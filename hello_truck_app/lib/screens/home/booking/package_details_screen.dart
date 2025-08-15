import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hello_truck_app/models/saved_address.dart';
import 'package:hello_truck_app/screens/home/booking/estimate_screen.dart';

class PackageDetailsScreen extends ConsumerStatefulWidget {
  final SavedAddress pickupAddress;
  final SavedAddress dropAddress;

  const PackageDetailsScreen({
    super.key,
    required this.pickupAddress,
    required this.dropAddress,
  });

  @override
  ConsumerState<PackageDetailsScreen> createState() => _PackageDetailsScreenState();
}

class _PackageDetailsScreenState extends ConsumerState<PackageDetailsScreen> {
  final _formKey = GlobalKey<FormState>();

  // Package type
  bool _isCommercialUse = false;

  // Product type
  bool _isAgriculturalProduct = false;
  bool _isNonAgriculturalProduct = false;

  // Agricultural product fields
  final _productNameController = TextEditingController();
  final _weightController = TextEditingController();
  String _weightUnit = 'KG';

  // Non-agricultural product fields
  final _avgWeightController = TextEditingController();
  final _bundleWeightController = TextEditingController();
  final _lengthController = TextEditingController();
  final _widthController = TextEditingController();
  final _heightController = TextEditingController();
  String _dimensionUnit = 'CM';
  final _numberOfProductsController = TextEditingController();
  final _descriptionController = TextEditingController();

  @override
  void dispose() {
    _productNameController.dispose();
    _weightController.dispose();
    _avgWeightController.dispose();
    _bundleWeightController.dispose();
    _lengthController.dispose();
    _widthController.dispose();
    _heightController.dispose();
    _numberOfProductsController.dispose();
    _descriptionController.dispose();
    super.dispose();
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
          'Package Details',
          style: textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
            color: colorScheme.onSurface,
          ),
        ),
        centerTitle: true,
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Package Type Section
              _buildSectionCard(
                title: 'Package Type',
                child: Column(
                  children: [
                    RadioListTile<bool>(
                      title: const Text('Personal Use'),
                      value: false,
                      groupValue: _isCommercialUse,
                      onChanged: (value) {
                        setState(() {
                          _isCommercialUse = value!;
                        });
                      },
                      activeColor: colorScheme.primary,
                    ),
                    RadioListTile<bool>(
                      title: const Text('Commercial Use'),
                      subtitle: const Text('GST bill mandatory'),
                      value: true,
                      groupValue: _isCommercialUse,
                      onChanged: (value) {
                        setState(() {
                          _isCommercialUse = value!;
                        });
                      },
                      activeColor: colorScheme.primary,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // Product Type Section
              _buildSectionCard(
                title: 'Product Type Selection',
                child: Column(
                  children: [
                    CheckboxListTile(
                      title: const Text('Agricultural Products'),
                      value: _isAgriculturalProduct,
                      onChanged: (value) {
                        setState(() {
                          _isAgriculturalProduct = value!;
                          if (value) {
                            _isNonAgriculturalProduct = false;
                          }
                        });
                      },
                      activeColor: colorScheme.primary,
                    ),
                    CheckboxListTile(
                      title: const Text('Non-Agricultural Products'),
                      value: _isNonAgriculturalProduct,
                      onChanged: (value) {
                        setState(() {
                          _isNonAgriculturalProduct = value!;
                          if (value) {
                            _isAgriculturalProduct = false;
                          }
                        });
                      },
                      activeColor: colorScheme.primary,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // Agricultural Products Details
              if (_isAgriculturalProduct) ...[
                _buildSectionCard(
                  title: 'Agricultural Product Details',
                  child: Column(
                    children: [
                      TextFormField(
                        controller: _productNameController,
                        decoration: InputDecoration(
                          labelText: 'Product Name *',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Product name is required';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            flex: 2,
                            child: TextFormField(
                              controller: _weightController,
                              decoration: InputDecoration(
                                labelText: 'Approximate Weight *',
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              keyboardType: TextInputType.number,
                              validator: (value) {
                                if (value == null || value.trim().isEmpty) {
                                  return 'Weight is required';
                                }
                                return null;
                              },
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: DropdownButtonFormField<String>(
                              value: _weightUnit,
                              decoration: InputDecoration(
                                labelText: 'Unit',
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              items: ['KG', 'Quintal'].map((unit) {
                                return DropdownMenuItem(
                                  value: unit,
                                  child: Text(unit),
                                );
                              }).toList(),
                              onChanged: (value) {
                                setState(() {
                                  _weightUnit = value!;
                                });
                              },
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
              ],

              // Non-Agricultural Products Details
              if (_isNonAgriculturalProduct) ...[
                _buildSectionCard(
                  title: 'Non-Agricultural Product Details',
                  child: Column(
                    children: [
                      // Weight Section
                      Text(
                        'Weight Information',
                        style: textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: colorScheme.primary,
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _avgWeightController,
                        decoration: InputDecoration(
                          labelText: 'Average Weight of Shipment (KG) *',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        keyboardType: TextInputType.number,
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Average weight is required';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _bundleWeightController,
                        decoration: InputDecoration(
                          labelText: 'Weight of Each Bundle (KG)',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        keyboardType: TextInputType.number,
                      ),
                      const SizedBox(height: 20),

                      // Dimensions Section
                      Text(
                        'Product Dimensions (Optional)',
                        style: textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: colorScheme.primary,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _lengthController,
                              decoration: InputDecoration(
                                labelText: 'Length',
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              keyboardType: TextInputType.number,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: TextFormField(
                              controller: _widthController,
                              decoration: InputDecoration(
                                labelText: 'Width',
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              keyboardType: TextInputType.number,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: TextFormField(
                              controller: _heightController,
                              decoration: InputDecoration(
                                labelText: 'Height',
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              keyboardType: TextInputType.number,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: DropdownButtonFormField<String>(
                              value: _dimensionUnit,
                              decoration: InputDecoration(
                                labelText: 'Unit',
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              items: ['CM', 'IN'].map((unit) {
                                return DropdownMenuItem(
                                  value: unit,
                                  child: Text(unit),
                                );
                              }).toList(),
                              onChanged: (value) {
                                setState(() {
                                  _dimensionUnit = value!;
                                });
                              },
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: TextFormField(
                              controller: _numberOfProductsController,
                              decoration: InputDecoration(
                                labelText: 'Number of Products',
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              keyboardType: TextInputType.number,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Description
                      TextFormField(
                        controller: _descriptionController,
                        decoration: InputDecoration(
                          labelText: 'Package Description',
                          hintText: 'Describe your package...',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        maxLines: 3,
                      ),
                      const SizedBox(height: 16),

                      // Upload buttons
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () {
                                // TODO: Implement image upload
                              },
                              icon: const Icon(Icons.camera_alt),
                              label: const Text('Upload Image'),
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
              ],

              // Document Upload Section
              if (_isCommercialUse) ...[
                _buildSectionCard(
                  title: 'Required Documents',
                  child: Column(
                    children: [
                      OutlinedButton.icon(
                        onPressed: () {
                          // TODO: Implement GST bill upload
                        },
                        icon: const Icon(Icons.upload_file),
                        label: const Text('Upload GST Bill (Mandatory)'),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
              ],

              // Transportation Documents
              _buildSectionCard(
                title: 'Transportation Documents (Optional)',
                child: Column(
                  children: [
                    OutlinedButton.icon(
                      onPressed: () {
                        // TODO: Implement document upload
                      },
                      icon: const Icon(Icons.attach_file),
                      label: const Text('Upload Documents'),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Support for multiple document upload',
                      style: textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurface.withValues(alpha: 0.6),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 32),

              // Continue Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _canProceed() ? _proceedToEstimate : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _canProceed()
                      ? colorScheme.primary
                      : colorScheme.onSurface.withValues(alpha: 0.3),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: _canProceed() ? 8 : 2,
                  ),
                  child: Text(
                    'Proceed to Estimate',
                    style: textTheme.titleMedium?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionCard({required String title, required Widget child}) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Container(
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
              title,
              style: textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 16),
            child,
          ],
        ),
      ),
    );
  }

  bool _canProceed() {
    if (!_isAgriculturalProduct && !_isNonAgriculturalProduct) {
      return false;
    }

    if (_isAgriculturalProduct) {
      return _productNameController.text.trim().isNotEmpty &&
             _weightController.text.trim().isNotEmpty;
    }

    if (_isNonAgriculturalProduct) {
      return _avgWeightController.text.trim().isNotEmpty;
    }

    return false;
  }

  void _proceedToEstimate() {
    if (_formKey.currentState!.validate()) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => EstimateScreen(
            pickupAddress: widget.pickupAddress,
            dropAddress: widget.dropAddress,
            packageDetails: _buildPackageDetails(),
          ),
        ),
      );
    }
  }

  Map<String, dynamic> _buildPackageDetails() {
    return {
      'isCommercialUse': _isCommercialUse,
      'isAgriculturalProduct': _isAgriculturalProduct,
      'isNonAgriculturalProduct': _isNonAgriculturalProduct,
      if (_isAgriculturalProduct) ...{
        'productName': _productNameController.text.trim(),
        'weight': _weightController.text.trim(),
        'weightUnit': _weightUnit,
      },
      if (_isNonAgriculturalProduct) ...{
        'avgWeight': _avgWeightController.text.trim(),
        'bundleWeight': _bundleWeightController.text.trim(),
        'length': _lengthController.text.trim(),
        'width': _widthController.text.trim(),
        'height': _heightController.text.trim(),
        'dimensionUnit': _dimensionUnit,
        'numberOfProducts': _numberOfProductsController.text.trim(),
        'description': _descriptionController.text.trim(),
      },
    };
  }
}