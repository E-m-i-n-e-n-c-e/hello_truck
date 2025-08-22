import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hello_truck_app/models/saved_address.dart';
import 'package:hello_truck_app/api/address_api.dart';
import 'package:hello_truck_app/providers/auth_providers.dart';
import 'package:hello_truck_app/widgets/snackbars.dart';

class AddressConfirmationModal extends ConsumerStatefulWidget {
  final SavedAddress savedAddress;
  final Function(SavedAddress) onConfirm;

  const AddressConfirmationModal({
    super.key,
    required this.savedAddress,
    required this.onConfirm,
  });

  @override
  ConsumerState<AddressConfirmationModal> createState() => _AddressConfirmationModalState();
}

class _AddressConfirmationModalState extends ConsumerState<AddressConfirmationModal> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _addressDetailsController;
  late final TextEditingController _contactNameController;
  late final TextEditingController _contactPhoneController;
  late final TextEditingController _noteToDriverController;
  late final TextEditingController _addressNameController;

    bool _shouldSave = false;
    bool _isSaveMode = false;
    bool _isSaving = false;
    bool _setAsDefaultWhenSaving = false;

  @override
  void initState() {
    super.initState();
    _addressDetailsController = TextEditingController(text: widget.savedAddress.address.addressDetails ?? '');
    _contactNameController = TextEditingController(text: widget.savedAddress.contactName);
    _contactPhoneController = TextEditingController(text: widget.savedAddress.contactPhone);
    _noteToDriverController = TextEditingController(text: widget.savedAddress.noteToDriver ?? '');
    _addressNameController = TextEditingController();
  }

  @override
  void dispose() {
    _addressDetailsController.dispose();
    _contactNameController.dispose();
    _contactPhoneController.dispose();
    _noteToDriverController.dispose();
    _addressNameController.dispose();
    super.dispose();
  }


  Widget _buildReactiveConfirmButton(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return ListenableBuilder(
      listenable: Listenable.merge([
        _contactNameController,
        _contactPhoneController,
      ]),
      builder: (context, _) {
        final enabled = _canConfirm();
        return SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: enabled ? _confirmAddress : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: enabled ? Theme.of(context).colorScheme.primary : Colors.grey.shade200,
              foregroundColor: enabled ? Colors.white : Colors.grey.shade500,
              padding: const EdgeInsets.symmetric(vertical: 18),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              elevation: 0,
            ),
            child: Text(
              'Confirm',
              style: textTheme.titleMedium?.copyWith(
                color: enabled ? Colors.white : Colors.grey.shade500,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    // If in save mode, show the save location modal
    if (_isSaveMode) {
      return _buildSaveMode(context);
    }

    // Normal recipient details modal
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
        child: Column(
        mainAxisSize: MainAxisSize.min,
          children: [
            // Header with back button and title
          Container(
            padding: const EdgeInsets.fromLTRB(12, 12, 16, 0),
            child: Row(
              children: [
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: Icon(
                    Icons.arrow_back,
                    color: Colors.black.withValues(alpha: 0.8),
                  ),
                ),
                const SizedBox(width: 4),
                Text(
                  'Recipient Details',
                  style: textTheme.titleLarge?.copyWith(
                    color: Colors.black.withValues(alpha: 0.85),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            ),

          Flexible(
              child: Form(
                key: _formKey,
                child: SingleChildScrollView(
                  padding:  EdgeInsets.only(left: 16, right: 16, top: 12, bottom:16 + MediaQuery.of(context).viewInsets.bottom),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                    // Address Display (Read-only)
                    _buildAddressDisplay(context),

                    const SizedBox(height: 16),

                      // Address Form Fields
                      _buildAddressForm(context),

                    const SizedBox(height: 16),

                    // Save this place checkbox
                    _buildSaveCheckbox(context),

                    const SizedBox(height: 16),

            // Confirm Button
                    _buildReactiveConfirmButton(context),
            // Add bottom padding for safe area
            SizedBox(height: MediaQuery.of(context).padding.bottom),
          ],
        ),
              ),
            ),
          ),
        ],
      ),
    );
  }


  Widget _buildSaveMode(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Flexible(
            child: Form(
              key: _formKey,
              child: SingleChildScrollView(
                padding:  EdgeInsets.only(left: 16, right: 16, top: 16, bottom:16 + MediaQuery.of(context).viewInsets.bottom),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Question text
                    Text(
                      'What do you want to save this address as?',
                      style: textTheme.bodyLarge?.copyWith(
                        color: Colors.black,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Name input field
                    _buildTextField(
                      controller: _addressNameController,
                      label: 'Name',
                      hint: 'e.g. Home, Office, Gym',
                      autoFocus: true,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Address name is required';
                        }
                        return null;
                      },
                    ),

                    const SizedBox(height: 16),

                    // Set as default checkbox (matches styling used elsewhere)
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            'Set as default',
                            style: textTheme.bodyMedium?.copyWith(
                              color: Colors.black87,
                            ),
                          ),
                        ),
                        Transform.scale(
                          scale: 1.2,
                          child: Checkbox(
                            value: _setAsDefaultWhenSaving,
                            onChanged: (value) {
                              setState(() {
                                _setAsDefaultWhenSaving = value ?? false;
                              });
                            },
                            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(4),
                            ),
                            side: BorderSide(
                              color: Colors.grey.shade400,
                              width: 1.5,
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 24),

                    // Save/Skip buttons
                    Row(
                      children: [
                        // Skip Button
                        Expanded(
                          child: OutlinedButton(
                            onPressed: _isSaving ? null : _skipSave,
                            style: OutlinedButton.styleFrom(
                              side: BorderSide(color: Colors.grey.shade400),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              padding: const EdgeInsets.symmetric(vertical: 16),
                            ),
                            child: Text(
                              'Skip',
                              style: textTheme.titleMedium?.copyWith(
                                color: Colors.grey.shade700,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        // Save Button
                        Expanded(
                          child: ElevatedButton(
                            onPressed: _isSaving ? null : _saveAddress,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF22AAAE),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              elevation: 0,
                            ),
                            child: _isSaving
                                ? const SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                    ),
                                  )
                                : Text(
                                    'Save',
                                    style: textTheme.titleMedium?.copyWith(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                          ),
                        ),
                      ],
                    ),

                    // Add bottom padding for safe area
                    SizedBox(height: MediaQuery.of(context).padding.bottom),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }


  Widget _buildAddressDisplay(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: Colors.grey.shade300,
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.location_on,
                color: Theme.of(context).colorScheme.primary,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'Selected Address',
                style: textTheme.labelMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            widget.savedAddress.address.formattedAddress,
            style: textTheme.bodyMedium?.copyWith(
              color: Colors.black87,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAddressForm(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Address Details
        _buildTextField(
          controller: _addressDetailsController,
          label: 'Address details',
          hint: 'Apartment, floor, landmark, etc.',
          maxLines: 1,
          onChanged: (value) => setState(() {}),
        ),

        const SizedBox(height: 16),

        // Contact Name
        _buildTextField(
          controller: _contactNameController,
          label: 'Contact name',
          hint: 'Name',
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Contact name is required';
            }
            return null;
          },
        ),

        const SizedBox(height: 16),

        // Contact Phone
        _buildTextField(
          controller: _contactPhoneController,
          label: 'Contact number',
          hint: 'Phone number',
          keyboardType: TextInputType.phone,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(10)],
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Contact number is required';
            }
            if (value.trim().length < 10) {
              return 'Please enter a valid phone number';
            }
            return null;
          },
        ),

        const SizedBox(height: 16),

        // Note to Driver
        _buildTextField(
          controller: _noteToDriverController,
          label: 'Note to driver',
          hint: 'Add a note to driver',
          maxLines: 2,
          onChanged: (value) => setState(() {}),
        ),
      ],
    );
  }



  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    int maxLines = 1,
    TextInputType? keyboardType,
    List<TextInputFormatter>? inputFormatters,
    String? Function(String?)? validator,
    Function(String)? onChanged,
    bool autoFocus = false,
  }) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              label,
              style: textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w500,
                color: Colors.black87,
              ),
            ),
            if (validator != null)
              Text(
                ' *',
                style: textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w500,
                  color: Colors.red,
                ),
              ),
          ],
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurface.withValues(alpha: 0.5),
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(
                color: colorScheme.outline.withValues(alpha: 0.3),
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(
                color: colorScheme.outline.withValues(alpha: 0.3),
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(
                color: colorScheme.secondary,
                width: 2,
              ),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(
                color: colorScheme.error,
              ),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(
                color: colorScheme.error,
                width: 2,
              ),
            ),
            filled: true,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 16,
            ),
          ),
          style: textTheme.bodyMedium?.copyWith(
            color: Colors.black87,
          ),
          autofocus: autoFocus,
          maxLines: maxLines,
          keyboardType: keyboardType,
          inputFormatters: inputFormatters,
          validator: validator,
          onChanged: onChanged,
        ),
      ],
    );
  }

  bool _canConfirm() {
    return _contactNameController.text.trim().isNotEmpty &&
           _contactPhoneController.text.trim().isNotEmpty &&
           _contactPhoneController.text.trim().length >= 10;
  }

  void _confirmAddress() {
    if (_formKey.currentState!.validate()) {
      // If user wants to save, switch to save mode
      if (_shouldSave) {
        setState(() {
          _isSaveMode = true;
        });
      } else {
        // If not saving, just confirm with current address
        _confirmWithCurrentAddress();
      }
    }
  }

  void _confirmWithCurrentAddress() {
    // Create updated address with new details (coordinates stay the same)
    final updatedAddress = Address(
      formattedAddress: widget.savedAddress.address.formattedAddress,
      addressDetails: _addressDetailsController.text.trim().isNotEmpty
          ? _addressDetailsController.text.trim()
          : null,
      latitude: widget.savedAddress.address.latitude,
      longitude: widget.savedAddress.address.longitude,
    );

    // Create updated saved address
    final updatedSavedAddress = SavedAddress(
      id: widget.savedAddress.id,
      name: widget.savedAddress.name,
      address: updatedAddress,
      contactName: _contactNameController.text.trim(),
      contactPhone: _contactPhoneController.text.trim(),
      noteToDriver: _noteToDriverController.text.trim().isNotEmpty
          ? _noteToDriverController.text.trim()
          : null,
      isDefault: widget.savedAddress.isDefault,
      createdAt: widget.savedAddress.createdAt,
      updatedAt: DateTime.now(),
    );

    widget.onConfirm(updatedSavedAddress);
  }

  Widget _buildSaveCheckbox(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Row(
      children: [
        Expanded(
          child: Text(
            'Save this place',
            style: textTheme.bodyMedium?.copyWith(
              color: Colors.black87,
            ),
          ),
        ),
        Transform.scale(
          scale: 1.2,
          child: Checkbox(
            value: _shouldSave,
            onChanged: (value) {
              setState(() {
                _shouldSave = value ?? false;
              });
            },
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(4),
            ),
            side: BorderSide(
              color: Colors.grey.shade400,
              width: 1.5,
            ),
          ),
        ),
      ],
    );
  }

  void _skipSave() {
    // Just confirm with current address without saving
    _confirmWithCurrentAddress();
  }

  Future<void> _saveAddress() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isSaving = true;
      });

      try {
        final api = await ref.read(apiProvider.future);

        // Create the address to save with current form data
        final addressToSave = Address(
          formattedAddress: widget.savedAddress.address.formattedAddress,
          addressDetails: _addressDetailsController.text.trim().isNotEmpty
              ? _addressDetailsController.text.trim()
              : null,
          latitude: widget.savedAddress.address.latitude,
          longitude: widget.savedAddress.address.longitude,
        );

        // Save the address
        final savedAddress = await createSavedAddress(
          api,
          name: _addressNameController.text.trim(),
          address: addressToSave,
          contactName: _contactNameController.text.trim(),
          contactPhone: _contactPhoneController.text.trim(),
          noteToDriver: _noteToDriverController.text.trim().isNotEmpty
              ? _noteToDriverController.text.trim()
              : null,
          isDefault: _setAsDefaultWhenSaving,
        );

        // Confirm with the saved address (which now has the new name)
        widget.onConfirm(savedAddress);
      } catch (e) {
        if (mounted) {
          SnackBars.error(context, 'Error saving address: $e');
        }
      } finally {
        if (mounted) {
          setState(() {
            _isSaving = false;
          });
        }
      }
    }
  }
}
