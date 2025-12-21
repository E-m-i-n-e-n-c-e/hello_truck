import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:hello_truck_app/api/booking_api.dart' as booking_api;
import 'package:hello_truck_app/models/booking.dart';

import 'package:hello_truck_app/models/enums/booking_enums.dart';
import 'package:hello_truck_app/models/navigation_update.dart';
import 'package:hello_truck_app/providers/auth_providers.dart';
import 'package:hello_truck_app/providers/booking_providers.dart';
import 'package:hello_truck_app/utils/logger.dart';
import 'package:hello_truck_app/utils/nav_utils.dart';
import 'package:hello_truck_app/utils/currency_format.dart';
import 'package:hello_truck_app/widgets/snackbars.dart';
import 'package:url_launcher/url_launcher.dart';

double calculateBearing(LatLng from, LatLng to) {
  final lat1 = from.latitude * pi / 180.0;
  final lon1 = from.longitude * pi / 180.0;
  final lat2 = to.latitude * pi / 180.0;
  final lon2 = to.longitude * pi / 180.0;
  final dLon = lon2 - lon1;
  final y = sin(dLon) * cos(lat2);
  final x = cos(lat1) * sin(lat2) - sin(lat1) * cos(lat2) * cos(dLon);
  var brng = atan2(y, x);
  brng = brng * 180.0 / pi;
  return (brng + 360.0) % 360.0;
}

const double _initialSheetSize = 0.4;
const double _minSheetSize = 0.25;

class BookingDetailsScreen extends ConsumerStatefulWidget {
  final Booking initialBooking;

  const BookingDetailsScreen({super.key, required this.initialBooking});

  @override
  ConsumerState<BookingDetailsScreen> createState() => _BookingDetailsScreenState();
}

class _BookingDetailsScreenState extends ConsumerState<BookingDetailsScreen> {
  GoogleMapController? _mapController;
  final Set<Marker> _markers = {};
  final Set<Polyline> _polylines = {};
  BitmapDescriptor? _truckIcon;
  BitmapDescriptor? _truckIconFlipped;
  late Booking _booking;
  bool _handledFirstUpdate = false;
  double _sheetSize = _initialSheetSize;
  bool _helpExpanded = false;

  @override
  void initState() {
    super.initState();
    _booking = widget.initialBooking;
    _setupStaticMarkers(_booking);
    _loadTruckIcons();
  }

  @override
  void dispose() {
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitDown,
      DeviceOrientation.portraitUp,
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
    super.dispose();
  }

  Future<void> _setupStaticMarkers(Booking booking) async {
    _markers.clear();
    final shouldShowPickup = !isActive(booking.status) || isBeforePickupVerified(booking.status);

    if (shouldShowPickup) {
      _markers.add(
        Marker(
          markerId: const MarkerId('pickup'),
          position: LatLng(_booking.pickupAddress.latitude, _booking.pickupAddress.longitude),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
          infoWindow: const InfoWindow(title: 'Pickup Location'),
        ),
      );
    }

    _markers.add(
      Marker(
        markerId: const MarkerId('drop'),
        position: LatLng(_booking.dropAddress.latitude, _booking.dropAddress.longitude),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
        infoWindow: const InfoWindow(title: 'Drop Location'),
      ),
    );
  }

  Future<void> _loadTruckIcons() async {
    final baseIcon = await BitmapDescriptor.asset(
      const ImageConfiguration(size: Size(36, 36)),
      'assets/images/truck_marker.png',
    );
    final flippedIcon = await BitmapDescriptor.asset(
      const ImageConfiguration(size: Size(36, 36)),
      'assets/images/truck_marker_flipped.png',
    );
    if (mounted) {
      setState(() {
        _truckIcon = baseIcon;
        _truckIconFlipped = flippedIcon;
      });
    }
  }

  void _updateRouteAndDriver(DriverNavigationUpdate? update) async {
    if (update == null || update.isStale || !isActive(_booking.status)) return;
    final points = decodePolyline(update.routePolyline);

    if (update.location != null) {
      final latLng = LatLng(update.location!.latitude, update.location!.longitude);
      if (_truckIcon == null || _truckIconFlipped == null) {
        await _loadTruckIcons();
      }
      final nextPoint = points.length > 1 ? points[1] : null;
      final rotation = nextPoint != null ? ((calculateBearing(latLng, nextPoint) - 90) % 360) : 0.0;
      final shouldFlip = rotation > 90 && rotation < 270;
      final selectedIcon = shouldFlip ? _truckIconFlipped! : _truckIcon!;
      final adjustedRotation = shouldFlip ? (rotation + 180) % 360 : rotation;
      _markers.removeWhere((m) => m.markerId.value == 'driver');
      _markers.add(
        Marker(
          markerId: const MarkerId('driver'),
          position: latLng,
          icon: selectedIcon,
          rotation: adjustedRotation,
          anchor: const Offset(0.5, 0.5),
          flat: true,
        ),
      );
    }

    if (!mounted) return;
    if (points.isNotEmpty) {
      _polylines
        ..clear()
        ..add(
          Polyline(
            polylineId: const PolylineId('route'),
            points: points,
            color: Theme.of(context).colorScheme.secondary.withValues(alpha: 0.7),
            width: 5,
          ),
        );
    }
    if (mounted) setState(() {});
  }


  void _recenterMap(Booking booking, DriverNavigationUpdate? navUpdate, bool isPickupPhase) {
    if (_mapController == null) return;
    final pickupLatLng = LatLng(booking.pickupAddress.latitude, booking.pickupAddress.longitude);
    final dropLatLng = LatLng(booking.dropAddress.latitude, booking.dropAddress.longitude);
    LatLngBounds bounds;

    if (navUpdate == null || navUpdate.isStale || navUpdate.location == null || !isActive(booking.status)) {
      bounds = LatLngBounds(
        southwest: LatLng(
          min(booking.pickupAddress.latitude, booking.dropAddress.latitude),
          min(booking.pickupAddress.longitude, booking.dropAddress.longitude),
        ),
        northeast: LatLng(
          max(booking.pickupAddress.latitude, booking.dropAddress.latitude),
          max(booking.pickupAddress.longitude, booking.dropAddress.longitude),
        ),
      );
    } else {
      final targetLatLng = isPickupPhase ? pickupLatLng : dropLatLng;
      bounds = LatLngBounds(
        southwest: LatLng(
          min(navUpdate.location!.latitude, targetLatLng.latitude),
          min(navUpdate.location!.longitude, targetLatLng.longitude),
        ),
        northeast: LatLng(
          max(navUpdate.location!.latitude, targetLatLng.latitude),
          max(navUpdate.location!.longitude, targetLatLng.longitude),
        ),
      );
    }
    _mapController!.animateCamera(CameraUpdate.newLatLngBounds(bounds, 100));
  }

  void _handleBookingUpdate(Booking booking) {
    AppLogger.log('Booking updated: ${booking.id}');
    _setupStaticMarkers(booking);
    setState(() => _booking = booking);
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final bookingProvider = bookingDetailsProvider(widget.initialBooking.id);
    final bookingAsync = ref.watch(bookingProvider);
    final navStream = isActive(_booking.status)
        ? ref.watch(driverNavigationStreamProvider(_booking.id))
        : const AsyncValue.data(null);

    if (bookingAsync.value != null && !_handledFirstUpdate) {
      _handledFirstUpdate = true;
      _handleBookingUpdate(bookingAsync.value!);
    }

    ref.listen(bookingProvider, (previous, next) {
      if (next.value != null) _handleBookingUpdate(next.value!);
    });

    navStream.whenData((update) => _updateRouteAndDriver(update));

    final etaLabel = arrivalLabel(_booking.status, navStream.value);
    final isPickupPhase = isBeforePickupVerified(_booking.status);
    final title = getBookingTitle(_booking.status);
    final canCancel = canCancelBooking(_booking.status);

    return Scaffold(
      backgroundColor: cs.surface,
      body: Column(
        children: [
          // Header
          Container(
            decoration: BoxDecoration(
              color: cs.primary,
              boxShadow: [BoxShadow(color: cs.shadow.withValues(alpha: 0.15), blurRadius: 10, offset: const Offset(0, 3))],
            ),
            child: SafeArea(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: Icon(Icons.arrow_back_ios_new_rounded, color: cs.onPrimary),
                      ),
                      const SizedBox(width: 2),
                      Expanded(
                        child: Text(
                          title,
                          textAlign: TextAlign.center,
                          style: tt.titleLarge?.copyWith(color: cs.onPrimary, fontWeight: FontWeight.w800),
                        ),
                      ),
                      const SizedBox(width: 48),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                    decoration: BoxDecoration(
                      color: cs.surface.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(15),
                      border: Border.all(color: cs.surface.withValues(alpha: 0.3)),
                    ),
                    child: Text(
                      etaLabel.isEmpty ? 'On the way' : etaLabel,
                      style: tt.titleMedium?.copyWith(color: cs.onPrimary, fontWeight: FontWeight.w700),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
          Expanded(child: _buildMapAndSheet(context, navStream, isPickupPhase, canCancel)),
        ],
      ),
    );
  }


  Widget _buildMapAndSheet(BuildContext context, AsyncValue<DriverNavigationUpdate?> navStream, bool isPickupPhase, bool canCancel) {
    final cs = Theme.of(context).colorScheme;

    return LayoutBuilder(
      builder: (context, constraints) {
        return Stack(
          children: [
            GoogleMap(
              onMapCreated: (c) {
                _mapController = c;
                _recenterMap(_booking, navStream.value, isPickupPhase);
              },
              initialCameraPosition: CameraPosition(
                target: isPickupPhase
                    ? LatLng(_booking.pickupAddress.latitude, _booking.pickupAddress.longitude)
                    : LatLng(_booking.dropAddress.latitude, _booking.dropAddress.longitude),
                zoom: 13,
              ),
              markers: _markers,
              polylines: showPolyline(_booking.status) ? _polylines : {},
              myLocationEnabled: true,
              zoomControlsEnabled: false,
            ),

            // Recenter button
            Positioned(
              left: 16,
              bottom: constraints.maxHeight * min(_sheetSize, _initialSheetSize) + 16,
              child: Material(
                elevation: 4,
                borderRadius: BorderRadius.circular(12),
                color: cs.surfaceBright,
                child: InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: () => _recenterMap(_booking, navStream.value, isPickupPhase),
                  child: Container(
                    width: 40,
                    height: 36,
                    alignment: Alignment.center,
                    child: Icon(Icons.my_location_rounded, size: 20, color: cs.primary),
                  ),
                ),
              ),
            ),

            // Zoom controls
            Positioned(
              right: 16,
              bottom: constraints.maxHeight * min(_sheetSize, _initialSheetSize) + 16,
              child: Material(
                elevation: 4,
                borderRadius: BorderRadius.circular(12),
                color: cs.surfaceBright,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    InkWell(
                      onTap: () => _mapController?.moveCamera(CameraUpdate.zoomIn()),
                      borderRadius: const BorderRadius.only(topLeft: Radius.circular(12), topRight: Radius.circular(12)),
                      child: Container(
                        width: 40,
                        height: 36,
                        alignment: Alignment.center,
                        child: Icon(Icons.add, size: 20, color: cs.primary),
                      ),
                    ),
                    Divider(height: 1, thickness: 1, color: cs.outline.withValues(alpha: 0.15)),
                    InkWell(
                      onTap: () => _mapController?.moveCamera(CameraUpdate.zoomOut()),
                      borderRadius: const BorderRadius.only(bottomLeft: Radius.circular(12), bottomRight: Radius.circular(12)),
                      child: Container(
                        width: 40,
                        height: 36,
                        alignment: Alignment.center,
                        child: Icon(Icons.remove, size: 20, color: cs.primary),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Draggable sheet
            NotificationListener<DraggableScrollableNotification>(
              onNotification: (notification) {
                setState(() => _sheetSize = notification.extent);
                return true;
              },
              child: DraggableScrollableSheet(
                initialChildSize: _initialSheetSize,
                minChildSize: _minSheetSize,
                maxChildSize: 1,
                builder: (context, controller) {
                  return Container(
                    decoration: BoxDecoration(
                      color: cs.surface,
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                      boxShadow: [BoxShadow(color: cs.shadow.withValues(alpha: 0.15), blurRadius: 12, offset: const Offset(0, -2))],
                    ),
                    child: ListView(
                      controller: controller,
                      padding: const EdgeInsets.all(16),
                      children: [
                        // Handle
                        Center(
                          child: Container(
                            width: 40,
                            height: 4,
                            margin: const EdgeInsets.only(bottom: 16),
                            decoration: BoxDecoration(
                              color: cs.onSurface.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                        ),
                        // OTP Banner - prominent display at top
                        if (_shouldShowOtpBanner()) ...[
                          _buildOtpBanner(context),
                          const SizedBox(height: 12),
                        ],
                        // Payment banner - only show if final invoice exists with payment link and not paid
                        if (_shouldShowPaymentBanner()) ...[
                          _buildPaymentBanner(context),
                          const SizedBox(height: 12),
                        ],
                        if (_booking.assignedDriver != null) ...[
                          _buildDriverCard(context),
                          const SizedBox(height: 12),
                        ],
                        _buildAddressesCard(context),
                        const SizedBox(height: 12),
                        _buildPackageCard(context),
                        const SizedBox(height: 12),
                        _buildInvoiceCard(context),
                        const SizedBox(height: 12),
                        _buildHelpSection(context, canCancel),
                        const SizedBox(height: 24),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }


  Widget _buildPaymentBanner(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final invoice = _booking.finalInvoice!;
    final amount = invoice.finalAmount;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: cs.surfaceBright,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [BoxShadow(color: cs.shadow.withValues(alpha: 0.05), blurRadius: 8, offset: const Offset(0, 2))],
        border: Border.all(color: cs.primary.withValues(alpha: 0.15)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: cs.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(Icons.payment_rounded, color: cs.primary, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Payment of ${amount.toRupees()} pending',
                  style: tt.bodyMedium?.copyWith(fontWeight: FontWeight.w700, color: cs.onSurface),
                ),
                const SizedBox(height: 2),
                Text(
                  'Tap Pay now to complete payment',
                  style: tt.bodySmall?.copyWith(color: cs.onSurface.withValues(alpha: 0.6)),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          FilledButton(
            onPressed: () async {
              final url = Uri.parse(invoice.paymentLinkUrl!);
              if (!await launchUrl(url, mode: LaunchMode.inAppWebView)) {
                if (context.mounted) SnackBars.error(context, 'Could not open payment link');
              }
            },
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('Pay now'),
          ),
        ],
      ),
    );
  }

  bool _shouldShowPaymentBanner() {
    final invoice = _booking.finalInvoice;
    return invoice != null &&
           invoice.paymentLinkUrl != null &&
           invoice.paymentLinkUrl!.isNotEmpty &&
           !invoice.isPaid;
  }

  Widget _buildDriverCard(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final d = _booking.assignedDriver;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: cs.surfaceBright,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [BoxShadow(color: cs.shadow.withValues(alpha: 0.05), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 24,
            backgroundColor: cs.primary.withValues(alpha: 0.15),
            backgroundImage: (d?.photo != null && d!.photo!.isNotEmpty) ? NetworkImage(d.photo!) : null,
            child: (d?.photo == null || d!.photo!.isEmpty)
                ? Icon(Icons.person_rounded, color: cs.primary, size: 24)
                : null,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  d?.firstName != null ? '${d!.firstName} ${d.lastName ?? ''}'.trim() : 'Assigned driver',
                  style: tt.titleMedium?.copyWith(fontWeight: FontWeight.w700, color: cs.onSurface),
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Icon(Icons.star_rounded, size: 14, color: Colors.amber),
                    const SizedBox(width: 4),
                    Text(
                      'Score: ${d?.score ?? '-'}',
                      style: tt.bodySmall?.copyWith(color: cs.onSurface.withValues(alpha: 0.6)),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Material(
            color: Colors.green.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10),
            child: InkWell(
              onTap: () async {
                if (d?.phoneNumber != null) {
                  final url = Uri.parse('tel:${d!.phoneNumber}');
                  if (!await launchUrl(url)) {
                    if (context.mounted) SnackBars.error(context, 'Could not make call');
                  }
                }
              },
              borderRadius: BorderRadius.circular(10),
              child: Container(
                padding: const EdgeInsets.all(10),
                child: Icon(Icons.call_rounded, color: Colors.green.shade700, size: 20),
              ),
            ),
          ),
        ],
      ),
    );
  }


  bool _shouldShowOtpBanner() {
    final isPickupPhase = _booking.status == BookingStatus.confirmed ||
        _booking.status == BookingStatus.pickupArrived;
    final isDropPhase = _booking.status == BookingStatus.pickupVerified ||
        _booking.status == BookingStatus.inTransit ||
        _booking.status == BookingStatus.dropArrived;

    return (isPickupPhase && _booking.pickupOtp != null) ||
           (isDropPhase && _booking.dropOtp != null);
  }

  Widget _buildOtpBanner(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    final isPickupPhase = _booking.status == BookingStatus.confirmed ||
        _booking.status == BookingStatus.pickupArrived;

    final otp = isPickupPhase ? _booking.pickupOtp! : _booking.dropOtp!;
    final label = isPickupPhase ? 'Pickup OTP' : 'Drop OTP';

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: cs.surfaceBright,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [BoxShadow(color: cs.shadow.withValues(alpha: 0.05), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: cs.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(Icons.verified_user_rounded, color: cs.primary, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: tt.bodyMedium?.copyWith(
                    color: cs.onSurface,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Share with driver',
                  style: tt.bodySmall?.copyWith(
                    color: cs.onSurface.withValues(alpha: 0.6),
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: cs.primary,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              otp,
              style: tt.titleMedium?.copyWith(
                color: cs.onPrimary,
                fontWeight: FontWeight.w900,
                letterSpacing: 4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAddressesCard(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cs.surfaceBright,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [BoxShadow(color: cs.shadow.withValues(alpha: 0.05), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.route_rounded, size: 18, color: cs.primary),
              const SizedBox(width: 8),
              Text('Addresses', style: tt.titleSmall?.copyWith(fontWeight: FontWeight.w700, color: cs.onSurface)),
              const Spacer(),
              Text(
                '#${_booking.bookingNumber.toString().padLeft(6, '0')}',
                style: tt.bodySmall?.copyWith(color: cs.onSurface.withValues(alpha: 0.5), fontWeight: FontWeight.w600),
              ),
            ],
          ),
          const SizedBox(height: 14),
          _buildAddressRow(context, 'Pickup', _booking.pickupAddress.formattedAddress, isPickup: true),
          const SizedBox(height: 12),
          _buildAddressRow(context, 'Drop', _booking.dropAddress.formattedAddress, isPickup: false),
        ],
      ),
    );
  }


  Widget _buildPackageCard(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final pkg = _booking.package;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cs.surfaceBright,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [BoxShadow(color: cs.shadow.withValues(alpha: 0.05), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.inventory_2_outlined, size: 18, color: cs.primary),
              const SizedBox(width: 8),
              Text('Package', style: tt.titleSmall?.copyWith(fontWeight: FontWeight.w700, color: cs.onSurface)),
            ],
          ),
          const SizedBox(height: 14),
          _buildInfoRow(context, 'Type', pkg.productType.value.replaceAll('_', ' ')),
          if (pkg.productName != null && pkg.productName!.isNotEmpty)
            _buildInfoRow(context, 'Name', pkg.productName!),
          if (pkg.description != null && pkg.description!.isNotEmpty)
            _buildInfoRow(context, 'Description', pkg.description!),
          _buildInfoRow(context, 'Weight', '${pkg.approximateWeight.toStringAsFixed(pkg.approximateWeight.truncateToDouble() == pkg.approximateWeight ? 0 : 1)} ${pkg.weightUnit.value}'),
          if (pkg.numberOfProducts != null)
            _buildInfoRow(context, 'Quantity', '${pkg.numberOfProducts} items'),
          if (pkg.length != null && pkg.width != null && pkg.height != null)
            _buildInfoRow(context, 'Dimensions', '${pkg.length} x ${pkg.width} x ${pkg.height} ${pkg.dimensionUnit?.value ?? ''}'),
        ],
      ),
    );
  }

  Widget _buildInvoiceCard(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final invoice = _booking.finalInvoice ?? _booking.estimateInvoice;
    final isFinal = _booking.finalInvoice != null;

    if (invoice == null) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cs.surfaceBright,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [BoxShadow(color: cs.shadow.withValues(alpha: 0.05), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.receipt_long_rounded, size: 18, color: cs.primary),
              const SizedBox(width: 8),
              Text('Invoice', style: tt.titleSmall?.copyWith(fontWeight: FontWeight.w700, color: cs.onSurface)),
              if (!isFinal) ...[
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.orange.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text('Estimated', style: tt.labelSmall?.copyWith(color: Colors.orange.shade700, fontWeight: FontWeight.w600)),
                ),
              ],
            ],
          ),
          const SizedBox(height: 14),
          _buildInfoRow(context, 'Vehicle', invoice.vehicleModelName),
          _buildInfoRow(context, 'Distance', '${invoice.distanceKm.toStringAsFixed(1)} km'),
          _buildInfoRow(context, 'Base Price', invoice.effectiveBasePrice.toRupees()),
          _buildInfoRow(context, 'Per Km Rate', '${invoice.perKmPrice.toRupees()}/km'),
          Divider(height: 16, color: cs.outline.withValues(alpha: 0.1)),
          _buildInfoRow(context, 'Total', invoice.totalPrice.toRupees()),
          if (invoice.walletApplied != 0) ...[
            if (invoice.walletApplied > 0)
              _buildInfoRow(context, 'Wallet Applied', '-${invoice.walletApplied.toRupees()}', valueColor: Colors.green)
            else
              _buildInfoRow(context, 'Debt Cleared', '+${invoice.walletApplied.abs().toRupees()}', valueColor: Colors.orange),
          ],
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Amount Payable', style: tt.bodyMedium?.copyWith(fontWeight: FontWeight.w700, color: cs.onSurface)),
              Text(invoice.finalAmount.toRupees(), style: tt.titleMedium?.copyWith(fontWeight: FontWeight.w800, color: cs.primary)),
            ],
          ),
          if (isFinal && invoice.isPaid) ...[
            const SizedBox(height: 10),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 8),
              decoration: BoxDecoration(
                color: Colors.green.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.check_circle_rounded, size: 16, color: Colors.green),
                  const SizedBox(width: 6),
                  Text('Paid', style: tt.bodySmall?.copyWith(color: Colors.green, fontWeight: FontWeight.w700)),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildInfoRow(BuildContext context, String label, String value, {Color? valueColor}) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: tt.bodySmall?.copyWith(color: cs.onSurface.withValues(alpha: 0.6))),
          Text(value, style: tt.bodyMedium?.copyWith(color: valueColor ?? cs.onSurface, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  Widget _buildAddressRow(BuildContext context, String label, String value, {required bool isPickup}) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: (isPickup ? cs.primary : Colors.red).withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            isPickup ? Icons.my_location_rounded : Icons.location_on_rounded,
            size: 16,
            color: isPickup ? cs.primary : Colors.red,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: tt.labelSmall?.copyWith(
                  color: cs.onSurface.withValues(alpha: 0.5),
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 2),
              Text(value, style: tt.bodyMedium?.copyWith(color: cs.onSurface)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildHelpSection(BuildContext context, bool canCancel) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Container(
      decoration: BoxDecoration(
        color: cs.surfaceBright,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [BoxShadow(color: cs.shadow.withValues(alpha: 0.05), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Column(
        children: [
          // Header - tappable to expand
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () => setState(() => _helpExpanded = !_helpExpanded),
              borderRadius: BorderRadius.circular(14),
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: cs.secondary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(Icons.help_outline_rounded, color: cs.secondary, size: 22),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Need Help?', style: tt.titleSmall?.copyWith(fontWeight: FontWeight.w700, color: cs.onSurface)),
                          const SizedBox(height: 2),
                          Text('Support & options', style: tt.bodySmall?.copyWith(color: cs.onSurface.withValues(alpha: 0.6))),
                        ],
                      ),
                    ),
                    AnimatedRotation(
                      turns: _helpExpanded ? 0.5 : 0,
                      duration: const Duration(milliseconds: 200),
                      child: Icon(Icons.keyboard_arrow_down_rounded, color: cs.onSurface.withValues(alpha: 0.5), size: 24),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Expandable content
          AnimatedCrossFade(
            firstChild: const SizedBox.shrink(),
            secondChild: Column(
              children: [
                Divider(height: 1, color: cs.outline.withValues(alpha: 0.1)),
                // Contact Support
                Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () => SnackBars.info(context, 'Support coming soon'),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      child: Row(
                        children: [
                          Icon(Icons.support_agent_rounded, color: cs.primary, size: 20),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text('Contact Support', style: tt.bodyMedium?.copyWith(color: cs.onSurface, fontWeight: FontWeight.w500)),
                          ),
                          Icon(Icons.chevron_right_rounded, color: cs.onSurface.withValues(alpha: 0.4), size: 20),
                        ],
                      ),
                    ),
                  ),
                ),
                // Cancel Booking - only if allowed
                if (canCancel) ...[
                  Divider(height: 1, indent: 46, color: cs.outline.withValues(alpha: 0.1)),
                  Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () => _showCancelDialog(context),
                      borderRadius: const BorderRadius.only(
                        bottomLeft: Radius.circular(14),
                        bottomRight: Radius.circular(14),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        child: Row(
                          children: [
                            Icon(Icons.cancel_outlined, color: cs.error, size: 20),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text('Cancel Booking', style: tt.bodyMedium?.copyWith(color: cs.error, fontWeight: FontWeight.w500)),
                            ),
                            Icon(Icons.chevron_right_rounded, color: cs.error.withValues(alpha: 0.5), size: 20),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
            crossFadeState: _helpExpanded ? CrossFadeState.showSecond : CrossFadeState.showFirst,
            duration: const Duration(milliseconds: 200),
          ),
        ],
      ),
    );
  }


  Future<void> _showCancelDialog(BuildContext context) async {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final config = await ref.read(cancellationConfigProvider.future);

    // Use totalPrice (full service value before wallet deduction) for cancellation charge
    // This matches backend logic
    final totalPrice = _booking.finalInvoice?.totalPrice ?? _booking.estimateInvoice?.totalPrice ?? _booking.estimatedCost;
    final isConfirmed = _booking.status != BookingStatus.pending && _booking.status != BookingStatus.driverAssigned;

    double refundAmount;
    double cancellationCharge;

    if (isConfirmed) {
      final chargePercent = config.calculateChargePercent(_booking.acceptedAt);
      cancellationCharge = totalPrice * chargePercent;
      refundAmount = totalPrice - cancellationCharge;
    } else {
      refundAmount = totalPrice;
      cancellationCharge = 0;
    }

    final shouldCancel = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: cs.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: cs.onSurface.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text('Cancel Booking?', style: tt.titleLarge?.copyWith(fontWeight: FontWeight.w700, color: cs.onSurface)),
            const SizedBox(height: 8),
            Text(
              'Booking #${_booking.bookingNumber.toString().padLeft(6, '0')}',
              style: tt.bodyMedium?.copyWith(color: cs.onSurface.withValues(alpha: 0.6)),
            ),
            const SizedBox(height: 20),

            // Refund details
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: cs.surfaceBright,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: cs.outline.withValues(alpha: 0.1)),
              ),
              child: Column(
                children: [
                  _buildDetailRow(context, 'Booking Amount', totalPrice.toRupees()),
                  if (cancellationCharge > 0) ...[
                    const SizedBox(height: 10),
                    _buildDetailRow(context, 'Cancellation Fee', '-${cancellationCharge.toRupees()}', valueColor: cs.error),
                  ],
                  const SizedBox(height: 10),
                  Divider(color: cs.outline.withValues(alpha: 0.1)),
                  const SizedBox(height: 10),
                  _buildDetailRow(context, 'Refund Amount', refundAmount.toRupees(), valueColor: Colors.green, isBold: true),
                ],
              ),
            ),

            if (isConfirmed) ...[
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.orange.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline_rounded, size: 18, color: Colors.orange),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Cancellation charges increase over time after driver accepts',
                        style: tt.bodySmall?.copyWith(color: Colors.orange.shade800),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context, false),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text('Keep Booking'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton(
                    onPressed: () => Navigator.pop(context, true),
                    style: FilledButton.styleFrom(
                      backgroundColor: cs.error,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text('Cancel Booking'),
                  ),
                ),
              ],
            ),
            SizedBox(height: MediaQuery.of(context).padding.bottom + 8),
          ],
        ),
      ),
    );

    if (shouldCancel == true && context.mounted) {
      await _cancelBooking(context);
    }
  }

  Widget _buildDetailRow(BuildContext context, String label, String value, {Color? valueColor, bool isBold = false}) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: tt.bodyMedium?.copyWith(color: cs.onSurface.withValues(alpha: 0.7), fontWeight: isBold ? FontWeight.w600 : null)),
        Text(value, style: tt.bodyMedium?.copyWith(color: valueColor ?? cs.onSurface, fontWeight: isBold ? FontWeight.w700 : FontWeight.w600)),
      ],
    );
  }

  Future<void> _cancelBooking(BuildContext context) async {
    try {
      final api = ref.read(apiProvider).value!;
      await booking_api.cancelBooking(api, _booking.id, 'Cancelled by customer');
      ref.invalidate(activeBookingsProvider);
      ref.invalidate(bookingDetailsProvider(_booking.id));
      if (context.mounted) {
        SnackBars.success(context, 'Booking cancelled successfully');
        Navigator.pop(context);
      }
    } catch (e) {
      if (context.mounted) {
        SnackBars.error(context, 'Failed to cancel booking: $e');
      }
    }
  }
}
