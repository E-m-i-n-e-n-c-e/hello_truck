import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hello_truck_app/models/booking.dart';
import 'package:hello_truck_app/models/booking_estimate.dart';
import 'package:hello_truck_app/models/enums/package_enums.dart';
import 'package:hello_truck_app/models/enums/invoice_enums.dart';
import 'package:hello_truck_app/models/gst_details.dart';
import 'package:hello_truck_app/models/invoice.dart';
import 'package:hello_truck_app/models/package.dart';
import 'package:hello_truck_app/api/booking_api.dart';
import 'package:hello_truck_app/providers/auth_providers.dart';
import 'package:hello_truck_app/providers/booking_providers.dart';
import 'package:hello_truck_app/providers/customer_providers.dart';
import 'package:hello_truck_app/providers/provider_registry.dart';
import 'package:hello_truck_app/screens/home/booking/widgets/address_search_page.dart';
import 'package:hello_truck_app/widgets/gst_details_modal.dart';
import 'package:hello_truck_app/widgets/snackbars.dart';
import 'package:hello_truck_app/widgets/price_calculation_modal.dart';
import 'package:hello_truck_app/utils/format_utils.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
  String? _selectedGstNumber; // Track selected GST number
  bool _hasLoadedLastUsedGst = false; // Track if we've loaded from prefs
  double? _walletBalance; // Track wallet balance (loaded once)
  bool _hasLoadedWallet = false; // Track if we've loaded wallet
  static const double _platformFee = 20.0; // Platform fee constant
  static const String _lastUsedGstKey = 'last_used_gst_number';
  bool _isRecalculating = false; // Track if we're recalculating estimate
  late BookingEstimate _currentEstimate; // Track current estimate
  bool _hasChanges = false; // Track if any changes were made

  VehicleOption get _idealVehicle {
    return _currentEstimate.topVehicles.firstWhere(
      (o) => o.vehicleModelName == _currentEstimate.idealVehicleModel,
    );
  }

  // Calculate wallet to be applied (supports both positive credit and negative debt)
  double _calculateWalletApplied(double total) {
    final balance = _walletBalance ?? 0.0;
    if (balance == 0) return 0.0;
    if (balance > 0) {
      // Positive balance: apply up to total amount
      return balance > total ? total : balance;
    } else {
      // Negative balance (debt): apply full debt
      return balance;
    }
  }

  // Calculate total with platform fee
  double _calculateTotal(bool isGstLoading) {
    // If GST is loading, show platform fee (no discount yet)
    final platformFee = (_selectedGstNumber != null && !isGstLoading) ? 0.0 : _platformFee;
    return _idealVehicle.estimatedCost + platformFee;
  }

  // Calculate final amount after wallet (credit reduces, debt increases)
  double _calculateFinalAmount(double total) {
    final walletApplied = _calculateWalletApplied(total);
    return total - walletApplied;
  }

  @override
  void initState() {
    super.initState();
    _pickupAddress = widget.pickupAddress;
    _dropAddress = widget.dropAddress;
    _currentEstimate = widget.estimate; // Initialize with passed estimate
    _loadLastUsedGst();
    _loadWalletBalance();
  }

  /// Load wallet balance once
  Future<void> _loadWalletBalance() async {
    try {
      final customer = await ref.read(customerProvider.future);
      if (mounted && !_hasLoadedWallet) {
        setState(() {
          _walletBalance = customer.walletBalance;
          _hasLoadedWallet = true;
        });
      }
    } catch (e) {
      // If loading fails, set to 0
      if (mounted && !_hasLoadedWallet) {
        setState(() {
          _walletBalance = 0.0;
          _hasLoadedWallet = true;
        });
      }
    }
  }

  /// Create BookingUpdate if there are changes
  BookingUpdate? _createUpdateIfChanged() {
    if (!_hasChanges) return null;

    return BookingUpdate(
      pickupAddress: _pickupAddress,
      dropAddress: _dropAddress,
      estimate: _currentEstimate,
    );
  }

  /// Load the last used GST number from SharedPreferences
  Future<void> _loadLastUsedGst() async {
    final prefs = await SharedPreferences.getInstance();
    final lastUsedGst = prefs.getString(_lastUsedGstKey);

    if (lastUsedGst != null && mounted) {
      try {
        // Wait for provider to resolve before validating
        final gstDetailsList = await ref.read(gstDetailsProvider.future);

        if (mounted && !_hasLoadedLastUsedGst) {
          // Check if the last used GST still exists in the list
          final isValid = gstDetailsList.any((gst) => gst.gstNumber == lastUsedGst);
          setState(() {
            _selectedGstNumber = isValid ? lastUsedGst : null;
            _hasLoadedLastUsedGst = true;
          });
        }
      } catch (e) {
        // If provider fails, just don't auto-select
        if (mounted && !_hasLoadedLastUsedGst) {
          setState(() {
            _hasLoadedLastUsedGst = true;
          });
        }
      }
    }
  }

  /// Save the selected GST number to SharedPreferences
  Future<void> _saveLastUsedGst(String? gstNumber) async {
    final prefs = await SharedPreferences.getInstance();
    if (gstNumber != null) {
      await prefs.setString(_lastUsedGstKey, gstNumber);
    } else {
      await prefs.remove(_lastUsedGstKey);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    // Watch GST details provider to check loading state
    final gstDetailsAsync = ref.watch(gstDetailsProvider);
    final isGstLoading = _selectedGstNumber != null && gstDetailsAsync.when(
      loading: () => true,
      error: (_, _) => false,
      data: (gstDetailsList) => !gstDetailsList.any((gst) => gst.gstNumber == _selectedGstNumber),
    );

    return PopScope(
      canPop: false, // Always intercept back button
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return; // Already popped, nothing to do

        // Don't allow back during booking or recalculation
        if (_isBooking || _isRecalculating) return;

        // Pop with update if changes were made
        final update = _createUpdateIfChanged();
        if (mounted) {
          Navigator.of(context).pop(update);
        }
      },
      child: Scaffold(
        backgroundColor: colorScheme.surface,
        appBar: AppBar(
          backgroundColor: colorScheme.surface,
          elevation: 0,
          leading: IconButton(
            icon: Icon(Icons.arrow_back, color: colorScheme.onSurface),
            onPressed: () {
              // Don't allow back during booking or recalculation
              if (_isBooking || _isRecalculating) return;

              final update = _createUpdateIfChanged();
              Navigator.pop(context, update);
            },
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
                    _buildPriceBreakdownCard(colorScheme, textTheme, isGstLoading),
                    const SizedBox(height: 12),
                    _buildGstSelectionCard(colorScheme, textTheme),
                    const SizedBox(height: 20),
                    _buildImportantNotesCard(colorScheme, textTheme),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
            _buildBottomSection(colorScheme, textTheme, isGstLoading),
          ],
        ),
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

  Widget _buildGstSelectionCard(ColorScheme colorScheme, TextTheme textTheme) {
    final gstDetailsAsync = ref.watch(gstDetailsProvider);

    return gstDetailsAsync.when(
      loading: () => const SizedBox.shrink(),
      error: (_, _) => const SizedBox.shrink(),
      data: (gstDetailsList) {
        if (gstDetailsList.isEmpty) {
          // Compact "Add GSTIN" card
          return InkWell(
            onTap: () => _showAddGstDialog(),
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: colorScheme.surfaceBright,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.08),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Icon(Icons.receipt_long_rounded, color: colorScheme.primary, size: 22),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Add GSTIN',
                          style: textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: colorScheme.onSurface,
                          ),
                        ),
                        Text(
                          'Save ₹20 platform fee on your order',
                          style: textTheme.bodySmall?.copyWith(
                            color: colorScheme.onSurface.withValues(alpha: 0.6),
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    Icons.chevron_right_rounded,
                    color: colorScheme.onSurface.withValues(alpha: 0.4),
                    size: 20,
                  ),
                ],
              ),
            ),
          );
        }

        // If no GST selected, show "Select GSTIN" card
        if (_selectedGstNumber == null) {
          return InkWell(
            onTap: () => _showGstSelectionModal(gstDetailsList, colorScheme, textTheme),
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: colorScheme.surfaceBright,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.08),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Icon(Icons.receipt_long_rounded, color: colorScheme.primary, size: 22),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Select GSTIN',
                          style: textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: colorScheme.onSurface,
                          ),
                        ),
                        Text(
                          'Save ₹20 platform fee on your order',
                          style: textTheme.bodySmall?.copyWith(
                            color: colorScheme.onSurface.withValues(alpha: 0.6),
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    Icons.chevron_right_rounded,
                    color: colorScheme.onSurface.withValues(alpha: 0.4),
                    size: 20,
                  ),
                ],
              ),
            ),
          );
        }

        // Show selected GST details
        // Try to find the selected GST in the list
        final selectedGst = gstDetailsList.cast<GstDetails?>().firstWhere(
          (gst) => gst?.gstNumber == _selectedGstNumber,
          orElse: () => null,
        );

        // If selected GST not found (during refresh), show loading state
        if (selectedGst == null) {
          return Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: colorScheme.surfaceBright,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.08),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                Icon(Icons.receipt_long_rounded, color: colorScheme.primary, size: 22),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Loading GST details...',
                        style: textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: colorScheme.onSurface.withValues(alpha: 0.6),
                        ),
                      ),
                      Text(
                        _selectedGstNumber ?? '',
                        style: textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurface.withValues(alpha: 0.4),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(colorScheme.primary),
                  ),
                ),
              ],
            ),
          );
        }

        return InkWell(
          onTap: () => _showGstSelectionModal(gstDetailsList, colorScheme, textTheme),
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: colorScheme.surfaceBright,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.08),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                Icon(Icons.receipt_long_rounded, color: colorScheme.primary, size: 22),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        selectedGst.businessName,
                        style: textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: colorScheme.onSurface,
                        ),
                      ),
                      Text(
                        selectedGst.gstNumber,
                        style: textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurface.withValues(alpha: 0.6),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  'Change',
                  style: textTheme.bodySmall?.copyWith(
                    color: colorScheme.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(width: 4),
                Icon(
                  Icons.chevron_right_rounded,
                  color: colorScheme.primary.withValues(alpha: 0.6),
                  size: 18,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showGstSelectionModal(List<GstDetails> gstDetailsList, ColorScheme colorScheme, TextTheme textTheme) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: colorScheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 20),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Text(
                  'Select GST Number',
                  style: textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: colorScheme.onSurface,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              // GST options with Material for ripple effect
              ...gstDetailsList.map((gst) => Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () {
                    setState(() {
                      _selectedGstNumber = gst.gstNumber;
                    });
                    _saveLastUsedGst(gst.gstNumber);
                    Navigator.pop(context);
                  },
                  child: ListTile(
                    leading: Icon(Icons.receipt_long_rounded, color: colorScheme.primary),
                    title: Text(
                      gst.businessName,
                      style: textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
                    ),
                    subtitle: Text(
                      gst.gstNumber,
                      style: textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurface.withValues(alpha: 0.6),
                      ),
                    ),
                    trailing: _selectedGstNumber == gst.gstNumber
                        ? Icon(Icons.check_circle, color: colorScheme.primary)
                        : null,
                  ),
                ),
              )),
              // Remove GST button (only show if GST is selected)
              if (_selectedGstNumber != null) ...[
                const SizedBox(height: 8),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () {
                        setState(() {
                          _selectedGstNumber = null;
                        });
                        _saveLastUsedGst(null);
                        Navigator.pop(context);
                      },
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: colorScheme.error.withValues(alpha: 0.3),
                          ),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.close_rounded, color: colorScheme.error, size: 18),
                            const SizedBox(width: 8),
                            Text(
                              'Remove GST (Pay ₹20 platform fee)',
                              style: textTheme.bodyMedium?.copyWith(
                                color: colorScheme.error,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _showAddGstDialog() async {
    final addedGstNumber = await GstDetailsModal.show(
      context,
      onSuccess: () {
        ref.invalidate(gstDetailsProvider);
        SnackBars.success(context, 'GST details added successfully');
      },
    );
    // If a GST number was returned (newly added or reactivated), select it and save it
    if (addedGstNumber != null && mounted) {
      setState(() {
        _selectedGstNumber = addedGstNumber;
      });
      _saveLastUsedGst(addedGstNumber);
    }
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

  Widget _buildPriceBreakdownCard(ColorScheme colorScheme, TextTheme textTheme, bool isGstLoading) {
    // If GST is loading, show platform fee (no discount yet)
    final platformFee = (_selectedGstNumber != null && !isGstLoading) ? 0.0 : _platformFee;
    final total = _calculateTotal(isGstLoading);

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
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text('Price Breakdown', style: textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600, color: colorScheme.onSurface)),
                Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () {
                      // Create a temporary Invoice from breakdown for the modal
                      final total = _calculateTotal(isGstLoading);
                      final walletApplied = _hasLoadedWallet ? _calculateWalletApplied(total) : 0.0;
                      final finalAmount = _hasLoadedWallet ? _calculateFinalAmount(total) : total;

                      final tempInvoice = Invoice(
                        id: '',
                        bookingId: '',
                        type: InvoiceType.estimate,
                        vehicleModelName: _idealVehicle.vehicleModelName,
                        basePrice: _idealVehicle.breakdown.baseFare,
                        perKmPrice: _idealVehicle.breakdown.perKm,
                        baseKm: _idealVehicle.breakdown.baseKm,
                        distanceKm: _idealVehicle.breakdown.distanceKm,
                        weightInTons: _idealVehicle.breakdown.weightInTons,
                        effectiveBasePrice: _idealVehicle.breakdown.baseFare * (_idealVehicle.breakdown.weightInTons > 1 ? _idealVehicle.breakdown.weightInTons : 1),
                        platformFee: platformFee,
                        totalPrice: total,
                        gstNumber: _selectedGstNumber,
                        walletApplied: walletApplied,
                        finalAmount: finalAmount,
                        isPaid: false,
                        createdAt: DateTime.now(),
                        updatedAt: DateTime.now(),
                      );
                      PriceCalculationModal.show(context, tempInvoice);
                    },
                    borderRadius: BorderRadius.circular(8),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Text(
                          'Learn more',
                          style: textTheme.labelMedium?.copyWith(
                            color: colorScheme.primary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Icon(Icons.chevron_right_rounded, size: 16, color: colorScheme.primary),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildPriceRow('Base fare', _idealVehicle.breakdown.baseFare.toRupees(), colorScheme, textTheme),
            _buildPriceRow('Base km included', '${_idealVehicle.breakdown.baseKm} km', colorScheme, textTheme),
            _buildPriceRow('Per km rate', '${_idealVehicle.breakdown.perKm.toRupees()}/km', colorScheme, textTheme),
            _buildPriceRow('Distance', _idealVehicle.breakdown.distanceKm.toDistance(), colorScheme, textTheme),
            _buildPriceRow('Weight', _idealVehicle.breakdown.weightInTons.tonsToKg(), colorScheme, textTheme),

            // Platform Fee
            if (platformFee > 0) ...[
              _buildPriceRow('Platform Fee', platformFee.toRupees(), colorScheme, textTheme),
            ] else ...[
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Text('Platform Fee', style: textTheme.bodyMedium?.copyWith(color: colorScheme.onSurface.withValues(alpha: 0.8))),
                        const SizedBox(width: 6),
                        Tooltip(
                          message: 'Platform fee waived for GST bookings',
                          triggerMode: TooltipTriggerMode.tap,
                          child: Icon(Icons.info_outline_rounded, size: 14, color: colorScheme.primary),
                        ),
                      ],
                    ),
                    Text('₹0 (GST)', style: textTheme.bodyMedium?.copyWith(color: Colors.green, fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
            ],

            Divider(height: 24, color: colorScheme.outline.withValues(alpha: 0.2)),
            _buildPriceRow('Total', total.toRupees(), colorScheme, textTheme),

            // Wallet Applied Section (only if wallet balance exists)
            if (_hasLoadedWallet && (_walletBalance ?? 0.0) != 0) ...[
              if (_calculateWalletApplied(total) > 0)
                _buildPriceRow('Wallet Applied', '-${_calculateWalletApplied(total).toRupees()}', colorScheme, textTheme, valueColor: Colors.green)
              else
                _buildPriceRow('Debt Cleared', '+${_calculateWalletApplied(total).abs().toRupees()}', colorScheme, textTheme, valueColor: Colors.orange),
            ],

            const SizedBox(height: 4),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Amount Payable', style: textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w700, color: colorScheme.onSurface)),
                Text(_calculateFinalAmount(total).toRupees(), style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800, color: colorScheme.primary)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPriceRow(String label, String value, ColorScheme colorScheme, TextTheme textTheme, {bool isTotal = false, Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: textTheme.bodyMedium?.copyWith(fontWeight: isTotal ? FontWeight.bold : FontWeight.normal, color: isTotal ? colorScheme.onSurface : colorScheme.onSurface.withValues(alpha: 0.8))),
          Text(value, style: textTheme.bodyMedium?.copyWith(fontWeight: isTotal ? FontWeight.bold : (valueColor != null ? FontWeight.w600 : FontWeight.normal), color: valueColor ?? (isTotal ? colorScheme.primary : colorScheme.onSurface))),
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

  Widget _buildBottomSection(ColorScheme colorScheme, TextTheme textTheme, bool isGstLoading) {
    final total = _calculateTotal(isGstLoading);
    final hasWallet = _hasLoadedWallet && (_walletBalance ?? 0.0) != 0;
    final displayAmount = hasWallet ? _calculateFinalAmount(total) : total;
    final isButtonDisabled = _isBooking || _isRecalculating || isGstLoading;

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
              _isRecalculating
                  ? Row(
                      children: [
                        SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(colorScheme.primary),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text('Calculating...', style: textTheme.titleMedium?.copyWith(color: colorScheme.onSurface.withValues(alpha: 0.6))),
                      ],
                    )
                  : Text(displayAmount.toRupees(), style: textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold, color: colorScheme.primary)),
            ],
          ),
          const SizedBox(height: 16),
          SafeArea(
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: isButtonDisabled ? null : _showConfirmationModal,
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

  void _editLocation(bool isPickup) async {
    if (!mounted) return;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      enableDrag: false,
      builder: (context) => AddressSearchPage(
        isPickup: isPickup,
        onAddressSelected: (address) async {
          final newAddress = BookingAddress.fromSavedAddress(address);

          // Update the address immediately
          setState(() {
            if (isPickup) {
              _pickupAddress = newAddress;
            } else {
              _dropAddress = newAddress;
            }
            _isRecalculating = true;
          });

          // Recalculate estimate with new addresses
          try {
            final api = await ref.read(apiProvider.future);
            final newEstimate = await getBookingEstimate(
              api,
              pickupAddress: _pickupAddress,
              dropAddress: _dropAddress,
              package: widget.package,
            );

            if (mounted) {
              setState(() {
                _currentEstimate = newEstimate;
                _isRecalculating = false;
                _hasChanges = true; // Mark that changes were made
              });
            }
          } catch (e) {
            if (mounted) {
              setState(() {
                _isRecalculating = false;
              });
              if(context.mounted) SnackBars.error(context, 'Failed to recalculate estimate: $e');
            }
          }
        },
      ),
    );
  }

  void _editPackageDetails() {
    if (mounted) {
      // Pass back update if any
      final update = _createUpdateIfChanged();
      Navigator.pop(context, update);
      Navigator.pop(context, update);
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
      await createBooking(
        api,
        pickupAddress: _pickupAddress,
        dropAddress: _dropAddress,
        package: widget.package,
        gstNumber: _selectedGstNumber,
      );
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
                  const SizedBox(height: 6),
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
              'Your booking will be placed in $_countdown ${_countdown == 1 ? 'second' : 'seconds'}',
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
