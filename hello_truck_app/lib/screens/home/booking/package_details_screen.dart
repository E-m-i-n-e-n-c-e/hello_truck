import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hello_truck_app/models/enums/package_enums.dart';
import 'package:hello_truck_app/widgets/snackbars.dart';
import 'package:file_picker/file_picker.dart';
import 'package:hello_truck_app/models/saved_address.dart';
import 'package:hello_truck_app/models/package.dart';
import 'package:hello_truck_app/screens/home/booking/estimate_screen.dart';
import 'package:hello_truck_app/widgets/document_upload_card.dart';
import 'package:hello_truck_app/providers/auth_providers.dart';

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
  String _weightUnit = 'kg';

  // Non-agricultural product fields
  final _avgWeightController = TextEditingController();
  final _bundleWeightController = TextEditingController();
  final _lengthController = TextEditingController();
  final _widthController = TextEditingController();
  final _heightController = TextEditingController();
  String _dimensionUnit = 'cm';
  final _numberOfProductsController = TextEditingController();
  final _descriptionController = TextEditingController();

  // Document upload state
  File? _packageImage;
  String? _packageImageUrl;
  bool _isUploadingPackageImage = false;

  File? _gstBillImage;
  String? _gstBillUrl;
  bool _isUploadingGstBill = false;

  // Multiple transportation documents
  final List<File> _transportDocs = [];
  final List<String> _transportDocUrls = [];
  final List<bool> _isUploadingTransportDocs = [];

  // UI state
  bool _showDimensions = true; // Persist tab selection

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

    final media = MediaQuery.of(context);
    return MediaQuery(
      data: media.copyWith(textScaler: TextScaler.linear(media.textScaler.scale(0.94).clamp(0.9, 1.0))),
      child: Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.black.withValues(alpha: 0.8)),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Package Details',
          style: textTheme.titleLarge?.copyWith(
            color: Colors.black.withValues(alpha: 0.85),
            fontWeight: FontWeight.w500,
          ),
        ),
        centerTitle: false,
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
                title: 'Select Package Type',
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
                      visualDensity: VisualDensity.compact,
                    ),
                    RadioListTile<bool>(
                      title: const Text('Commercial Use'),
                      value: true,
                      groupValue: _isCommercialUse,
                      onChanged: (value) {
                        setState(() {
                          _isCommercialUse = value!;
                        });
                      },
                      activeColor: colorScheme.primary,
                      visualDensity: VisualDensity.compact,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // Product Type Section
              _buildSectionCard(
                title: 'Select Product Type',
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
                      visualDensity: VisualDensity.compact,
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
                      visualDensity: VisualDensity.compact,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // Agricultural Products Details
              if (_isAgriculturalProduct) ...[
                _buildSectionCard(
                  title: 'Enter Product Details',
                  child: Column(
                    children: [
                      _buildFormField(
                        controller: _productNameController,
                        label: 'Product Name',
                        isRequired: true,
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
                            child: _buildFormField(
                              controller: _weightController,
                              label: 'Approximate Weight',
                              isRequired: true,
                              keyboardType: TextInputType.number,
                              validator: (value) {
                                if (value == null || value.trim().isEmpty) {
                                  return 'Weight is required';
                                }
                                final weight = double.tryParse(value.trim());
                                if (weight == null) {
                                  return 'Please enter a valid number';
                                }
                                if (weight <= 0) {
                                  return 'Weight must be greater than 0';
                                }
                                return null;
                              },
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const SizedBox(height: 16),
                                DropdownButtonFormField<String>(
                                  initialValue: _weightUnit,
                                  decoration: InputDecoration(
                                    labelText: 'Unit',
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                  items: ['kg', 'quintal'].map((unit) {
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
                              ],
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
                  title: 'Enter Product Details',
                  child: Column(
                    children: [
                      // Weight Section
                      const SizedBox(height: 12),
                      _buildFormField(
                        controller: _avgWeightController,
                        label: 'Approximate Total Weight of Shipment (KG)',
                        isRequired: true,
                        keyboardType: TextInputType.number,
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Approximate weight is required';
                          }
                          final weight = double.tryParse(value.trim());
                          if (weight == null) {
                            return 'Invalid weight value';
                          }
                          if (weight <= 0) {
                            return 'Weight must be greater than 0';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      _buildFormField(
                        controller: _bundleWeightController,
                        label: 'Weight of Each Bundle (KG)',
                        isRequired: true,
                        keyboardType: TextInputType.number,
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Bundle weight is required';
                          }
                          final weight = double.tryParse(value.trim());
                          if (weight == null) {
                            return 'Invalid weight value';
                          }
                          if (weight <= 0) {
                            return 'Weight must be greater than 0';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 24),

                      // Tab Switch for Dimensions or Description
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.all(4),
                        child: Row(
                          children: [
                            Expanded(
                              child: GestureDetector(
                                onTap: () {
                                  setState(() {
                                    _showDimensions = true;
                                  });
                                },
                                child: Container(
                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                  decoration: BoxDecoration(
                                    color: _showDimensions ? Colors.white : Colors.transparent,
                                    borderRadius: BorderRadius.circular(10),
                                    boxShadow: _showDimensions
                                        ? [
                                            BoxShadow(
                                              color: Colors.black.withValues(alpha: 0.05),
                                              blurRadius: 4,
                                              offset: const Offset(0, 2),
                                            ),
                                          ]
                                        : null,
                                  ),
                                  child: Text(
                                    'Dimensions',
                                    textAlign: TextAlign.center,
                                    style: textTheme.bodyMedium?.copyWith(
                                      color: _showDimensions ? colorScheme.primary : Colors.grey.shade600,
                                      fontWeight: _showDimensions ? FontWeight.w600 : FontWeight.w500,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            Expanded(
                              child: GestureDetector(
                                onTap: () {
                                  setState(() {
                                    _showDimensions = false;
                                  });
                                },
                                child: Container(
                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                  decoration: BoxDecoration(
                                    color: !_showDimensions ? Colors.white : Colors.transparent,
                                    borderRadius: BorderRadius.circular(10),
                                    boxShadow: !_showDimensions
                                        ? [
                                            BoxShadow(
                                              color: Colors.black.withValues(alpha: 0.05),
                                              blurRadius: 4,
                                              offset: const Offset(0, 2),
                                            ),
                                          ]
                                        : null,
                                  ),
                                  child: Text(
                                    'Description',
                                    textAlign: TextAlign.center,
                                    style: textTheme.bodyMedium?.copyWith(
                                      color: !_showDimensions ? colorScheme.primary : Colors.grey.shade600,
                                      fontWeight: !_showDimensions ? FontWeight.w600 : FontWeight.w500,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),

                      if (_showDimensions) ...[
                        Row(
                        children: [
                          Expanded(
                            child: _buildFormField(
                              controller: _lengthController,
                              label: 'Length',
                              isRequired: true,
                              keyboardType: TextInputType.number,
                              validator: (value) {
                                if (_showDimensions) {
                                  if (value == null || value.trim().isEmpty) {
                                    return 'Length is required';
                                  }
                                  final length = double.tryParse(value.trim());
                                  if (length == null) {
                                    return 'Invalid length value';
                                  }
                                  if (length <= 0) {
                                    return 'Length must be greater than 0';
                                  }
                                }
                                return null;
                              },
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: _buildFormField(
                              controller: _widthController,
                              label: 'Width',
                              isRequired: true,
                              keyboardType: TextInputType.number,
                              validator: (value) {
                                if (_showDimensions) {
                                  if (value == null || value.trim().isEmpty) {
                                    return 'Width is required';
                                  }
                                  final width = double.tryParse(value.trim());
                                  if (width == null) {
                                    return 'Invalid width value';
                                  }
                                  if (width <= 0) {
                                    return 'Width must be greater than 0';
                                  }
                                }
                                return null;
                              },
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: _buildFormField(
                              controller: _heightController,
                              label: 'Height',
                              isRequired: true,
                              keyboardType: TextInputType.number,
                              validator: (value) {
                                if (_showDimensions) {
                                  if (value == null || value.trim().isEmpty) {
                                    return 'Height is required';
                                  }
                                  final height = double.tryParse(value.trim());
                                  if (height == null) {
                                    return 'Invalid height value';
                                  }
                                  if (height <= 0) {
                                    return 'Height must be greater than 0';
                                  }
                                }
                                return null;
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Text(
                                      'Unit',
                                      style: textTheme.bodySmall?.copyWith(
                                        color: Colors.black.withValues(alpha: 0.68),
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                DropdownButtonFormField<String>(
                                  initialValue: _dimensionUnit,
                                  decoration: InputDecoration(
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                                  ),
                                  items: ['cm', 'inches'].map((unit) {
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
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _buildFormField(
                              controller: _numberOfProductsController,
                              label: 'Number of Products',
                              isRequired: true,
                              keyboardType: TextInputType.number,
                              validator: (value) {
                                if (_showDimensions) {
                                  if (value == null || value.trim().isEmpty) {
                                    return 'Number of products is required';
                                  }
                                  final numberOfProducts = int.tryParse(value.trim());
                                  if (numberOfProducts == null) {
                                    return 'Invalid integer value';
                                  }
                                  if (numberOfProducts <= 0) {
                                    return 'Number of products must be greater than 0';
                                  }
                                }
                                return null;
                              },
                            ),
                          ),
                        ],
                      ),
                      ]
                      else ...[
                        _buildFormField(
                          controller: _descriptionController,
                          label: 'Package Description',
                          isRequired: true,
                          hint: 'Provide a detailed description of your package (at least 10 characters)',
                          maxLines: 5,
                          validator: (value) {
                            if (!_showDimensions) {
                              if (value == null || value.trim().isEmpty) {
                                return 'Package description is required';
                              }
                              if (value.trim().length < 10) {
                                return 'Description must be at least 10 characters';
                              }
                            }
                            return null;
                          },
                        ),
                      ],
                      const SizedBox(height: 16),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
              ],

              // Package Image Section (optional)
              _buildSectionCard(
                title: 'Package Image (Optional)',
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Upload a photo of your package to help drivers identify it',
                      style: textTheme.bodyMedium?.copyWith(
                        color: colorScheme.onSurface.withValues(alpha: 0.68),
                      ),
                    ),
                    const SizedBox(height: 16),
                    DocumentUploadCard(
                      title: 'Package Image',
                      subtitle: 'Add package photo (optional)',
                      icon: Icons.camera_alt_rounded,
                      selectedFile: _packageImage,
                      uploadedUrl: _packageImageUrl,
                      isUploading: _isUploadingPackageImage,
                      onUpload: () => _handleDocumentUpload('packageImage'),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // GST Bill Upload Section (for commercial use)
              if (_isCommercialUse) ...[
                DocumentUploadCard(
                  title: 'GST Bill',
                  subtitle: 'Upload your GST bill',
                  icon: Icons.receipt_long_rounded,
                  selectedFile: _gstBillImage,
                  uploadedUrl: _gstBillUrl,
                  isUploading: _isUploadingGstBill,
                  onUpload: () => _handleDocumentUpload('gstBill'),
                  isRequired: true,
                ),
                const SizedBox(height: 20),
              ],

              // Additional Documents Section
              _buildSectionCard(
                title: 'Additional Documents',
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Upload other documents like images, receipts, or any supporting files',
                      style: textTheme.bodyMedium?.copyWith(
                        color: colorScheme.onSurface.withValues(alpha: 0.68),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Existing transportation documents
                    ..._transportDocs.asMap().entries.map((entry) {
                      final index = entry.key;
                      final file = entry.value;
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: DocumentUploadCard(
                          title: 'Document ${index + 1}',
                          subtitle: 'Upload additional document',
                          icon: Icons.attach_file_rounded,
                          selectedFile: file,
                          uploadedUrl: _transportDocUrls[index],
                          isUploading: _isUploadingTransportDocs[index],
                          onUpload: () => _handleDocumentUpload('transportDoc', index: index),
                        ),
                      );
                    }),

                    // Add new document button
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: () => _addNewTransportDocument(),
                        icon: const Icon(Icons.add),
                        label: const Text('Add Another Document'),
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
              ),

              const SizedBox(height: 32),

              // Continue Button (reactive)
              _buildReactiveProceedButton(colorScheme, textTheme),

              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    ));
  }

  Widget _buildSectionCard({required String title, required Widget child}) {
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
                color: Colors.black.withValues(alpha: 0.85),
                fontWeight: FontWeight.w500,
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

    bool hasRequiredFields = false;

    if (_isAgriculturalProduct) {
      hasRequiredFields = _productNameController.text.trim().isNotEmpty &&
                         _weightController.text.trim().isNotEmpty;
    } else if (_isNonAgriculturalProduct) {
      // Check required weights
      final hasWeights = _avgWeightController.text.trim().isNotEmpty &&
                        _bundleWeightController.text.trim().isNotEmpty;

      // Check if either dimensions or description is provided
      final hasDimensions = _lengthController.text.trim().isNotEmpty &&
                          _widthController.text.trim().isNotEmpty &&
                          _heightController.text.trim().isNotEmpty &&
                          _numberOfProductsController.text.trim().isNotEmpty;
      final hasDescription = _descriptionController.text.trim().isNotEmpty;

      hasRequiredFields = hasWeights && (hasDimensions || hasDescription);
    }

    // Check if GST bill is required and uploaded for commercial use
    if (_isCommercialUse && (_gstBillUrl == null || _gstBillUrl!.isEmpty)) {
      return false;
    }

    return hasRequiredFields;
  }

    Future<void> _handleDocumentUpload(String documentType, {int? index}) async {
    try {
      // Pick file
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['jpg', 'jpeg', 'png', 'pdf'],
      );
      if (result == null || result.files.isEmpty) return;

      final file = File(result.files.first.path!);

      // Set loading state
      setState(() {
        switch (documentType) {
          case 'packageImage':
            _packageImage = file;
            _isUploadingPackageImage = true;
            break;
          case 'gstBill':
            _gstBillImage = file;
            _isUploadingGstBill = true;
            break;
          case 'transportDoc':
            if (index != null) {
              // Ensure the lists are large enough
              while (_transportDocs.length <= index) {
                _transportDocs.add(File(''));
                _transportDocUrls.add('');
                _isUploadingTransportDocs.add(false);
              }
              _transportDocs[index] = file;
              _isUploadingTransportDocs[index] = true;
            }
            break;
        }
      });

      // Upload file
      final api = await ref.read(apiProvider.future);
      final fileName = '${documentType}_${DateTime.now().millisecondsSinceEpoch}';
      final filePath = 'customer/documents/$fileName';

      // Determine MIME type based on file extension
      final extension = result.files.first.extension?.toLowerCase() ?? 'jpg';
      final mimeType = extension == 'pdf' ? 'application/pdf' : 'image/$extension';

      final uploadedUrl = await api.uploadFile(file, filePath, mimeType);

      // Update state with uploaded URL
      setState(() {
        switch (documentType) {
          case 'packageImage':
            _packageImageUrl = uploadedUrl;
            _isUploadingPackageImage = false;
            break;
          case 'gstBill':
            _gstBillUrl = uploadedUrl;
            _isUploadingGstBill = false;
            break;
          case 'transportDoc':
            if (index != null && index < _transportDocUrls.length) {
              _transportDocUrls[index] = uploadedUrl;
              _isUploadingTransportDocs[index] = false;
            }
            break;
        }
      });
    } catch (e) {
      // Reset loading state on error
      setState(() {
        switch (documentType) {
          case 'packageImage':
            _isUploadingPackageImage = false;
            break;
          case 'gstBill':
            _isUploadingGstBill = false;
            break;
          case 'transportDoc':
            if (index != null && index < _isUploadingTransportDocs.length) {
              _isUploadingTransportDocs[index] = false;
            }
            break;
        }
      });
      if (mounted) {
        SnackBars.error(context, 'Failed to upload $documentType: $e');
      }
    }
  }

  void _addNewTransportDocument() {
    setState(() {
      _transportDocs.add(File(''));
      _transportDocUrls.add('');
      _isUploadingTransportDocs.add(false);
    });
  }

  Package _buildPackage() {
    final packageType = _isCommercialUse ? PackageType.commercial : PackageType.personal;

    if (_isAgriculturalProduct) {
      return Package.agricultural(
        packageType: packageType,
        productName: _productNameController.text.trim(),
        approximateWeight: double.tryParse(_weightController.text.trim()) ?? 0.0,
        weightUnit: WeightUnit.fromString(_weightUnit.toUpperCase()),
        gstBillUrl: _isCommercialUse ? _gstBillUrl : null,
        transportDocUrls: _transportDocUrls.where((url) => url.isNotEmpty).toList(),
      );
    } else if (_isNonAgriculturalProduct) {
      return Package.nonAgricultural(
        packageType: packageType,
        averageWeight: double.tryParse(_avgWeightController.text.trim()) ?? 0.0,
        bundleWeight: _bundleWeightController.text.trim().isNotEmpty
            ? double.tryParse(_bundleWeightController.text.trim())
            : null,
        length: _lengthController.text.trim().isNotEmpty
            ? double.tryParse(_lengthController.text.trim())
            : null,
        width: _widthController.text.trim().isNotEmpty
            ? double.tryParse(_widthController.text.trim())
            : null,
        height: _heightController.text.trim().isNotEmpty
            ? double.tryParse(_heightController.text.trim())
            : null,
        dimensionUnit: DimensionUnit.fromString(_dimensionUnit.toUpperCase()),
        numberOfProducts: _numberOfProductsController.text.trim().isNotEmpty
            ? int.tryParse(_numberOfProductsController.text.trim())
            : null,
        description: _descriptionController.text.trim(),
        packageImageUrl: _packageImageUrl,
        gstBillUrl: _isCommercialUse ? _gstBillUrl : null,
        transportDocUrls: _transportDocUrls.where((url) => url.isNotEmpty).toList(),
      );
    } else {
      // Default case - should not happen if validation is working
      return Package(
        packageType: packageType,
        productType: ProductType.agricultural,
      );
    }
  }

  void _proceedToEstimate() {
    if (_formKey.currentState!.validate()) {
      final package = _buildPackage();
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => EstimateScreen(
            pickupAddress: widget.pickupAddress,
            dropAddress: widget.dropAddress,
            package: package,
          ),
        ),
      );
    }
  }

  // Consistent form field used across app (label above with red * for required)
  Widget _buildFormField({
    required TextEditingController controller,
    required String label,
    bool isRequired = false,
    TextInputType? keyboardType,
    int maxLines = 1,
    String? hint,
    String? Function(String?)? validator,
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
                color: Colors.black.withValues(alpha: 0.68),
                fontWeight: FontWeight.w600,
              ),
            ),
            if (isRequired)
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
          decoration: InputDecoration(
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            filled: true,
            fillColor: Colors.white,
            hintText: hint,
            hintStyle: textTheme.bodyMedium?.copyWith(
              color: Colors.grey.shade500,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: colorScheme.outline.withValues(alpha: 0.3)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: colorScheme.primary, width: 1.5),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Colors.red),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Colors.red),
            ),
          ),
        ),
      ],
    );
  }

  // Reactive proceed button that listens to text controllers and document states
  Widget _buildReactiveProceedButton(ColorScheme colorScheme, TextTheme textTheme) {
    return ListenableBuilder(
      listenable: Listenable.merge([
        _productNameController,
        _weightController,
        _avgWeightController,
        _bundleWeightController,
        _lengthController,
        _widthController,
        _heightController,
        _numberOfProductsController,
        _descriptionController,
      ]),
      builder: (context, _) {
        final enabled = _canProceed();
        return SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: enabled ? _proceedToEstimate : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: enabled ? colorScheme.primary : Colors.grey.shade200,
              foregroundColor: enabled ? Colors.white : Colors.grey.shade500,
              padding: const EdgeInsets.symmetric(vertical: 18),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: enabled ? 2 : 1,
            ),
            child: Text(
              'Proceed to Estimate',
              style: textTheme.titleMedium?.copyWith(
                color: enabled ? Colors.white : Colors.grey.shade500,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        );
      },
    );
  }
}