import 'package:flutter/material.dart';
import 'package:hello_truck_app/models/invoice.dart';
import 'package:hello_truck_app/utils/format_utils.dart';

class PriceCalculationModal {
  static void show(BuildContext context, Invoice invoice) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    // Calculate using correct formula from server:
    // effectiveBasePrice = basePrice * max(1, weightInTons)
    final effectiveBasePrice = invoice.basePrice * (invoice.weightInTons > 1 ? invoice.weightInTons : 1);

    // extraDistance = max(distanceKm - baseKm, 0)
    final extraDistance = (invoice.distanceKm - invoice.baseKm) > 0 ? (invoice.distanceKm - invoice.baseKm) : 0;

    // distanceCharges = extraDistance * perKm
    final distanceCharges = extraDistance * invoice.perKmPrice;

    // totalPrice = effectiveBasePrice + distanceCharges + platformFee
    final calculatedTotal = effectiveBasePrice + distanceCharges + invoice.platformFee;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.8,
        ),
        decoration: BoxDecoration(
          color: cs.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 20),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Price Calculation',
                        style: tt.titleLarge?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: cs.onSurface,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: Icon(Icons.close_rounded, color: cs.onSurface.withValues(alpha: 0.6)),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              Flexible(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Base Fare Section with weight multiplier
                      _buildCalculationSection(
                        cs,
                        tt,
                        'Base Fare',
                        'Base fare for ${invoice.vehicleModelName.replaceAll('_', ' ')}: ${invoice.basePrice.toRupees()}\n'
                        'Weight: ${invoice.weightInTons.tonsToKg()}\n'
                        'Weight multiplier: ${invoice.weightInTons > 1 ? invoice.weightInTons.toStringAsFixed(2) : '1.00'}',
                        effectiveBasePrice.toRupees(),
                        invoice.weightInTons > 1
                            ? '${invoice.basePrice.toRupees()} × ${invoice.weightInTons.toStringAsFixed(2)}'
                            : '${invoice.basePrice.toRupees()} × 1',
                      ),
                      const SizedBox(height: 16),

                      // Distance Calculation
                      _buildCalculationSection(
                        cs,
                        tt,
                        'Distance Charges',
                        'Total distance: ${invoice.distanceKm.toDistance()}\n'
                        'Base km included: ${invoice.baseKm} km\n'
                        'Extra km: ${extraDistance.toStringAsFixed(2)} km\n'
                        'Rate: ${invoice.perKmPrice.toRupees()}/km',
                        distanceCharges.toRupees(),
                        extraDistance > 0
                            ? '${extraDistance.toStringAsFixed(2)} km × ${invoice.perKmPrice.toRupees()}'
                            : 'No extra distance',
                      ),
                      const SizedBox(height: 16),

                      // Platform Fee
                      _buildCalculationSection(
                        cs,
                        tt,
                        'Platform Fee',
                        invoice.platformFee > 0
                            ? 'Service fee for using the platform'
                            : 'Waived for GST registered businesses',
                        invoice.platformFee > 0 ? invoice.platformFee.toRupees() : '₹0 (GST Applied)',
                        null,
                        isHighlighted: invoice.platformFee == 0,
                      ),
                      const SizedBox(height: 20),

                      // Total
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: cs.primary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: cs.primary.withValues(alpha: 0.3),
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Total Amount',
                              style: tt.titleMedium?.copyWith(
                                fontWeight: FontWeight.w700,
                                color: cs.onSurface,
                              ),
                            ),
                            Text(
                              calculatedTotal.toRupees(),
                              style: tt.titleLarge?.copyWith(
                                fontWeight: FontWeight.w900,
                                color: cs.primary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  static Widget _buildCalculationSection(
    ColorScheme cs,
    TextTheme tt,
    String title,
    String description,
    String amount,
    String? formula, {
    bool isHighlighted = false,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isHighlighted
            ? Colors.green.withValues(alpha: 0.1)
            : cs.surfaceContainerHighest.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isHighlighted
              ? Colors.green.withValues(alpha: 0.3)
              : cs.outline.withValues(alpha: 0.1),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: tt.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: cs.onSurface,
                ),
              ),
              Text(
                amount,
                style: tt.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: isHighlighted ? Colors.green : cs.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            description,
            style: tt.bodySmall?.copyWith(
              color: cs.onSurface.withValues(alpha: 0.7),
              height: 1.4,
            ),
          ),
          if (formula != null) ...[
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: cs.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                formula,
                style: tt.labelSmall?.copyWith(
                  color: cs.primary,
                  fontWeight: FontWeight.w600,
                  fontFamily: 'monospace',
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
