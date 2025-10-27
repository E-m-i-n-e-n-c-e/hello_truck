import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hello_truck_app/models/gst_details.dart';
import 'package:hello_truck_app/providers/auth_providers.dart';
import 'package:hello_truck_app/api/gst_details_api.dart' as gst_api;
import 'package:hello_truck_app/widgets/snackbars.dart';

class GstDetailsDialog extends ConsumerStatefulWidget {
  final GstDetails? existingDetails;
  final VoidCallback onSuccess;

  const GstDetailsDialog({
    super.key,
    this.existingDetails,
    required this.onSuccess,
  });

  @override
  ConsumerState<GstDetailsDialog> createState() => _GstDetailsDialogState();
}

class _GstDetailsDialogState extends ConsumerState<GstDetailsDialog> {
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

      if (widget.existingDetails != null) {
        await gst_api.updateGstDetails(
          api,
          id: widget.existingDetails!.id ?? '',
          gstNumber: _gstNumberController.text.trim(),
          businessName: _businessNameController.text.trim(),
          businessAddress: _businessAddressController.text.trim(),
        );
      } else {
        await gst_api.addGstDetails(
          api,
          gstNumber: _gstNumberController.text.trim(),
          businessName: _businessNameController.text.trim(),
          businessAddress: _businessAddressController.text.trim(),
        );
      }

      if (mounted) {
        widget.onSuccess();
        Navigator.pop(context);
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
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 12),
            const Text(
              'Would you like to reactivate these GST details?',
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                'GST Number: $gstNumber',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                ),
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
          Navigator.of(context).pop();
          SnackBars.success(context, 'GST details reactivated successfully');
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
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 500),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Icon(
                  Icons.receipt_long_rounded,
                  color: colorScheme.primary,
                  size: 24,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    widget.existingDetails == null ? 'Add GST Details' : 'Edit GST Details',
                    style: textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close_rounded),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Form
            Form(
              key: _formKey,
              child: Column(
                children: [
                  TextFormField(
                    controller: _gstNumberController,
                    decoration: const InputDecoration(
                      labelText: 'GST Number',
                      hintText: 'Enter GST number',
                      border: OutlineInputBorder(),
                    ),
                    enabled: !_isLoading,
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
                  TextFormField(
                    controller: _businessNameController,
                    decoration: const InputDecoration(
                      labelText: 'Business Name',
                      hintText: 'Enter business name',
                      border: OutlineInputBorder(),
                    ),
                    enabled: !_isLoading,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Business name is required';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _businessAddressController,
                    decoration: const InputDecoration(
                      labelText: 'Business Address',
                      hintText: 'Enter business address',
                      border: OutlineInputBorder(),
                    ),
                    maxLines: 3,
                    enabled: !_isLoading,
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
                      backgroundColor: colorScheme.primary,
                      foregroundColor: colorScheme.onPrimary,
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
                              valueColor: AlwaysStoppedAnimation<Color>(colorScheme.onPrimary),
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
    );
  }
}