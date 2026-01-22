import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hello_truck_app/models/gst_details.dart';
import 'package:hello_truck_app/providers/auth_providers.dart';
import 'package:hello_truck_app/api/gst_details_api.dart' as gst_api;
import 'package:hello_truck_app/widgets/snackbars.dart';
import 'package:hello_truck_app/screens/profile/gst_details_screen.dart';

/// Centralized GST Details Modal
/// Can be used for both adding and editing GST details
class GstDetailsModal extends ConsumerStatefulWidget {
  final GstDetails? existingDetails;
  final VoidCallback onSuccess;
  final bool navigateToScreenAfterAdd;

  const GstDetailsModal({
    super.key,
    this.existingDetails,
    required this.onSuccess,
    this.navigateToScreenAfterAdd = false,
  });

  /// Show the modal as a bottom sheet
  static Future<String?> show(
    BuildContext context, {
    GstDetails? existingDetails,
    required VoidCallback onSuccess,
    bool navigateToScreenAfterAdd = false,
  }) {
    return showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => GstDetailsModal(
        existingDetails: existingDetails,
        onSuccess: onSuccess,
        navigateToScreenAfterAdd: navigateToScreenAfterAdd,
      ),
    );
  }

  @override
  ConsumerState<GstDetailsModal> createState() => _GstDetailsModalState();
}

class _GstDetailsModalState extends ConsumerState<GstDetailsModal> {
  late final TextEditingController _gstNumberController;
  late final TextEditingController _businessNameController;
  late final TextEditingController _businessAddressController;
  late final GlobalKey<FormState> _formKey;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _gstNumberController = TextEditingController(text: widget.existingDetails?.gstNumber ?? '');
    _businessNameController = TextEditingController(text: widget.existingDetails?.businessName ?? '');
    _businessAddressController = TextEditingController(text: widget.existingDetails?.businessAddress ?? '');
    _formKey = GlobalKey<FormState>();
  }

  @override
  void dispose() {
    _gstNumberController.dispose();
    _businessNameController.dispose();
    _businessAddressController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final api = ref.read(apiProvider).value!;
      final gstNumber = _gstNumberController.text.trim();

      if (widget.existingDetails != null) {
        await gst_api.updateGstDetails(
          api,
          id: widget.existingDetails!.id ?? '',
          gstNumber: gstNumber,
          businessName: _businessNameController.text.trim(),
          businessAddress: _businessAddressController.text.trim(),
        );
      } else {
        await gst_api.addGstDetails(
          api,
          gstNumber: gstNumber,
          businessName: _businessNameController.text.trim(),
          businessAddress: _businessAddressController.text.trim(),
        );
      }

      if (mounted) {
        widget.onSuccess();
        // Return the GST number when adding new GST
        Navigator.pop(context, widget.existingDetails == null ? gstNumber : null);

        // Navigate to GST details screen after adding (if flag is set and we're adding, not editing)
        if (widget.navigateToScreenAfterAdd && widget.existingDetails == null) {
          // Import is needed at the top of the file
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => const GstDetailsScreen(),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        if (e.toString().contains('GST number already exists but is inactive. Please reactivate it.')) {
          _showReactivateDialog(_gstNumberController.text.trim());
        } else {
          SnackBars.error(context, 'Failed to ${widget.existingDetails == null ? 'add' : 'update'} GST details: $e');
        }
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _showReactivateDialog(String gstNumber) async {
    final cs = Theme.of(context).colorScheme;

    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('GST Details Already Exists'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'We found an existing GST registration with this number that is currently inactive.',
            ),
            const SizedBox(height: 12),
            const Text(
              'Would you like to reactivate these GST details?',
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: cs.surfaceContainerHighest.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                'GST Number: $gstNumber',
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Reactivate'),
          ),
        ],
      ),
    );

    if (result == true) {
      try {
        final api = ref.read(apiProvider).value!;
        await gst_api.reactivateGstDetails(api, gstNumber);
        if (mounted) {
          widget.onSuccess();
          // Return the GST number when reactivating
          Navigator.of(context).pop(gstNumber);
          SnackBars.success(context, 'GST details reactivated successfully');

          // Navigate to GST details screen after reactivating (if flag is set)
          if (widget.navigateToScreenAfterAdd) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const GstDetailsScreen(),
              ),
            );
          }
        }
      } catch (e) {
        if (mounted) {
          SnackBars.error(context, 'Failed to reactivate GST details: $e');
        }
      }
    }
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
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: cs.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      Icons.receipt_long_rounded,
                      color: cs.primary,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      widget.existingDetails == null ? 'Add GST Details' : 'Edit GST Details',
                      style: tt.titleLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: cs.onSurface,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: Icon(Icons.close_rounded, color: cs.onSurface.withValues(alpha: 0.6)),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Form
              Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildTextField(
                      controller: _gstNumberController,
                      label: 'GST Number',
                      hint: 'Enter GST number',
                      maxLength: 15,
                      textCapitalization: TextCapitalization.characters,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'GST number is required';
                        }
                        if (!RegExp(r'^[0-9]{2}[A-Z]{5}[0-9]{4}[A-Z]{1}[1-9A-Z]{1}Z[0-9A-Z]{1}$')
                            .hasMatch(value.trim())) {
                          return 'Invalid GST number format';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    _buildTextField(
                      controller: _businessNameController,
                      label: 'Business Name',
                      hint: 'Enter business name',
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Business name is required';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    _buildTextField(
                      controller: _businessAddressController,
                      label: 'Business Address',
                      hint: 'Enter business address',
                      maxLines: 3,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Business address is required';
                        }
                        return null;
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Action Buttons
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _isLoading ? null : () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text('Cancel'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _save,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: cs.primary,
                        foregroundColor: cs.onPrimary,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: _isLoading
                          ? SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(cs.onPrimary),
                              ),
                            )
                          : Text(widget.existingDetails == null ? 'Add' : 'Update'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    String? Function(String?)? validator,
    int maxLines = 1,
    int? maxLength,
    TextCapitalization textCapitalization = TextCapitalization.none,
  }) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              label,
              style: tt.bodySmall?.copyWith(
                color: cs.onSurface.withValues(alpha: 0.7),
                fontWeight: FontWeight.w600,
              ),
            ),
            if (validator != null)
              Text(
                ' *',
                style: tt.bodySmall?.copyWith(
                  color: cs.error,
                  fontWeight: FontWeight.w600,
                ),
              ),
          ],
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          validator: validator,
          maxLines: maxLines,
          maxLength: maxLength,
          textCapitalization: textCapitalization,
          enabled: !_isLoading,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: tt.bodyMedium?.copyWith(
              color: cs.onSurface.withValues(alpha: 0.4),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            filled: true,
            fillColor: cs.surfaceContainerHighest.withValues(alpha: 0.3),
            counterText: '',
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: cs.outline.withValues(alpha: 0.3)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: cs.primary, width: 1.5),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: cs.error),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: cs.error),
            ),
          ),
        ),
      ],
    );
  }
}
