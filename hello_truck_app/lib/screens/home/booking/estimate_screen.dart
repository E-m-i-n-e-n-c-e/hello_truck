import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hello_truck_app/models/booking.dart';
import 'package:hello_truck_app/models/booking_estimate.dart';
import 'package:hello_truck_app/models/package.dart';
import 'package:hello_truck_app/screens/home/booking/review_screen.dart';
import 'package:hello_truck_app/providers/booking_providers.dart';

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
          'Estimate',
          style: textTheme.titleLarge?.copyWith(
            color: colorScheme.onSurface,
            fontWeight: FontWeight.w700,
          ),
        ),
        centerTitle: true,
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
                Text(
                  error.toString(),
                  textAlign: TextAlign.center,
                  style: textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurface.withValues(alpha: 0.6),
                  ),
                ),
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
          final idealVehicle = estimate.topVehicles.firstWhere(
            (o) => o.vehicleModelName == estimate.idealVehicleModel,
          );

          return Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildIdealVehicleCard(idealVehicle, colorScheme, textTheme),
                      const SizedBox(height: 20),
                      _buildInfoBanner(colorScheme, textTheme),
                      const SizedBox(height: 20),
                      if (estimate.topVehicles.length > 1)
                        _buildOtherOptionsCard(estimate, colorScheme, textTheme),
                      if (estimate.topVehicles.length > 1)
                        const SizedBox(height: 20),
                      _buildTermsCard(colorScheme, textTheme),
                      const SizedBox(height: 20),
                      _buildAcknowledgeCheckbox(colorScheme, textTheme),
                      const SizedBox(height: 24),
                      _buildReviewButton(estimate, colorScheme, textTheme),
                      SizedBox(height: MediaQuery.of(context).padding.bottom + 8),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildIdealVehicleCard(VehicleOption idealVehicle, ColorScheme colorScheme, TextTheme textTheme) {
    return Container(
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
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: colorScheme.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(Icons.local_shipping, color: colorScheme.primary, size: 28),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: colorScheme.primary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          'Best Match',
                          style: textTheme.labelSmall?.copyWith(
                            color: colorScheme.primary,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        _vehicleLabel(idealVehicle.vehicleModelName),
                        style: textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: colorScheme.onSurface,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    colorScheme.primary.withValues(alpha: 0.08),
                    colorScheme.primary.withValues(alpha: 0.04),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Estimated Cost', style: textTheme.titleMedium?.copyWith(color: colorScheme.onSurface.withValues(alpha: 0.8))),
                  Text('₹${idealVehicle.estimatedCost.toStringAsFixed(0)}', style: textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold, color: colorScheme.primary)),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                _buildSpecChip(Icons.scale, 'Up to ${(idealVehicle.maxWeightTons * 1000).toStringAsFixed(0)} kg', colorScheme, textTheme),
                const SizedBox(width: 12),
                _buildSpecChip(Icons.check_circle, 'Available', colorScheme, textTheme, isSuccess: true),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoBanner(ColorScheme colorScheme, TextTheme textTheme) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Icon(Icons.info_outline, color: Colors.blue.shade700, size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'The best available vehicle matching your requirements will be assigned automatically.',
              style: textTheme.bodyMedium?.copyWith(color: Colors.blue.shade800, height: 1.4),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOtherOptionsCard(BookingEstimate estimate, ColorScheme colorScheme, TextTheme textTheme) {
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
            Text('Other Options', style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600, color: colorScheme.onSurface)),
            const SizedBox(height: 4),
            Text('For your reference only', style: textTheme.bodySmall?.copyWith(color: colorScheme.onSurface.withValues(alpha: 0.6))),
            const SizedBox(height: 16),
            ...estimate.topVehicles.where((v) => v.vehicleModelName != estimate.idealVehicleModel).take(2).map((opt) => _buildVehicleInfoTile(opt, colorScheme, textTheme)),
          ],
        ),
      ),
    );
  }

  Widget _buildTermsCard(ColorScheme colorScheme, TextTheme textTheme) {
    return Container(
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
          Text('Terms and Conditions', style: textTheme.titleSmall?.copyWith(color: colorScheme.primary, fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          Text(
            '• Prices are estimates and may vary based on real-time factors.\n'
            '• Loading distance limit: up to 50 feet from vehicle (longer distances may incur additional charges).\n'
            '• Additional charges may apply for extended waiting time after pickup verification, change of destination, or change in package details.',
            style: textTheme.bodySmall?.copyWith(color: colorScheme.onSurface.withValues(alpha: 0.75), height: 1.35),
          ),
        ],
      ),
    );
  }

  Widget _buildAcknowledgeCheckbox(ColorScheme colorScheme, TextTheme textTheme) {
    return GestureDetector(
      onTap: () => setState(() => _acknowledged = !_acknowledged),
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: _acknowledged ? colorScheme.primary.withValues(alpha: 0.08) : colorScheme.surfaceBright,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: _acknowledged ? colorScheme.primary.withValues(alpha: 0.3) : colorScheme.outline.withValues(alpha: 0.2), width: 1.5),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8, offset: const Offset(0, 2))],
        ),
        child: Row(
          children: [
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color: _acknowledged ? colorScheme.primary : Colors.transparent,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: _acknowledged ? colorScheme.primary : colorScheme.outline.withValues(alpha: 0.5), width: 2),
              ),
              child: _acknowledged ? Icon(Icons.check, size: 16, color: colorScheme.onPrimary) : null,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'I have read and acknowledge the terms and conditions for this booking.',
                style: textTheme.bodyMedium?.copyWith(color: _acknowledged ? colorScheme.primary : colorScheme.onSurface.withValues(alpha: 0.85), height: 1.4),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReviewButton(BookingEstimate estimate, ColorScheme colorScheme, TextTheme textTheme) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _acknowledged ? () => _proceedToReview(estimate) : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: colorScheme.primary,
          foregroundColor: colorScheme.onPrimary,
          disabledBackgroundColor: colorScheme.onSurface.withValues(alpha: 0.12),
          disabledForegroundColor: colorScheme.onSurface.withValues(alpha: 0.38),
          padding: const EdgeInsets.symmetric(vertical: 18),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          elevation: _acknowledged ? 4 : 0,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.bookmark_border),
            const SizedBox(width: 8),
            Text('Review Order', style: textTheme.titleMedium?.copyWith(color: _acknowledged ? colorScheme.onPrimary : colorScheme.onSurface.withValues(alpha: 0.38), fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }

  Widget _buildSpecChip(IconData icon, String text, ColorScheme colorScheme, TextTheme textTheme, {bool isSuccess = false}) {
    final color = isSuccess ? Colors.green : colorScheme.primary;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(20)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 6),
          Text(text, style: textTheme.bodySmall?.copyWith(color: color, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  Widget _buildVehicleInfoTile(VehicleOption option, ColorScheme colorScheme, TextTheme textTheme) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colorScheme.outline.withValues(alpha: 0.15)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: colorScheme.onSurface.withValues(alpha: 0.05), borderRadius: BorderRadius.circular(8)),
            child: Icon(Icons.local_shipping, color: colorScheme.onSurface.withValues(alpha: 0.6), size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(_vehicleLabel(option.vehicleModelName), style: textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600, color: colorScheme.onSurface)),
                const SizedBox(height: 2),
                Text('Up to ${(option.maxWeightTons * 1000).toStringAsFixed(0)} kg', style: textTheme.bodySmall?.copyWith(color: colorScheme.onSurface.withValues(alpha: 0.6))),
              ],
            ),
          ),
          Text('₹${option.estimatedCost.toStringAsFixed(0)}', style: textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600, color: colorScheme.onSurface.withValues(alpha: 0.8))),
        ],
      ),
    );
  }

  String _vehicleLabel(String vehicleModelName) => vehicleModelName.replaceAll('_', ' ');

  void _proceedToReview(BookingEstimate estimate) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ReviewScreen(
          pickupAddress: widget.pickupAddress,
          dropAddress: widget.dropAddress,
          package: widget.package,
          estimate: estimate,
        ),
      ),
    );
  }
}
