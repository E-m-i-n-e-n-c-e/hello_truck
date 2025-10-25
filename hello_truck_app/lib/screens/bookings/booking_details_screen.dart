import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:hello_truck_app/models/navigation_update.dart';
import 'package:hello_truck_app/models/saved_address.dart';
import 'package:hello_truck_app/utils/logger.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:hello_truck_app/models/booking.dart';
import 'package:hello_truck_app/models/package.dart';
import 'package:hello_truck_app/models/enums/package_enums.dart';
import 'package:hello_truck_app/providers/booking_providers.dart';
import 'package:hello_truck_app/utils/nav_utils.dart';
import 'package:hello_truck_app/screens/home/booking/widgets/map_selection_page.dart';
import 'package:hello_truck_app/api/booking_api.dart';
import 'package:hello_truck_app/providers/auth_providers.dart';
import 'package:hello_truck_app/widgets/snackbars.dart';

const double _initialSheetSize = 0.4;
const double _minSheetSize = 0.25;

class BookingDetailsScreen extends ConsumerStatefulWidget {
  final Booking initialBooking;

  const BookingDetailsScreen({super.key, required this.initialBooking});

  @override
  ConsumerState<BookingDetailsScreen> createState() => _BookingDetailsScreenState();
}

class _BookingDetailsScreenState extends ConsumerState<BookingDetailsScreen> with TickerProviderStateMixin {
  GoogleMapController? _mapController;
  final Set<Marker> _markers = {};
  final Set<Polyline> _polylines = {};
  BitmapDescriptor? _driverIcon;
  late Booking _booking;
  bool _handledFirstUpdate = false;
  double _sheetSize = _initialSheetSize; // Track current sheet size

  @override
  void initState() {
    super.initState();
    _booking = widget.initialBooking;
    _setupStaticMarkers(_booking);
    _loadDriverIcon();
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
    // show pickup marker if pickup is not yet verified or booking is inactive/completed
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

    // Always show drop marker
    _markers.add(
      Marker(
        markerId: const MarkerId('drop'),
        position: LatLng(_booking.dropAddress.latitude, _booking.dropAddress.longitude),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
        infoWindow: const InfoWindow(title: 'Drop Location'),
      ),
    );
  }

  Future<void> _loadDriverIcon() async {
    final icon = await BitmapDescriptor.asset(
      const ImageConfiguration(size: Size(48, 48)),
      'assets/images/truck_marker.png',
    );
    if (mounted) {
      setState(() {
        _driverIcon = icon;
      });
    }
  }

  void _updateRouteAndDriver(DriverNavigationUpdate? update) async {
    if(update == null || update.isStale || !isActive(_booking.status) ) return;
    // driver marker
    if (update.location != null) {
      final latLng = LatLng(update.location!.latitude, update.location!.longitude);
      if(_driverIcon == null) {
        await _loadDriverIcon();
      }
      _markers.removeWhere((m) => m.markerId.value == 'driver');
      _markers.add(Marker(markerId: const MarkerId('driver'), position: latLng, icon: _driverIcon!));
    }
    if(!mounted) return;
    // polyline
    final points = decodePolyline(update.routePolyline);
    // Only update polyline if the points are not empty and the update is not stale
    if(points.isNotEmpty) {
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
    if (_mapController != null) {
      final pickupLatLng = LatLng(booking.pickupAddress.latitude, booking.pickupAddress.longitude);
      final dropLatLng = LatLng(booking.dropAddress.latitude, booking.dropAddress.longitude);
      LatLngBounds bounds;
      if (navUpdate == null || navUpdate.isStale || navUpdate.location == null || !isActive(booking.status)) {
        bounds = LatLngBounds(
          southwest: LatLng(
            booking.pickupAddress.latitude < booking.dropAddress.latitude
                ? booking.pickupAddress.latitude
                : booking.dropAddress.latitude,
            booking.pickupAddress.longitude < booking.dropAddress.longitude
                ? booking.pickupAddress.longitude
                : booking.dropAddress.longitude,
          ),
          northeast: LatLng(
            booking.pickupAddress.latitude > booking.dropAddress.latitude
                ? booking.pickupAddress.latitude
                : booking.dropAddress.latitude,
            booking.pickupAddress.longitude > booking.dropAddress.longitude
                ? booking.pickupAddress.longitude
                : booking.dropAddress.longitude,
          ),
        );
      } else {
        final targetLatLng = isPickupPhase ? pickupLatLng : dropLatLng;
        bounds = LatLngBounds(
          southwest: LatLng(
            navUpdate.location!.latitude < targetLatLng.latitude
                ? navUpdate.location!.latitude
                : targetLatLng.latitude,
            navUpdate.location!.longitude < targetLatLng.longitude
                ? navUpdate.location!.longitude
                : targetLatLng.longitude,
          ),
          northeast: LatLng(
            navUpdate.location!.latitude > targetLatLng.latitude
                ? navUpdate.location!.latitude
                : targetLatLng.latitude,
            navUpdate.location!.longitude > targetLatLng.longitude
                ? navUpdate.location!.longitude
                : targetLatLng.longitude,
          ),
        );
      }
      _mapController!.animateCamera(CameraUpdate.newLatLngBounds(bounds, 100));
    }
  }

  void _handleBookingUpdate(Booking booking) {
    AppLogger.log('Booking updated: ${booking.id}');

     _setupStaticMarkers(booking);

    setState(() {
      _booking = booking;
    });
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final bookingProvider = bookingDetailsProvider(widget.initialBooking.id);
    final bookingAsync = ref.watch(bookingProvider);
    final navStream = isActive(_booking.status)
        ? ref.watch(driverNavigationStreamProvider(_booking.id))
        : const AsyncValue.data(null);

    // Handle first update
    if(bookingAsync.value != null && !_handledFirstUpdate) {
      _handledFirstUpdate = true;
      _handleBookingUpdate(bookingAsync.value!);
    }

    // Handle subsequent updates
    ref.listen(bookingProvider, (previous, next) {
      _handleBookingUpdate(next.value!);
    });

    // Handle navigation updates
    navStream.whenData((update) {
      _updateRouteAndDriver(update);
    });

    final etaLabel = arrivalLabel(_booking.status, navStream.value);
    final isPickupPhase = isBeforePickupVerified(_booking.status);
    final title = getBookingTitle(_booking.status);
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          // Top overlay banner acting as app bar + status
          Container(
            decoration: BoxDecoration(
              color: colorScheme.primary,
              boxShadow: [
                BoxShadow(color: Colors.black.withValues(alpha: 0.15), blurRadius: 10, offset: const Offset(0, 3)),
              ],
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
                        icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
                      ),
                      const SizedBox(width: 2),
                      Expanded(
                        child: Text(
                          title,
                          textAlign: TextAlign.center,
                          style: textTheme.titleLarge?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                      const SizedBox(width: 48), // balance back button space
                    ],
                  ),
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(15),
                      border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
                    ),
                    child: Text(
                      etaLabel.isEmpty ? 'On the way' : etaLabel,
                      style: textTheme.titleMedium?.copyWith(color: Colors.white, fontWeight: FontWeight.w700),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                return Stack(
                  children: [
                    // Map
                GoogleMap(
                  onMapCreated: (c) {
                    _mapController = c;
                    _recenterMap(_booking, navStream.value, isPickupPhase);
                  },
                  initialCameraPosition: CameraPosition(
                        target: isPickupPhase
                            ? LatLng(_booking.pickupAddress.latitude,_booking.pickupAddress.longitude)
                            : LatLng(_booking.dropAddress.latitude,_booking.dropAddress.longitude),
                    zoom: 13,
                  ),
                  markers: _markers,
                  polylines: showPolyline(_booking.status) ? _polylines : {},
                  myLocationEnabled: true,
                  zoomControlsEnabled: false,
                ),

                 // Recenter button (bottom left) - positioned relative to draggable sheet
                 Positioned(
                   left: 16,
                   bottom: constraints.maxHeight * min(_sheetSize, _initialSheetSize) + 16, // 16px above the current sheet size
                   child: Material(
                     elevation: 4,
                     borderRadius: BorderRadius.circular(12),
                     color: Colors.white,
                     child: InkWell(
                       borderRadius: BorderRadius.circular(12),
                       onTap: () => _recenterMap(_booking, navStream.value, isPickupPhase),
                       child: Container(
                         width: 40,
                         height: 36,
                         alignment: Alignment.center,
                         child: Icon(Icons.my_location_rounded, size: 20, color: colorScheme.primary),
                       ),
                     ),
                   ),
                 ),

                 // Zoom controls (bottom right) - positioned relative to draggable sheet
                 Positioned(
                   right: 16,
                   bottom: constraints.maxHeight * min(_sheetSize, _initialSheetSize) + 16, // 16px above the current sheet size
                   child: Material(
                     elevation: 4,
                     borderRadius: BorderRadius.circular(12),
                     color: Colors.white,
                     child: Column(
                       mainAxisSize: MainAxisSize.min,
                       children: [
                         InkWell(
                           onTap: () {
                             _mapController?.moveCamera(CameraUpdate.zoomIn());
                           },
                           borderRadius: const BorderRadius.only(
                             topLeft: Radius.circular(12),
                             topRight: Radius.circular(12),
                           ),
                           child: Container(
                             width: 40,
                             height: 36,
                             alignment: Alignment.center,
                             child: Icon(Icons.add, size: 20, color: colorScheme.primary),
                           ),
                         ),
                         const Divider(height: 1, thickness: 1, color: Color(0xFFDDDDDD)),
                         InkWell(
                           onTap: () {
                             _mapController?.moveCamera(CameraUpdate.zoomOut());
                           },
                           borderRadius: const BorderRadius.only(
                             bottomLeft: Radius.circular(12),
                             bottomRight: Radius.circular(12),
                           ),
                           child: Container(
                             width: 40,
                             height: 36,
                             alignment: Alignment.center,
                             child: Icon(Icons.remove, size: 20, color: colorScheme.primary),
                           ),
                         ),
                       ],
                     ),
                   ),
                 ),

                 // Draggable sheet
                 NotificationListener<DraggableScrollableNotification>(
                   onNotification: (notification) {
                     setState(() {
                       _sheetSize = notification.extent;
                     });
                     return true;
                   },
                   child: DraggableScrollableSheet(
                     initialChildSize: _initialSheetSize,
                     minChildSize: _minSheetSize,
                     maxChildSize: 1,
                     builder: (context, controller) {
                       return Container(
                         decoration: const BoxDecoration(
                           color: Colors.white,
                           borderRadius: BorderRadius.only(topLeft: Radius.circular(20), topRight: Radius.circular(20)),
                           boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 12, offset: Offset(0, -2))],
                         ),
                         child: ListView(
                           controller: controller,
                           padding: const EdgeInsets.all(16),
                           children: [
                             // Payment banner (placeholder link)
                             _paymentBanner(context),
                             const SizedBox(height: 12),
                             if(_booking.assignedDriver != null) ...[
                              _driverCard(context),
                              const SizedBox(height: 12),
                             ],
                             _orderDetailsCard(context),
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
            ),
          ),
        ],
      ),
    );
  }

  Widget _paymentBanner(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colorScheme.primary.withValues(alpha: 0.06), borderRadius: BorderRadius.circular(16), border: Border.all(color: colorScheme.primary.withValues(alpha: 0.15))),
      child: Row(
        children: [
          const SizedBox(width: 8),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Payment of ₹${_booking.finalCost?.toStringAsFixed(2) ?? _booking.estimatedCost.toStringAsFixed(2)} pending', style: textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w700)),
              const SizedBox(height: 2),
              Text('Tap Pay now to complete payment', style: textTheme.bodySmall?.copyWith(color: Colors.black.withValues(alpha: 0.6))),
            ]),
          ),
          const SizedBox(width: 8),
          ElevatedButton(
            onPressed: () async {
              final url = Uri.parse('https://rzp.io/rzp/3E0KVp8');
              if (!await launchUrl(url, mode: LaunchMode.inAppWebView)) {
                if (context.mounted) SnackBars.error(context, 'Could not open payment link');
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: colorScheme.primary, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
            child: const Text('Pay now'),
          ),
        ],
      ),
    );
  }

  Widget _driverCard(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final d = _booking.assignedDriver;
    return Container(
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.08), blurRadius: 10, offset: const Offset(0, 2))]),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            CircleAvatar(radius: 22, backgroundImage: (d?.photo != null && d!.photo!.isNotEmpty) ? NetworkImage(d.photo!) : null, child: (d?.photo == null || d!.photo!.isEmpty) ? const Icon(Icons.person) : null),
            const SizedBox(width: 12),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(d?.firstName != null ? '${d!.firstName} ${d.lastName ?? ''}'.trim() : 'Assigned driver', style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
                const SizedBox(height: 2),
                Text('Score: ${d?.score ?? '-'}', style: textTheme.bodySmall?.copyWith(color: Colors.grey.shade700)),
              ]),
            ),
            IconButton(onPressed: () async {
              // Optional: tel: link if phone available
            }, icon: const Icon(Icons.call, color: Colors.green)),
          ],
        ),
      ),
    );
  }

  Widget _orderDetailsCard(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    return Container(
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.08), blurRadius: 10, offset: const Offset(0, 2))]),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Text('Order details', style: textTheme.titleLarge?.copyWith(color: Colors.black, fontWeight: FontWeight.w500)),
          ]),
          const SizedBox(height: 16),

          // Addresses
          _addressRow(context, 'Pickup', _booking.pickupAddress.formattedAddress, isPickup: true),
          const SizedBox(height: 10),
          _addressRow(context, 'Drop', _booking.dropAddress.formattedAddress, isPickup: false),
          const SizedBox(height: 16),

          // Package summary
          Row(children: [
            const Icon(Icons.inventory_2_outlined, size: 18, color: Colors.grey),
            const SizedBox(width: 8),
            Expanded(child: Text('Package: ${_booking.package.productType.value.replaceAll('_', ' ')}', style: textTheme.bodyMedium)),
            if(showEditButton(_booking.status, EditButtonType.package))
            TextButton(onPressed: () => _editPackage(context), child: Text('Edit', style: TextStyle(color: colorScheme.primary, fontWeight: FontWeight.w600))),
          ]),
          const SizedBox(height: 8),

          Row(children: [
            const Icon(Icons.local_shipping_outlined, size: 18, color: Colors.grey),
            const SizedBox(width: 8),
            Expanded(child: Text('Vehicle: ${_booking.suggestedVehicleType.value.replaceAll('_', ' ')}', style: textTheme.bodyMedium)),
            Text('₹${(_booking.finalCost ?? _booking.estimatedCost).toStringAsFixed(2)}', style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
          ]),
        ]),
      ),
    );
  }

  Widget _addressRow(BuildContext context, String label, String value, {required bool isPickup}) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(isPickup ? Icons.my_location : Icons.location_on, size: 18, color: isPickup ? colorScheme.primary : Colors.red),
        const SizedBox(width: 8),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(label.toUpperCase(), style: textTheme.bodySmall?.copyWith(color: Colors.grey.shade600, fontWeight: FontWeight.w600, letterSpacing: 0.5)),
            const SizedBox(height: 4),
            Text(value, style: textTheme.bodyMedium),
          ]),
        ),
        if(showEditButton(_booking.status, isPickup ? EditButtonType.pickup : EditButtonType.drop))
        TextButton(onPressed: () => _editAddress(context, isPickup), child: Text('Edit', style: TextStyle(color: colorScheme.primary, fontWeight: FontWeight.w600))),
      ],
    );
  }

  Future<void> _editAddress(BuildContext context, bool isPickup) async {
    final current = isPickup ? _booking.pickupAddress : _booking.dropAddress;

    final saved = SavedAddress(
      id: '',
      name: isPickup ? 'Pickup' : 'Drop',
      address: Address(
        formattedAddress: current.formattedAddress,
        latitude: current.latitude,
        longitude: current.longitude,
        addressDetails: current.addressDetails,
      ),
      contactName: isPickup ? _booking.pickupAddress.contactName : _booking.dropAddress.contactName,
      contactPhone: isPickup ? _booking.pickupAddress.contactPhone : _booking.dropAddress.contactPhone,
      noteToDriver: isPickup ? _booking.pickupAddress.noteToDriver : _booking.dropAddress.noteToDriver,
      isDefault: false,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    final selected = await Navigator.push<SavedAddress>(
      context,
      MaterialPageRoute(
        builder: (context) => MapSelectionPage.booking(
          isPickup: isPickup,
          initialSavedAddress: saved,
        ),
      ),
    );

    if (!context.mounted || selected == null) return;

    try {
      final api = await ref.read(apiProvider.future);
      await updateBookingAddress(
        api,
        _booking.id,
        addressType: isPickup ? AddressType.pickup : AddressType.drop,
        addressName: selected.name,
        contactName: selected.contactName,
        contactPhone: selected.contactPhone,
        noteToDriver: selected.noteToDriver,
        formattedAddress: selected.address.formattedAddress,
        addressDetails: selected.address.addressDetails,
        latitude: selected.address.latitude,
        longitude: selected.address.longitude,
      );
      if (!context.mounted) return;
      ref.invalidate(bookingDetailsProvider(_booking.id));
    } catch (e) {
      if (context.mounted) SnackBars.error(context, 'Failed to update address: $e');
    }
  }

  Future<void> _editPackage(BuildContext context) async {
    // Lightweight prompt to edit weight; validate with estimate and updateBooking
    final isAgri = _booking.package.productType == ProductType.agricultural;
    final controller = TextEditingController(text: isAgri ? (_booking.package.approximateWeight?.toString() ?? '') : (_booking.package.averageWeight?.toString() ?? ''));

    final value = await showDialog<double?>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Update weight'),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(labelText: 'Weight (KG)'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(context, double.tryParse(controller.text.trim())), child: const Text('Save')),
        ],
      ),
    );

    if (value == null) return;

    try {
      final api = await ref.read(apiProvider.future);
      final isAgri = _booking.package.productType == ProductType.agricultural;
      final pkg = isAgri ? Package.agricultural(
        packageType: _booking.package.packageType,
        productName: _booking.package.productName ?? '',
        approximateWeight: value,
        weightUnit: _booking.package.weightUnit ?? WeightUnit.kg,
      ) : Package.nonAgricultural(
        packageType: _booking.package.packageType,
        averageWeight: value,
        bundleWeight: _booking.package.bundleWeight,
        length: _booking.package.length,
        width: _booking.package.width,
        height: _booking.package.height,
        dimensionUnit: _booking.package.dimensionUnit ?? DimensionUnit.cm,
        description: _booking.package.description,
        packageImageUrl: _booking.package.packageImageUrl,
        gstBillUrl: _booking.package.gstBillUrl,
      );

      // Validate against vehicle weight limit using estimate
      final estimate = await getBookingEstimate(
        api,
        pickupAddress: _booking.pickupAddress,
        dropAddress: _booking.dropAddress,
        package: _booking.package,
      );
      final matched = estimate.vehicleOptions.firstWhere((o) => o.vehicleType == _booking.suggestedVehicleType, orElse: () => estimate.vehicleOptions.first);
      if ((isAgri ? (pkg.approximateWeight ?? 0) : (pkg.averageWeight ?? 0)) > matched.weightLimit) {
        if (context.mounted) SnackBars.error(context, 'Weight exceeds ${matched.weightLimit.toStringAsFixed(0)} kg limit for ${_booking.suggestedVehicleType.value.replaceAll('_', ' ')}');
        return;
      }

      await updateBookingPackage(api, _booking.id, pkg);
      if (!context.mounted) return;
      ref.invalidate(bookingDetailsProvider(_booking.id));
    } catch (e) {
      if (context.mounted) SnackBars.error(context, 'Failed to update package: $e');
    }
  }
}


