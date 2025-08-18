import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hello_truck_app/models/booking_estimate.dart';
import 'package:hello_truck_app/models/enums/package_enums.dart';
import 'package:hello_truck_app/models/saved_address.dart';
import 'package:hello_truck_app/models/package.dart';
import 'package:hello_truck_app/models/enums/booking_enums.dart';
import 'package:hello_truck_app/api/booking_api.dart';
import 'package:hello_truck_app/providers/auth_providers.dart';
import 'package:hello_truck_app/screens/home/booking/widgets/address_search_page.dart';
import 'package:hello_truck_app/widgets/snackbars.dart';

class ReviewScreen extends ConsumerStatefulWidget {
  final SavedAddress pickupAddress;
  final SavedAddress dropAddress;
  final Package package;
  final BookingEstimate estimate;
  final VehicleType selectedVehicleType;

  const ReviewScreen({
    super.key,
    required this.pickupAddress,
    required this.dropAddress,
    required this.package,
    required this.estimate,
    required this.selectedVehicleType,
  });

  @override
  ConsumerState<ReviewScreen> createState() => _ReviewScreenState();
}

class _ReviewScreenState extends ConsumerState<ReviewScreen> {
  bool _isBooking = false;
  late SavedAddress _pickupAddress;
  late SavedAddress _dropAddress;
  VehicleOption? get _selectedOption {
    try {
      return widget.estimate.vehicleOptions.firstWhere(
        (o) => o.vehicleType == widget.selectedVehicleType,
      );
    } catch (_) {
      return null;
    }
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
            fontWeight: FontWeight.bold,
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
                  // Order Summary Card
                  Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Colors.white,
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
                            'Order Summary',
                            style: textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.w500,
                              color: Colors.black,
                            ),
                          ),
                          const SizedBox(height: 20),

                          // Pickup Location
                          _buildLocationRow(
                            icon: Icons.circle,
                            iconColor: colorScheme.primary,
                            title: 'Pickup',
                            address: _pickupAddress,
                            onEdit: () => _editLocation(true),
                          ),

                          // Dotted line
                          Container(
                            margin: const EdgeInsets.symmetric(vertical: 12),
                            child: Row(
                              children: [
                                const SizedBox(width: 6),
                                SizedBox(
                                  width: 2,
                                  height: 30,
                                  child: CustomPaint(
                                    painter: DottedLinePainter(
                                      color: colorScheme.onSurface.withValues(alpha: 0.3),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 14),
                              ],
                            ),
                          ),

                          // Drop Location
                          _buildLocationRow(
                            icon: Icons.circle,
                            iconColor: Colors.red,
                            title: 'Drop',
                            address: _dropAddress,
                            onEdit: () => _editLocation(false),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Package Details Card
                  Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Colors.white,
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
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Package Details',
                                style: textTheme.titleLarge?.copyWith(
                                  fontWeight: FontWeight.w500,
                                  color: Colors.black,
                                ),
                              ),
                              TextButton(
                                onPressed: _editPackageDetails,
                                child: Text(
                                  'Edit',
                                  style: TextStyle(
                                    color: colorScheme.primary,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          _buildPackageDetailsSummary(),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Delivery Options / Vehicle Card
                  Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Colors.white,
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
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Selected Vehicle',
                                style: textTheme.titleLarge?.copyWith(
                                  fontWeight: FontWeight.w500,
                                  color: Colors.black,
                                ),
                              ),
                              TextButton(
                                onPressed: _editDeliveryOptions,
                                child: Text(
                                  'Edit',
                                  style: TextStyle(
                                    color: colorScheme.primary,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Colors.blue.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Icon(
                                  Icons.local_shipping,
                                  color: Colors.blue,
                                  size: 20,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      widget.selectedVehicleType.name.toUpperCase(),
                                      style: textTheme.titleMedium?.copyWith(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    Text(
                                      'Recommended for your item',
                                      style: textTheme.bodySmall?.copyWith(
                                        color: colorScheme.onSurface.withValues(alpha: 0.7),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              if (_selectedOption != null)
                                Text(
                                  '₹${_selectedOption!.estimatedCost.toStringAsFixed(2)}',
                                  style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                                ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Price Breakdown Card (from estimate)
                  Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Colors.white,
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
                            'Price Breakdown',
                            style: textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.w500,
                              color: Colors.black,
                            ),
                          ),
                          const SizedBox(height: 16),
                          if (_selectedOption != null) ...[
                            _buildPriceRow('Base fare', _selectedOption!.breakdown.baseFare),
                            _buildPriceRow('Distance charge', _selectedOption!.breakdown.distanceCharge),
                            _buildPriceRow('Weight multiplier', _selectedOption!.breakdown.weightMultiplier, isMultiplier: true),
                            _buildPriceRow('Vehicle multiplier', _selectedOption!.breakdown.vehicleMultiplier, isMultiplier: true),
                            const Divider(height: 24),
                            _buildPriceRow('Total multiplier', _selectedOption!.breakdown.totalMultiplier, isMultiplier: true),
                          ],
                          const Divider(height: 24),
                          _buildPriceRow(
                            'Total',
                            _selectedOption?.estimatedCost ?? 0.0,
                            isTotal: true,
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Terms and Conditions
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: colorScheme.primary.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: colorScheme.primary.withValues(alpha: 0.2),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Important Notes',
                          style: textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: colorScheme.primary,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '• Please ensure the package is properly packed\n'
                          '• Driver will verify package contents before pickup\n'
                          '• Delivery time may vary based on traffic conditions\n'
                          '• Contact details are mandatory for both locations',
                          style: textTheme.bodySmall?.copyWith(
                            color: colorScheme.onSurface.withValues(alpha: 0.8),
                            height: 1.4,
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

          // Bottom Section with Confirm Button
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 10,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Total Amount', style: textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w500, color: Colors.black)),
                    Text(
                      '₹${(_selectedOption?.estimatedCost ?? 0.0).toStringAsFixed(2)}',
                      style: textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w500,
                        color: colorScheme.primary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isBooking || _selectedOption == null ? null : _confirmBooking,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: colorScheme.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 18),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      elevation: 8,
                    ),
                    child: _isBooking
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : Text(
                            'Confirm Booking',
                            style: textTheme.titleMedium?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLocationRow({
    required IconData icon,
    required Color iconColor,
    required String title,
    required SavedAddress address,
    required VoidCallback onEdit,
  }) {
    final textTheme = Theme.of(context).textTheme;

    return Row(
      children: [
        Icon(
          icon,
          color: iconColor,
          size: 12,
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title.toUpperCase(),
                style: textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.5,
                  color: Colors.grey.shade600,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                address.name,
                style: textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (address.contactPhone.isNotEmpty) ...[
                const SizedBox(height: 2),
                Text(
                  '${address.contactName} • ${address.contactPhone}',
                  style: textTheme.bodySmall?.copyWith(
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ],
          ),
        ),
        TextButton(
          onPressed: onEdit,
          child: const Text('Edit'),
        ),
      ],
    );
  }

  Widget _buildPackageDetailsSummary() {
    final textTheme = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Type: ${widget.package.packageType == PackageType.commercial ? 'Commercial' : 'Personal'}',
          style: textTheme.bodyMedium,
        ),
        const SizedBox(height: 4),
        if (widget.package.productType == ProductType.agricultural) ...[
          Text(
            'Product: ${widget.package.productName}',
            style: textTheme.bodyMedium,
          ),
          const SizedBox(height: 4),
          Text(
            'Weight: ${widget.package.approximateWeight} ${widget.package.weightUnit?.value}',
            style: textTheme.bodyMedium,
          ),
        ],
        if (widget.package.productType == ProductType.nonAgricultural) ...[
          Text(
            'Category: Non-Agricultural Product',
            style: textTheme.bodyMedium,
          ),
          const SizedBox(height: 4),
          Text(
            'Weight: ${widget.package.averageWeight} KG',
            style: textTheme.bodyMedium,
          ),
          if (widget.package.description?.isNotEmpty ?? false) ...[
            const SizedBox(height: 4),
            Text(
              'Description: ${widget.package.description}',
              style: textTheme.bodyMedium,
            ),
          ],
        ],
      ],
    );
  }

  Widget _buildPriceRow(String label, double amount, {bool isTotal = false, bool isMultiplier = false}) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: textTheme.bodyMedium?.copyWith(
              fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
              color: isTotal ? colorScheme.onSurface : colorScheme.onSurface.withValues(alpha: 0.8),
            ),
          ),
          Text(
            isMultiplier ? '${amount.toStringAsFixed(2)}x' : '₹${amount.toStringAsFixed(2)}',
            style: textTheme.bodyMedium?.copyWith(
              fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
              color: isTotal ? colorScheme.primary : colorScheme.onSurface,
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
      backgroundColor: Colors.white,
      builder: (context) => AddressSearchPage(
        isPickup: isPickup,
        onAddressSelected: (address) {
          setState(() {
            if (isPickup) {
              _pickupAddress = address;
            } else {
              _dropAddress = address;
            }
          });
        },
      ),
    );
  }

  void _editPackageDetails() {
    if (mounted) {
      // Navigate back to package details
      Navigator.pop(context);
      Navigator.pop(context);
    }
  }

  void _editDeliveryOptions() {
    if (mounted) {
      // Navigate back to estimate screen
      Navigator.pop(context);
    }
  }

  Future<void> _confirmBooking() async {
    setState(() {
      _isBooking = true;
    });

    try {
      final api = await ref.read(apiProvider.future);
      await createBooking(
        api,
        pickupAddress: _pickupAddress.address,
        dropAddress: _dropAddress.address,
        package: widget.package,
        selectedVehicleType: widget.selectedVehicleType,
      );

      if (mounted) {
        // Show success dialog
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.green.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.check_circle,
                    color: Colors.green,
                    size: 48,
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Booking Confirmed!',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Your order has been placed successfully. You will receive updates on your booking.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.grey,
                  ),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.popUntil(context, (route) => route.isFirst);
                    },
                    child: const Text('Go to Home'),
                  ),
                ),
              ],
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        SnackBars.error(context, 'Booking failed: $e');
      }
    } finally {
      if (mounted) {
        setState(() {
          _isBooking = false;
        });
      }
    }
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