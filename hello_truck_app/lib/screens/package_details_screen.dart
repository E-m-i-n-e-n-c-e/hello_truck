import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:hello_truck_app/screens/map_screen.dart';

class PackageDetailsScreen extends ConsumerStatefulWidget {
  final VoidCallback? onProceedToMap;

  const PackageDetailsScreen({super.key, this.onProceedToMap});

  @override
  ConsumerState<PackageDetailsScreen> createState() => _PackageDetailsScreenState();
}

class _PackageDetailsScreenState extends ConsumerState<PackageDetailsScreen> {
  final _formKey = GlobalKey<FormState>();
  final _weightController = TextEditingController();
  final _lengthController = TextEditingController();
  final _widthController = TextEditingController();
  final _heightController = TextEditingController();
  final _descriptionController = TextEditingController();

  bool _isAgriculturalSelected = false;
  bool _isNonAgriculturalSelected = false;
  String _loadingPreference = '';
  File? _packageImage;
  File? _gstBillImage;
  final ImagePicker _picker = ImagePicker();

  @override
  void dispose() {
    _weightController.dispose();
    _lengthController.dispose();
    _widthController.dispose();
    _heightController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _pickImage(bool isGstBill) async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      setState(() {
        if (isGstBill) {
          _gstBillImage = File(image.path);
        } else {
          _packageImage = File(image.path);
        }
      });
    }
  }

  bool _isFormValid() {
    if (!_isAgriculturalSelected && !_isNonAgriculturalSelected) {
      return false;
    }

    if (_loadingPreference.isEmpty) {
      return false;
    }

    if (_isAgriculturalSelected && _weightController.text.trim().isEmpty) {
      return false;
    }

    if (_isNonAgriculturalSelected) {
      bool hasWeight = _weightController.text.trim().isNotEmpty;
      bool hasDimensions = _lengthController.text.trim().isNotEmpty &&
          _widthController.text.trim().isNotEmpty &&
          _heightController.text.trim().isNotEmpty;
      bool hasOthers = _packageImage != null || _descriptionController.text.trim().isNotEmpty;

      if (!hasWeight && !hasDimensions && !hasOthers) {
        return false;
      }

      if (_gstBillImage == null) {
        return false;
      }
    }

    return true;
  }

  void _proceedToMap() {
    if (_isFormValid()) {
      // Use the callback if provided, otherwise navigate directly
      if (widget.onProceedToMap != null) {
        widget.onProceedToMap!();
      } else {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => const MapScreen(),
          ),
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please fill all required fields'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        title: const Text('Package Details'),
        backgroundColor: colorScheme.primary,
        foregroundColor: colorScheme.onPrimary,
        elevation: 0,
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Product Type Selection
              Text(
                'Product Type Selection',
                style: textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: colorScheme.primary,
                ),
              ),
              const SizedBox(height: 16),

              _buildProductTypeCheckbox(
                'Agricultural Products',
                _isAgriculturalSelected,
                (value) => setState(() => _isAgriculturalSelected = value ?? false),
                colorScheme,
              ),
              const SizedBox(height: 8),

              _buildProductTypeCheckbox(
                'Non-Agricultural Products',
                _isNonAgriculturalSelected,
                (value) => setState(() => _isNonAgriculturalSelected = value ?? false),
                colorScheme,
              ),

              const SizedBox(height: 24),

              // Agricultural Products Section
              if (_isAgriculturalSelected) ...[
                _buildSectionHeader('Agricultural Products', colorScheme, textTheme),
                const SizedBox(height: 16),

                _buildTextField(
                  controller: _weightController,
                  label: 'Approximate Weight (KG)',
                  isRequired: true,
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 16),

                _buildLoadingPreferenceSection(colorScheme, textTheme),
                const SizedBox(height: 24),
              ],

              // Non-Agricultural Products Section
              if (_isNonAgriculturalSelected) ...[
                _buildSectionHeader('Non-Agricultural Products', colorScheme, textTheme),
                const SizedBox(height: 16),

                Text(
                  'Provide at least one of the following:',
                  style: textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurface.withValues(alpha: 0.7),
                  ),
                ),
                const SizedBox(height: 12),

                _buildTextField(
                  controller: _weightController,
                  label: 'Product Weight (KG)',
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 16),

                Text(
                  'Product Dimensions (CM)',
                  style: textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),

                Row(
                  children: [
                    Expanded(
                      child: _buildTextField(
                        controller: _lengthController,
                        label: 'Length',
                        keyboardType: TextInputType.number,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildTextField(
                        controller: _widthController,
                        label: 'Width',
                        keyboardType: TextInputType.number,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildTextField(
                        controller: _heightController,
                        label: 'Height',
                        keyboardType: TextInputType.number,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                Text(
                  'Others',
                  style: textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),

                _buildImageUploadButton(
                  'Upload Package Image 📷',
                  _packageImage,
                  () => _pickImage(false),
                  colorScheme,
                ),
                const SizedBox(height: 12),

                _buildTextField(
                  controller: _descriptionController,
                  label: 'Description of the package 📄',
                  maxLines: 3,
                ),
                const SizedBox(height: 16),

                _buildLoadingPreferenceSection(colorScheme, textTheme),
                const SizedBox(height: 16),

                Text(
                  'GST Bill Image (Mandatory)',
                  style: textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: Colors.red,
                  ),
                ),
                const SizedBox(height: 8),

                _buildImageUploadButton(
                  'Upload GST Bill 📷',
                  _gstBillImage,
                  () => _pickImage(true),
                  colorScheme,
                  isRequired: true,
                ),
                const SizedBox(height: 24),
              ],

              // Proceed Button
              if (_isAgriculturalSelected || _isNonAgriculturalSelected) ...[
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _proceedToMap,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: colorScheme.primary,
                      foregroundColor: colorScheme.onPrimary,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'Proceed to Map',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProductTypeCheckbox(
    String title,
    bool value,
    ValueChanged<bool?> onChanged,
    ColorScheme colorScheme,
  ) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(
          color: value ? colorScheme.primary : colorScheme.outline,
        ),
        borderRadius: BorderRadius.circular(12),
        color: value ? colorScheme.primary.withValues(alpha: 0.05) : null,
      ),
      child: CheckboxListTile(
        title: Text(
          title,
          style: TextStyle(
            fontWeight: value ? FontWeight.w600 : FontWeight.normal,
            color: value ? colorScheme.primary : null,
          ),
        ),
        value: value,
        onChanged: onChanged,
        activeColor: colorScheme.primary,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, ColorScheme colorScheme, TextTheme textTheme) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.primary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        title,
        style: textTheme.titleLarge?.copyWith(
          fontWeight: FontWeight.bold,
          color: colorScheme.primary,
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    bool isRequired = false,
    TextInputType? keyboardType,
    int maxLines = 1,
  }) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: isRequired ? '$label *' : label,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      keyboardType: keyboardType,
      maxLines: maxLines,
    );
  }

  Widget _buildLoadingPreferenceSection(ColorScheme colorScheme, TextTheme textTheme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Loading Preference',
          style: textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),

        _buildRadioOption('Self-Loading', colorScheme),
        _buildRadioOption('Require Loadman at Loading Point', colorScheme),
        _buildRadioOption('Require Loadman at Unloading Point', colorScheme),
      ],
    );
  }

  Widget _buildRadioOption(String title, ColorScheme colorScheme) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        border: Border.all(
          color: _loadingPreference == title ? colorScheme.primary : colorScheme.outline,
        ),
        borderRadius: BorderRadius.circular(12),
        color: _loadingPreference == title ? colorScheme.primary.withValues(alpha: 0.05) : null,
      ),
      child: RadioListTile<String>(
        title: Text(
          title,
          style: TextStyle(
            fontWeight: _loadingPreference == title ? FontWeight.w600 : FontWeight.normal,
            color: _loadingPreference == title ? colorScheme.primary : null,
          ),
        ),
        value: title,
        groupValue: _loadingPreference,
        onChanged: (value) => setState(() => _loadingPreference = value ?? ''),
        activeColor: colorScheme.primary,
      ),
    );
  }

  Widget _buildImageUploadButton(
    String title,
    File? image,
    VoidCallback onTap,
    ColorScheme colorScheme,
    {bool isRequired = false}
  ) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        border: Border.all(
          color: image != null ? colorScheme.primary : colorScheme.outline,
          width: image != null ? 2 : 1,
        ),
        borderRadius: BorderRadius.circular(12),
        color: image != null ? colorScheme.primary.withValues(alpha: 0.05) : null,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Icon(
                  image != null ? Icons.check_circle : Icons.cloud_upload,
                  size: 40,
                  color: image != null ? colorScheme.primary : colorScheme.onSurface.withValues(alpha: 0.6),
                ),
                const SizedBox(height: 8),
                Text(
                  image != null ? 'Image Selected' : (isRequired ? '$title *' : title),
                  style: TextStyle(
                    fontWeight: image != null ? FontWeight.w600 : FontWeight.normal,
                    color: image != null ? colorScheme.primary : colorScheme.onSurface.withValues(alpha: 0.7),
                  ),
                  textAlign: TextAlign.center,
                ),
                if (image != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    'Tap to change',
                    style: TextStyle(
                      fontSize: 12,
                      color: colorScheme.onSurface.withValues(alpha: 0.5),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}