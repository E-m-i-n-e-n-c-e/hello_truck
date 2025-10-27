import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hello_truck_app/models/booking.dart';
import 'package:hello_truck_app/models/booking_estimate.dart';
import 'package:hello_truck_app/models/package.dart';
import 'package:hello_truck_app/screens/home/booking/review_screen.dart';
import 'package:hello_truck_app/providers/booking_providers.dart';
import 'package:hello_truck_app/models/enums/booking_enums.dart';

class EstimateScreen extends ConsumerStatefulWidget {
  final BookingAddress pickupAddress;
  final BookingAddress dropAddress;
  final Package package;

  const EstimateScreen({
    super.key,
    required this.pickupAddress,
    required this.dropAddress,
    required this.package,
  });

  @override
  ConsumerState<EstimateScreen> createState() => _EstimateScreenState();
}

class _EstimateScreenState extends ConsumerState<EstimateScreen> {
  VehicleType? _selectedVehicleType;
  bool _acknowledged = false;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    final estimateAsync = ref.watch(bookingEstimateProvider((
      pickupAddress: widget.pickupAddress,
      dropAddress: widget.dropAddress,
      package: widget.package,
    )));

    final media = MediaQuery.of(context);
    return MediaQuery(
      data: media.copyWith(textScaler: TextScaler.linear(media.textScaler.scale(0.95).clamp(0.9, 1.0))),
      child: Scaffold(
        backgroundColor: colorScheme.surfaceBright,
        appBar: AppBar(
          backgroundColor: colorScheme.surfaceBright,
          elevation: 0,
          leading: IconButton(
            icon: Icon(Icons.arrow_back, color: Colors.black.withValues(alpha: 0.8)),
            onPressed: () => Navigator.pop(context),
          ),
          title: Text(
            'Select Vehicle',
            style: textTheme.titleLarge?.copyWith(
              color: Colors.black.withValues(alpha: 0.85),
              fontWeight: FontWeight.w500,
            ),
          ),
          centerTitle: false,
        ),
        body: estimateAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, stackTrace) => Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.error_outline, color: Colors.red.shade400, size: 48),
                  const SizedBox(height: 12),
                  Text('Failed to load estimate', style: textTheme.titleMedium),
                  const SizedBox(height: 6),
                  Text(error.toString(), textAlign: TextAlign.center, style: textTheme.bodySmall?.copyWith(color: Colors.grey.shade600)),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => ref.invalidate(bookingEstimateProvider((
                      pickupAddress: widget.pickupAddress,
                      dropAddress: widget.dropAddress,
                      package: widget.package,
                    ))),
                    child: const Text('Retry'),
                  )
                ],
              ),
            ),
          ),
          data: (estimate) {
            // Set selected vehicle type if not already set
            if (_selectedVehicleType == null) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                setState(() {
                  _selectedVehicleType = estimate.suggestedVehicleType;
                });
              });
            }

            return Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        // Suggested vehicle banner
                        Container(
                          width: double.infinity,
                          decoration: BoxDecoration(
                            color: colorScheme.primary.withValues(alpha: 0.06),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: colorScheme.primary.withValues(alpha: 0.15)),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: colorScheme.surfaceBright,
                                    borderRadius: BorderRadius.circular(12),
                                    boxShadow: [
                                      BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 8, offset: const Offset(0, 2)),
                                    ],
                                  ),
                                  child: Icon(Icons.recommend, color: colorScheme.primary),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text('Suggested vehicle', style: textTheme.bodySmall?.copyWith(color: colorScheme.primary, fontWeight: FontWeight.w700)),
                                      const SizedBox(height: 4),
                                      Text(
                                        _vehicleLabel(estimate.suggestedVehicleType),
                                        style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        'Suggested based on weight',
                                        style: textTheme.bodySmall?.copyWith(color: Colors.black.withValues(alpha: 0.6)),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  '₹${estimate.vehicleOptions.firstWhere((o) => o.vehicleType == estimate.suggestedVehicleType).estimatedCost.toStringAsFixed(2)}',
                                  style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                                ),
                              ],
                            ),
                          ),
                        ),

                        const SizedBox(height: 20),

                        // Vehicle Options (from estimate)
                        Container(
                          width: double.infinity,
                          decoration: BoxDecoration(
                            color: colorScheme.surfaceBright,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.08),
                                blurRadius: 10,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(20),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Choose a vehicle',
                                  style: textTheme.titleLarge?.copyWith(
                                    color: Colors.black,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                const SizedBox(height: 12),
                                ...estimate.vehicleOptions.map((opt) => _buildVehicleOptionTile(opt)),
                              ],
                            ),
                          ),
                        ),

                    const SizedBox(height: 12),

                    // Disclaimer
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: colorScheme.primary.withValues(alpha: 0.05),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: colorScheme.primary.withValues(alpha: 0.15)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Terms and Conditions',
                            style: textTheme.titleSmall?.copyWith(
                              color: colorScheme.primary,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '• Prices are estimates and may vary based on real-time factors.\n'
                            '• Loading distance limit: up to 50 feet from vehicle (longer distances may incur additional charges).\n'
                            '• Additional charges may apply for extended waiting time after pickup verification, change of destination, or change in package details.',
                            style: textTheme.bodySmall?.copyWith(
                              color: Colors.black.withValues(alpha: 0.75),
                              height: 1.35,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Acknowledge checkbox with better styling
                    GestureDetector(
                      onTap: () => setState(() => _acknowledged = !_acknowledged),
                      behavior: HitTestBehavior.opaque,
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: _acknowledged
                            ? colorScheme.primary.withValues(alpha: 0.08)
                            : Colors.grey.withValues(alpha: 0.04),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: _acknowledged
                              ? colorScheme.primary.withValues(alpha: 0.3)
                              : colorScheme.outline.withValues(alpha: 0.2),
                            width: 1.5,
                          ),
                        ),
                        child: Row(
                          children: [
                            InkWell(
                              onTap: () => setState(() => _acknowledged = !_acknowledged),
                              borderRadius: BorderRadius.circular(6),
                              child: Container(
                                width: 24,
                                height: 24,
                                decoration: BoxDecoration(
                                  color: _acknowledged ? colorScheme.primary : Colors.transparent,
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(
                                    color: _acknowledged
                                      ? colorScheme.primary
                                      : colorScheme.outline.withValues(alpha: 0.5),
                                    width: 2,
                                  ),
                                ),
                                child: _acknowledged
                                  ? Icon(
                                      Icons.check,
                                      size: 16,
                                      color: colorScheme.onPrimary,
                                    )
                                  : null,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                'I have read and acknowledge the terms and conditions for this booking.',
                                style: textTheme.bodyMedium?.copyWith(
                                  color: _acknowledged
                                    ? colorScheme.primary
                                    : Colors.black.withValues(alpha: 0.85),
                                  height: 1.4,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 24),

                        // Review button at the end (no sticky footer, no total)
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: (_selectedVehicleType != null && _acknowledged)
                                ? () => _proceedToReview(estimate)
                                : null,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: colorScheme.primary,
                              foregroundColor: colorScheme.onPrimary,
                              padding: const EdgeInsets.symmetric(vertical: 18),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                              elevation: 8,
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.bookmark_border),
                                const SizedBox(width: 8),
                                Text(
                                  'Review Order',
                                  style: textTheme.titleMedium?.copyWith(
                                    color: colorScheme.onPrimary,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        SizedBox(height: MediaQuery.of(context).padding.bottom + 8),
                      ],
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildVehicleOptionTile(VehicleOption option) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final isSelected = _selectedVehicleType == option.vehicleType;
    final isDisabled = !option.isAvailable;

    IconData leadingIcon;
    switch (option.vehicleType) {
      case VehicleType.twoWheeler:
        leadingIcon = Icons.two_wheeler;
        break;
      case VehicleType.threeWheeler:
        leadingIcon = Icons.delivery_dining; // better visual for three-wheeler
        break;
      case VehicleType.fourWheeler:
        leadingIcon = Icons.local_shipping;
        break;
    }

    final card = Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(
            color: isDisabled
                ? colorScheme.outline.withValues(alpha: 0.15)
                : (isSelected ? colorScheme.primary : colorScheme.outline.withValues(alpha: 0.3)),
            width: isSelected && !isDisabled ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(12),
          color: isDisabled
              ? Colors.grey.shade100
              : (isSelected ? colorScheme.primary.withValues(alpha: 0.05) : null),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: isDisabled ? Colors.grey.shade200 : colorScheme.primary.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(leadingIcon, color: isDisabled ? Colors.grey : colorScheme.primary),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          _vehicleLabel(option.vehicleType),
                          style: textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                            color: isDisabled ? Colors.grey : null,
                          ),
                        ),
                      ),
                      Text(
                        isDisabled ? '--' : '₹${option.estimatedCost.toStringAsFixed(2)}',
                        style: textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: isDisabled ? Colors.grey : null,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      _pill(option.isAvailable ? 'Available' : 'Unavailable', option.isAvailable ? Colors.green : Colors.grey),
                      const SizedBox(width: 8),
                      _pill('Up to ${option.weightLimit.toStringAsFixed(0)} kg', isDisabled ? Colors.grey : colorScheme.primary),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      );

    if (isDisabled) {
      return IgnorePointer(ignoring: true, child: card);
    }

    return InkWell(
      onTap: () {
        setState(() {
          _selectedVehicleType = option.vehicleType;
        });
      },
      borderRadius: BorderRadius.circular(12),
      child: card,
    );
  }

  Widget _pill(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(text, style: TextStyle(color: color, fontWeight: FontWeight.w600, fontSize: 12)),
    );
  }

  // Removed calculation breakdown per selection requirements

  String _vehicleLabel(VehicleType type) {
    switch (type) {
      case VehicleType.twoWheeler:
        return 'Two Wheeler';
      case VehicleType.threeWheeler:
        return 'Three Wheeler';
      case VehicleType.fourWheeler:
        return 'Four Wheeler';
    }
  }

  void _proceedToReview(BookingEstimate estimate) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ReviewScreen(
          pickupAddress: widget.pickupAddress,
          dropAddress: widget.dropAddress,
          package: widget.package,
          estimate: estimate,
          selectedVehicleType: _selectedVehicleType!,
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
    final paint = Paint()
      ..color = color
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    const dashHeight = 3.0;
    const dashSpace = 3.0;
    double startY = 0;

    while (startY < size.height) {
      canvas.drawLine(
        Offset(0, startY),
        Offset(0, startY + dashHeight),
        paint,
      );
      startY += dashHeight + dashSpace;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}