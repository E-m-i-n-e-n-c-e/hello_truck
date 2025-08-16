import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hello_truck_app/api/address_api.dart';
import 'package:hello_truck_app/models/saved_address.dart';
import 'package:hello_truck_app/providers/auth_providers.dart';
import 'package:hello_truck_app/screens/home/booking/widgets/map_selection_page.dart';

enum AddOrEditAddressMode { add, edit }

class AddOrEditAddressPage extends ConsumerStatefulWidget {
  final AddOrEditAddressMode mode;
  final Address? initialAddress; // for add
  final SavedAddress? initialSavedAddress; // for edit

  const AddOrEditAddressPage.add({
    super.key,
    required Address this.initialAddress,
  })  : mode = AddOrEditAddressMode.add,
        initialSavedAddress = null;

  const AddOrEditAddressPage.edit({
    super.key,
    required SavedAddress savedAddress,
  })  : mode = AddOrEditAddressMode.edit,
        initialSavedAddress = savedAddress,
        initialAddress = null;

  @override
  ConsumerState<AddOrEditAddressPage> createState() => _AddOrEditAddressPageState();
}

class _AddOrEditAddressPageState extends ConsumerState<AddOrEditAddressPage> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _formattedAddressController = TextEditingController();
  final TextEditingController _addressDetailsController = TextEditingController();
  final TextEditingController _contactNameController = TextEditingController();
  final TextEditingController _contactPhoneController = TextEditingController();
  final TextEditingController _noteToDriverController = TextEditingController();

  Address? _selectedAddress;
  bool _isSaving = false;
  bool _setAsDefault = false;

  @override
  void initState() {
    super.initState();
    if (widget.mode == AddOrEditAddressMode.add) {
      _selectedAddress = widget.initialAddress;
      _formattedAddressController.text = widget.initialAddress?.formattedAddress ?? '';
    } else {
      final saved = widget.initialSavedAddress!;
      _nameController.text = saved.name;
      _selectedAddress = saved.address;
      _formattedAddressController.text = saved.address.formattedAddress;
      _addressDetailsController.text = saved.address.addressDetails ?? '';
      _contactNameController.text = saved.contactName ?? '';
      _contactPhoneController.text = saved.contactPhone ?? '';
      _noteToDriverController.text = saved.noteToDriver ?? '';
      _setAsDefault = saved.isDefault;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _formattedAddressController.dispose();
    _addressDetailsController.dispose();
    _contactNameController.dispose();
    _contactPhoneController.dispose();
    _noteToDriverController.dispose();
    super.dispose();
  }

  Future<void> _openMapForAddress() async {
    final result = await showModalBottomSheet<Address>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (context) => SizedBox(
        height: MediaQuery.of(context).size.height * 0.9,
        child: MapSelectionPage(
          mode: MapSelectionMode.direct,
        ),
      ),
    );

    if (result != null) {
      setState(() {
        _selectedAddress = result;
        _formattedAddressController.text = result.formattedAddress;
      });
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedAddress == null) return;

    setState(() {
      _isSaving = true;
    });

    try {
      final api = await ref.read(apiProvider.future);
      final addressPayload = Address(
        formattedAddress: _formattedAddressController.text.trim(),
        addressDetails: _addressDetailsController.text.trim().isNotEmpty
            ? _addressDetailsController.text.trim()
            : null,
        latitude: _selectedAddress!.latitude,
        longitude: _selectedAddress!.longitude,
      );

      SavedAddress saved;
      if (widget.mode == AddOrEditAddressMode.add) {
        saved = await createSavedAddress(
          api,
          name: _nameController.text.trim(),
          address: addressPayload,
          contactName: _contactNameController.text.trim().isNotEmpty
              ? _contactNameController.text.trim()
              : null,
          contactPhone: _contactPhoneController.text.trim().isNotEmpty
              ? _contactPhoneController.text.trim()
              : null,
          noteToDriver: _noteToDriverController.text.trim().isNotEmpty
              ? _noteToDriverController.text.trim()
              : null,
          isDefault: _setAsDefault,
        );
      } else {
        saved = await updateSavedAddress(
          api,
          widget.initialSavedAddress!.id,
          name: _nameController.text.trim(),
          address: addressPayload,
          contactName: _contactNameController.text.trim().isNotEmpty
              ? _contactNameController.text.trim()
              : null,
          contactPhone: _contactPhoneController.text.trim().isNotEmpty
              ? _contactPhoneController.text.trim()
              : null,
          noteToDriver: _noteToDriverController.text.trim().isNotEmpty
              ? _noteToDriverController.text.trim()
              : null,
          isDefault: _setAsDefault,
        );
      }

      if (mounted) {
        Navigator.pop(context, saved);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving address: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final isEdit = widget.mode == AddOrEditAddressMode.edit;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.black.withValues(alpha: 0.8)),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          isEdit ? 'Edit Saved Place' : 'Add New Place',
          style: textTheme.titleLarge?.copyWith(
            color: Colors.black.withValues(alpha: 0.85),
            fontWeight: FontWeight.w500,
          ),
        ),
        centerTitle: false,
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildTextField(
                  controller: _nameController,
                  label: 'Name',
                  hint: 'e.g. Home, Office, Gym',
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Name is required';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: _openMapForAddress,
                  child: AbsorbPointer(
                    child: _buildTextField(
                      controller: _formattedAddressController,
                      label: 'Address',
                      hint: 'Tap to pick on map',
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Address is required';
                        }
                        return null;
                      },
                      maxLines: 2,
                      suffixIcon: const Icon(Icons.chevron_right_rounded, size: 18, color: Colors.grey),
                      readOnly: true,
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                _buildTextField(
                  controller: _addressDetailsController,
                  label: 'Address details',
                  hint: 'e.g. Floor, unit number',
                  maxLines: 2,
                ),
                const SizedBox(height: 16),

                _buildTextField(
                  controller: _contactNameController,
                  label: 'Contact name',
                  hint: 'e.g. John Doe',
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Contact name is required';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                _buildTextField(
                  controller: _contactPhoneController,
                  label: 'Contact number',
                  hint: 'e.g. 1234567890',
                  keyboardType: TextInputType.phone,
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'[0-9]')),
                    LengthLimitingTextInputFormatter(10),
                  ],
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Contact number is required';
                    }
                    if (!RegExp(r'^[0-9]{10}$').hasMatch(value.trim())) {
                      return 'Please enter a valid 10 digit number';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                _buildTextField(
                  controller: _noteToDriverController,
                  label: 'Note to driver',
                  hint: 'e.g. Meet me at the lobby',
                  maxLines: 2,
                ),
                const SizedBox(height: 16),

                // Set as default checkbox (styled like confirmation modal)
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
                        value: _setAsDefault,
                        onChanged: (value) {
                          setState(() {
                            _setAsDefault = value ?? false;
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

                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isSaving ? null : _submit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF22AAAE),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
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
                            isEdit ? 'Update Address' : 'Save Address',
                            style: textTheme.titleMedium?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                  ),
                ),
                SizedBox(height: MediaQuery.of(context).padding.bottom),
              ],
            ),
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
    List<TextInputFormatter>? inputFormatters,
    TextInputType? keyboardType,
    int maxLines = 1,
    Widget? suffixIcon,
    bool readOnly = false,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              label,
              style: textTheme.bodySmall?.copyWith(
                color: Colors.black.withValues(alpha: 0.7),
                fontWeight: FontWeight.w600,
              ),
            ),
            if (validator != null)
              Text(
                ' *',
                style: textTheme.bodySmall?.copyWith(
                  color: Colors.red,
                  fontWeight: FontWeight.w600,
                ),
              ),
          ],
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          validator: validator,
          keyboardType: keyboardType,
          maxLines: maxLines,
          readOnly: readOnly,
          inputFormatters: inputFormatters,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: textTheme.bodyMedium?.copyWith(
              color: Colors.black.withValues(alpha: 0.4),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            filled: true,
            fillColor: Colors.white,
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: colorScheme.outline.withValues(alpha: 0.3)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: Color(0xFF22AAAE), width: 1.5),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: Colors.red),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: Colors.red),
            ),
            suffixIcon: suffixIcon,
          ),
        ),
      ],
    );
  }
}


