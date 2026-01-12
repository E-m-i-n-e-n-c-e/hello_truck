import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hello_truck_app/models/booking.dart';
import 'package:hello_truck_app/models/booking_estimate.dart';
import 'package:hello_truck_app/models/enums/package_enums.dart';
import 'package:hello_truck_app/models/package.dart';
import 'package:hello_truck_app/api/booking_api.dart';
import 'package:hello_truck_app/providers/auth_providers.dart';
import 'package:hello_truck_app/providers/booking_providers.dart';
import 'package:hello_truck_app/providers/provider_registry.dart';
import 'package:hello_truck_app/screens/home/booking/widgets/address_search_page.dart';
import 'package:hello_truck_app/widgets/snackbars.dart';
import 'package:hello_truck_app/utils/format_utils.dart';

class ReviewScreen extends ConsumerStatefulWidget {
  final BookingAddress pickupAddress;
  final BookingAddress dropAddress;
  final Package package;
  final BookingEstimate estimate;

  const ReviewScreen({
    super.key,
    required this.pickupAddress,
    required this.dropAddress,
    required this.package,
    required this.estimate,
  });

  @override
  ConsumerState<ReviewScreen> createState() => _ReviewScreenState();
}

class _ReviewScreenState extends ConsumerState<ReviewScreen> {
  bool _isBooking = false;
  late BookingAddress _pickupAddress;
  late BookingAddress _dropAddress;

  VehicleOption get _idealVehicle {
    return widget.estimate.topVehicles.firstWhere(
      (o) => o.vehicleModelName == widget.estimate.idealVehicleModel,
    );
  }

  @override
  void initState() {
    super.initState();
    _pickupAddress = widget.pickupAddress;
    _dropAddress = widget.dropAddress;
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        backgroundColor: colorScheme.surface,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: colorScheme.onSurface),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Review Order',
          style: textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w700,
            color: colorScheme.onSurface,
          ),
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildOrderSummaryCard(colorScheme, textTheme),
                  const SizedBox(height: 20),
                  _buildPackageDetailsCard(colorScheme, textTheme),
                  const SizedBox(height: 20),
                  _buildVehicleCard(colorScheme, textTheme),
                  const SizedBox(height: 20),
                  _buildPriceBreakdownCard(colorScheme, textTheme),
                  const SizedBox(height: 20),
                  _buildImportantNotesCard(colorScheme, textTheme),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
          _buildBottomSection(colorScheme, textTheme),
        ],
      ),
    );
  }

  Widget _buildOrderSummaryCard(ColorScheme colorScheme, TextTheme textTheme) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: colorScheme.surfaceBright,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.08), blurRadius: 10, offset: const Offset(0, 2)),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Order Summary', style: textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600, color: colorScheme.onSurface)),
            const SizedBox(height: 20),
            _buildLocationRow(Icons.circle, colorScheme.primary, 'Pickup', _pickupAddress, () => _editLocation(true), colorScheme, textTheme),
            Container(
              margin: const EdgeInsets.symmetric(vertical: 12),
              child: Row(
                children: [
                  const SizedBox(width: 6),
                  SizedBox(width: 2, height: 30, child: CustomPaint(painter: DottedLinePainter(color: colorScheme.onSurface.withValues(alpha: 0.3)))),
                  const SizedBox(width: 14),
                ],
              ),
            ),
            _buildLocationRow(Icons.circle, Colors.red, 'Drop', _dropAddress, () => _editLocation(false), colorScheme, textTheme),
          ],
        ),
      ),
    );
  }

  Widget _buildLocationRow(IconData icon, Color iconColor, String title, BookingAddress address, VoidCallback onEdit, ColorScheme colorScheme, TextTheme textTheme) {
    return Row(
      children: [
        Icon(icon, color: iconColor, size: 12),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title.toUpperCase(), style: textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w600, letterSpacing: 0.5, color: colorScheme.onSurface.withValues(alpha: 0.6))),
              const SizedBox(height: 4),
              Text(address.addressName ?? '', style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold, color: colorScheme.onSurface)),
              if (address.contactPhone.isNotEmpty) ...[
                const SizedBox(height: 2),
                Text('${address.contactName} • ${address.contactPhone}', style: textTheme.bodySmall?.copyWith(color: colorScheme.onSurface.withValues(alpha: 0.6))),
              ],
            ],
          ),
        ),
        TextButton(onPressed: onEdit, child: Text('Edit', style: TextStyle(fontSize: 15, color: colorScheme.primary, fontWeight: FontWeight.w600))),
      ],
    );
  }

  Widget _buildPackageDetailsCard(ColorScheme colorScheme, TextTheme textTheme) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: colorScheme.surfaceBright,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.08), blurRadius: 10, offset: const Offset(0, 2))],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Package Details', style: textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600, color: colorScheme.onSurface)),
                TextButton(onPressed: _editPackageDetails, child: Text('Edit', style: TextStyle(fontSize: 15, color: colorScheme.primary, fontWeight: FontWeight.w600))),
              ],
            ),
            const SizedBox(height: 16),
            _buildPackageDetailsSummary(colorScheme, textTheme),
          ],
        ),
      ),
    );
  }

  Widget _buildPackageDetailsSummary(ColorScheme colorScheme, TextTheme textTheme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Type: ${widget.package.isCommercial ? 'Commercial' : 'Personal'}', style: textTheme.bodyMedium?.copyWith(color: colorScheme.onSurface)),
        const SizedBox(height: 4),
        if (widget.package.productType == ProductType.personal || widget.package.productType == ProductType.agricultural) ...[
          if (widget.package.productName != null) Text('Product: ${widget.package.productName}', style: textTheme.bodyMedium?.copyWith(color: colorScheme.onSurface)),
          const SizedBox(height: 4),
          Text('Weight: ${widget.package.approximateWeight} ${widget.package.weightUnit.value}', style: textTheme.bodyMedium?.copyWith(color: colorScheme.onSurface)),
        ],
        if (widget.package.productType == ProductType.nonAgricultural) ...[
          Text('Category: Non-Agricultural Product', style: textTheme.bodyMedium?.copyWith(color: colorScheme.onSurface)),
          const SizedBox(height: 4),
          Text('Weight: ${widget.package.approximateWeight} ${widget.package.weightUnit.value}', style: textTheme.bodyMedium?.copyWith(color: colorScheme.onSurface)),
          if (widget.package.description?.isNotEmpty ?? false) ...[
            const SizedBox(height: 4),
            Text('Description: ${widget.package.description}', style: textTheme.bodyMedium?.copyWith(color: colorScheme.onSurface)),
          ],
        ],
      ],
    );
  }

  Widget _buildVehicleCard(ColorScheme colorScheme, TextTheme textTheme) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: colorScheme.surfaceBright,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.08), blurRadius: 10, offset: const Offset(0, 2))],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Best Vehicle', style: textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600, color: colorScheme.onSurface)),
            const SizedBox(height: 16),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(color: colorScheme.primary.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
                  child: Icon(Icons.local_shipping, color: colorScheme.primary, size: 24),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(_idealVehicle.vehicleModelName.replaceAll('_', ' '), style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold, color: colorScheme.onSurface)),
                      const SizedBox(height: 4),
                      Text('Will be auto-assigned', style: textTheme.bodySmall?.copyWith(color: colorScheme.onSurface.withValues(alpha: 0.6))),
                    ],
                  ),
                ),
                Text(_idealVehicle.estimatedCost.toRupees(), style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold, color: colorScheme.primary)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPriceBreakdownCard(ColorScheme colorScheme, TextTheme textTheme) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: colorScheme.surfaceBright,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.08), blurRadius: 10, offset: const Offset(0, 2))],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Price Breakdown', style: textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600, color: colorScheme.onSurface)),
            const SizedBox(height: 16),
            _buildPriceRow('Base fare', _idealVehicle.breakdown.baseFare.toRupees(), colorScheme, textTheme),
            _buildPriceRow('Base km included', '${_idealVehicle.breakdown.baseKm} km', colorScheme, textTheme),
            _buildPriceRow('Per km rate', '${_idealVehicle.breakdown.perKm.toRupees()}/km', colorScheme, textTheme),
            _buildPriceRow('Distance', _idealVehicle.breakdown.distanceKm.toDistance(), colorScheme, textTheme),
            _buildPriceRow('Weight', _idealVehicle.breakdown.weightInTons.tonsToKg(), colorScheme, textTheme),
            Divider(height: 24, color: colorScheme.outline.withValues(alpha: 0.2)),
            _buildPriceRow('Total', _idealVehicle.estimatedCost.toRupees(), colorScheme, textTheme, isTotal: true),
          ],
        ),
      ),
    );
  }

  Widget _buildPriceRow(String label, String value, ColorScheme colorScheme, TextTheme textTheme, {bool isTotal = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: textTheme.bodyMedium?.copyWith(fontWeight: isTotal ? FontWeight.bold : FontWeight.normal, color: isTotal ? colorScheme.onSurface : colorScheme.onSurface.withValues(alpha: 0.8))),
          Text(value, style: textTheme.bodyMedium?.copyWith(fontWeight: isTotal ? FontWeight.bold : FontWeight.normal, color: isTotal ? colorScheme.primary : colorScheme.onSurface)),
        ],
      ),
    );
  }

  Widget _buildImportantNotesCard(ColorScheme colorScheme, TextTheme textTheme) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.primary.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colorScheme.primary.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Important Notes', style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold, color: colorScheme.primary)),
          const SizedBox(height: 8),
          Text(
            '• Please ensure the package is properly packed\n• Driver will verify package contents before pickup\n• Delivery time may vary based on traffic conditions\n• Contact details are mandatory for both locations',
            style: textTheme.bodySmall?.copyWith(color: colorScheme.onSurface.withValues(alpha: 0.8), height: 1.4),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomSection(ColorScheme colorScheme, TextTheme textTheme) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colorScheme.surfaceBright,
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 10, offset: const Offset(0, -2))],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Estimated Cost', style: textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600, color: colorScheme.onSurface)),
              Text(_idealVehicle.estimatedCost.toRupees(), style: textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold, color: colorScheme.primary)),
            ],
          ),
          const SizedBox(height: 16),
          SafeArea(
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isBooking ? null : _showConfirmationModal,
                style: ElevatedButton.styleFrom(
                  backgroundColor: colorScheme.primary,
                  foregroundColor: colorScheme.onPrimary,
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  elevation: 4,
                ),
                child: _isBooking
                    ? SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation<Color>(colorScheme.onPrimary)))
                    : Text('Confirm Booking', style: textTheme.titleMedium?.copyWith(color: colorScheme.onPrimary, fontWeight: FontWeight.bold)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _editLocation(bool isPickup) {
    if (!mounted) return;
    showModalBottomSheet<BuildContext>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      enableDrag: false,
      builder: (context) => AddressSearchPage(
        isPickup: isPickup,
        onAddressSelected: (address) {
          setState(() {
            if (isPickup) {
              _pickupAddress = BookingAddress.fromSavedAddress(address);
            } else {
              _dropAddress = BookingAddress.fromSavedAddress(address);
            }
          });
        },
      ),
    );
  }

  void _editPackageDetails() {
    if (mounted) {
      Navigator.pop(context);
      Navigator.pop(context);
    }
  }

  void _showConfirmationModal() {
    showModalBottomSheet(
      context: context,
      isDismissible: false,
      enableDrag: false,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (bottomSheetContext) => _PlacingOrderBottomSheet(
        onConfirmed: () {
          Navigator.pop(bottomSheetContext);
          _confirmBooking();
        },
        onCancelled: () => Navigator.pop(bottomSheetContext),
      ),
    );
  }

  Future<void> _confirmBooking() async {
    setState(() => _isBooking = true);
    try {
      final api = await ref.read(apiProvider.future);
      await createBooking(api, pickupAddress: _pickupAddress, dropAddress: _dropAddress, package: widget.package);
      ref.invalidate(activeBookingsProvider);
      if (mounted) _showSuccessDialog();
    } catch (e) {
      if (mounted) SnackBars.error(context, 'Booking failed: $e');
    } finally {
      if (mounted) setState(() => _isBooking = false);
    }
  }

  void _showSuccessDialog() {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    showModalBottomSheet(
      context: context,
      isDismissible: false,
      enableDrag: false,
      backgroundColor: Colors.transparent,
      builder: (bottomSheetContext) => PopScope(
        canPop: false,
        child: Container(
          decoration: BoxDecoration(
            color: cs.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Handle
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
                  const SizedBox(height: 24),
                  // Success icon
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.green.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.check_circle_rounded, color: Colors.green, size: 48),
                  ),
                  const SizedBox(height: 20),
                  Text('Booking Placed!', style: tt.titleLarge?.copyWith(fontWeight: FontWeight.w700, color: cs.onSurface)),
                  const SizedBox(height: 8),
                  Text(
                    'Your booking has been placed successfully. You will receive updates on your booking.',
                    textAlign: TextAlign.center,
                    style: tt.bodyMedium?.copyWith(color: cs.onSurface.withValues(alpha: 0.7)),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: () {
                        // Increment key to force rebuild BookingsScreen (resets tab to Active)
                        final currentKey = ref.read(bookingsScreenKeyProvider);
                        ref.read(bookingsScreenKeyProvider.notifier).state = currentKey + 1;
                        // Navigate to Bookings tab (index 1)
                        ref.read(selectedTabIndexProvider.notifier).state = 1;
                        Navigator.popUntil(context, (route) => route.isFirst);
                      },
                      style: FilledButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.directions_rounded, size: 20),
                          const SizedBox(width: 8),
                          Text('Go to Rides', style: tt.titleSmall?.copyWith(fontWeight: FontWeight.w600, color: cs.onPrimary)),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _PlacingOrderBottomSheet extends StatefulWidget {
  final VoidCallback onConfirmed;
  final VoidCallback onCancelled;
  const _PlacingOrderBottomSheet({required this.onConfirmed, required this.onCancelled});
  @override
  State<_PlacingOrderBottomSheet> createState() => _PlacingOrderBottomSheetState();
}

class _PlacingOrderBottomSheetState extends State<_PlacingOrderBottomSheet> with SingleTickerProviderStateMixin {
  int _countdown = 5;
  Timer? _timer;
  late AnimationController _progressController;

  @override
  void initState() {
    super.initState();
    _progressController = AnimationController(vsync: this, duration: const Duration(seconds: 5))..forward();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_countdown > 1) {
        setState(() => _countdown--);
      } else {
        timer.cancel();
        widget.onConfirmed();
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _progressController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Container(
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Linear progress indicator at top
            ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
              child: AnimatedBuilder(
                animation: _progressController,
                builder: (context, _) => LinearProgressIndicator(
                  value: _progressController.value,
                  minHeight: 4,
                  backgroundColor: cs.primary.withValues(alpha: 0.15),
                  valueColor: AlwaysStoppedAnimation<Color>(cs.primary),
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Truck icon centered
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: cs.primary.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.local_shipping_rounded, color: cs.primary, size: 32),
            ),

            const SizedBox(height: 20),

            // Title
            Text('Placing Booking', style: tt.titleMedium?.copyWith(fontWeight: FontWeight.w700, color: cs.onSurface)),

            const SizedBox(height: 8),

            // Countdown
            Text(
              'Your booking will be confirmed in $_countdown ${_countdown == 1 ? 'second' : 'seconds'}',
              style: tt.bodyMedium?.copyWith(color: cs.onSurface.withValues(alpha: 0.7)),
            ),

            const SizedBox(height: 6),

            // Info text
            Text(
              'Tap cancel if you need to make changes.',
              style: tt.bodySmall?.copyWith(color: cs.onSurface.withValues(alpha: 0.5)),
            ),

            const SizedBox(height: 24),

            // Cancel button
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: widget.onCancelled,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: cs.error,
                    side: BorderSide(color: cs.error.withValues(alpha: 0.5)),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: Text('Cancel', style: tt.titleSmall?.copyWith(fontWeight: FontWeight.w600)),
                ),
              ),
            ),

            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}

class DottedLinePainter extends CustomPainter {
  final Color color;
  DottedLinePainter({required this.color});
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color..strokeWidth = 2..style = PaintingStyle.stroke;
    const dashHeight = 3.0;
    const dashSpace = 3.0;
    double startY = 0;
    while (startY < size.height) {
      canvas.drawLine(Offset(0, startY), Offset(0, startY + dashHeight), paint);
      startY += dashHeight + dashSpace;
    }
  }
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
