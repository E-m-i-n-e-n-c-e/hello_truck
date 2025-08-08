import 'dart:io';

enum ProductType {
  agricultural,
  nonAgricultural,
}

enum LoadingPreference {
  selfLoading,
  requireLoadmanAtLoadingPoint,
  requireLoadmanAtUnloadingPoint,
}

class PackageDimensions {
  final double? length;
  final double? width;
  final double? height;

  const PackageDimensions({
    this.length,
    this.width,
    this.height,
  });

  Map<String, dynamic> toJson() {
    return {
      'length': length,
      'width': width,
      'height': height,
    };
  }

  factory PackageDimensions.fromJson(Map<String, dynamic> json) {
    return PackageDimensions(
      length: json['length']?.toDouble(),
      width: json['width']?.toDouble(),
      height: json['height']?.toDouble(),
    );
  }

  bool get isValid => length != null && width != null && height != null;

  @override
  String toString() {
    if (!isValid) return 'No dimensions provided';
    return 'L: ${length}cm x W: ${width}cm x H: ${height}cm';
  }
}

class Package {
  final String id;
  final ProductType productType;
  final double? weight; // in KG
  final PackageDimensions? dimensions; // in CM
  final String? description;
  final LoadingPreference loadingPreference;
  final String? packageImagePath;
  final String? gstBillImagePath;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Package({
    required this.id,
    required this.productType,
    this.weight,
    this.dimensions,
    this.description,
    required this.loadingPreference,
    this.packageImagePath,
    this.gstBillImagePath,
    required this.createdAt,
    required this.updatedAt,
  });

  // Factory constructor to create a Package from form data
  factory Package.fromFormData({
    required ProductType productType,
    double? weight,
    PackageDimensions? dimensions,
    String? description,
    required LoadingPreference loadingPreference,
    File? packageImage,
    File? gstBillImage,
  }) {
    final now = DateTime.now();
    final id = 'pkg_${now.millisecondsSinceEpoch}';

    return Package(
      id: id,
      productType: productType,
      weight: weight,
      dimensions: dimensions,
      description: description,
      loadingPreference: loadingPreference,
      packageImagePath: packageImage?.path,
      gstBillImagePath: gstBillImage?.path,
      createdAt: now,
      updatedAt: now,
    );
  }

  // JSON serialization for backend communication
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'productType': productType.name,
      'weight': weight,
      'dimensions': dimensions?.toJson(),
      'description': description,
      'loadingPreference': loadingPreference.name,
      'packageImagePath': packageImagePath,
      'gstBillImagePath': gstBillImagePath,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory Package.fromJson(Map<String, dynamic> json) {
    return Package(
      id: json['id'] ?? '',
      productType: ProductType.values.firstWhere(
        (e) => e.name == json['productType'],
        orElse: () => ProductType.nonAgricultural,
      ),
      weight: json['weight']?.toDouble(),
      dimensions: json['dimensions'] != null
          ? PackageDimensions.fromJson(json['dimensions'])
          : null,
      description: json['description'],
      loadingPreference: LoadingPreference.values.firstWhere(
        (e) => e.name == json['loadingPreference'],
        orElse: () => LoadingPreference.selfLoading,
      ),
      packageImagePath: json['packageImagePath'],
      gstBillImagePath: json['gstBillImagePath'],
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : DateTime.now(),
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'])
          : DateTime.now(),
    );
  }

  // Create a copy with updated fields
  Package copyWith({
    String? id,
    ProductType? productType,
    double? weight,
    PackageDimensions? dimensions,
    String? description,
    LoadingPreference? loadingPreference,
    String? packageImagePath,
    String? gstBillImagePath,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Package(
      id: id ?? this.id,
      productType: productType ?? this.productType,
      weight: weight ?? this.weight,
      dimensions: dimensions ?? this.dimensions,
      description: description ?? this.description,
      loadingPreference: loadingPreference ?? this.loadingPreference,
      packageImagePath: packageImagePath ?? this.packageImagePath,
      gstBillImagePath: gstBillImagePath ?? this.gstBillImagePath,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  // Validation methods
  bool get isValid {
    // Basic validation - loadingPreference is required (non-nullable)

    if (productType == ProductType.agricultural) {
      return weight != null && weight! > 0;
    } else {
      // Non-agricultural products need at least one of: weight, dimensions, or description
      bool hasWeight = weight != null && weight! > 0;
      bool hasDimensions = dimensions?.isValid ?? false;
      bool hasDescription = description != null && description!.trim().isNotEmpty;

      return (hasWeight || hasDimensions || hasDescription) && gstBillImagePath != null;
    }
  }

  String get productTypeDisplayName {
    switch (productType) {
      case ProductType.agricultural:
        return 'Agricultural Products';
      case ProductType.nonAgricultural:
        return 'Non-Agricultural Products';
    }
  }

  String get loadingPreferenceDisplayName {
    switch (loadingPreference) {
      case LoadingPreference.selfLoading:
        return 'Self-Loading';
      case LoadingPreference.requireLoadmanAtLoadingPoint:
        return 'Require Loadman at Loading Point';
      case LoadingPreference.requireLoadmanAtUnloadingPoint:
        return 'Require Loadman at Unloading Point';
    }
  }

  // Pretty print for debugging and backend team
  @override
  String toString() {
    final buffer = StringBuffer();
    buffer.writeln('📦 Package Details:');
    buffer.writeln('  ID: $id');
    buffer.writeln('  Product Type: $productTypeDisplayName');

    if (weight != null) {
      buffer.writeln('  Weight: ${weight}kg');
    }

    if (dimensions != null && dimensions!.isValid) {
      buffer.writeln('  Dimensions: $dimensions');
    }

    if (description != null && description!.isNotEmpty) {
      buffer.writeln('  Description: $description');
    }

    buffer.writeln('  Loading Preference: $loadingPreferenceDisplayName');

    if (packageImagePath != null) {
      buffer.writeln('  Package Image: $packageImagePath');
    }

    if (gstBillImagePath != null) {
      buffer.writeln('  GST Bill Image: $gstBillImagePath');
    }

    buffer.writeln('  Created: ${createdAt.toLocal()}');
    buffer.writeln('  Updated: ${updatedAt.toLocal()}');
    buffer.writeln('  Valid: ${isValid ? "✅" : "❌"}');

    return buffer.toString();
  }

  // Generate a formatted JSON string for backend
  String toFormattedJson() {
    const indent = '  ';
    final json = toJson();
    final buffer = StringBuffer();

    buffer.writeln('{');
    json.forEach((key, value) {
      if (value is Map) {
        buffer.writeln('$indent"$key": {');
        value.forEach((subKey, subValue) {
          buffer.writeln('$indent$indent"$subKey": ${_formatJsonValue(subValue)},');
        });
        buffer.writeln('$indent},');
      } else {
        buffer.writeln('$indent"$key": ${_formatJsonValue(value)},');
      }
    });
    buffer.writeln('}');

    return buffer.toString();
  }

  String _formatJsonValue(dynamic value) {
    if (value == null) return 'null';
    if (value is String) return '"$value"';
    return value.toString();
  }
}

// Helper extension for enum parsing
extension LoadingPreferenceExtension on LoadingPreference {
  static LoadingPreference fromString(String value) {
    switch (value) {
      case 'Self-Loading':
        return LoadingPreference.selfLoading;
      case 'Require Loadman at Loading Point':
        return LoadingPreference.requireLoadmanAtLoadingPoint;
      case 'Require Loadman at Unloading Point':
        return LoadingPreference.requireLoadmanAtUnloadingPoint;
      default:
        return LoadingPreference.selfLoading;
    }
  }
}