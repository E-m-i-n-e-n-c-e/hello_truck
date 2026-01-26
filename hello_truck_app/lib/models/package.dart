import 'package:equatable/equatable.dart';

import 'enums/package_enums.dart';

class Package extends Equatable {
  final ProductType productType;
  final double approximateWeight;
  final WeightUnit weightUnit;

  // Personal/Agricultural Product Fields
  final String? productName;

  // Non-Agricultural Product Fields
  final double? bundleWeight;
  final int? numberOfProducts;
  final double? length;
  final double? width;
  final double? height;
  final DimensionUnit? dimensionUnit;
  final String? description;
  final String? packageImageUrl;

  // Document URLs
  final String? gstBillUrl; // Required for non personal products
  final List<String> transportDocUrls;

  const Package({
    required this.productType,
    required this.approximateWeight,
    required this.weightUnit,
    this.productName,
    this.bundleWeight,
    this.numberOfProducts,
    this.length,
    this.width,
    this.height,
    this.dimensionUnit,
    this.description,
    this.packageImageUrl,
    this.gstBillUrl,
    this.transportDocUrls = const [],
  });

  @override
  List<Object?> get props => [
        productType,
        approximateWeight,
        weightUnit,
        productName,
        bundleWeight,
        numberOfProducts,
        length,
        width,
        height,
        dimensionUnit,
        description,
        packageImageUrl,
        gstBillUrl,
        transportDocUrls,
      ];

  // Factory constructor for Personal Products
  factory Package.personal({
    required String productName,
    required double approximateWeight,
    required WeightUnit weightUnit,
    String? packageImageUrl,
    List<String> transportDocUrls = const [],
  }) {
    return Package(
      productType: ProductType.personal,
      approximateWeight: approximateWeight,
      weightUnit: weightUnit,
      // Personal Product Fields
      productName: productName,
      // Document URLs
      packageImageUrl: packageImageUrl,
      transportDocUrls: transportDocUrls,
    );
  }

  // Factory constructor for Agricultural Products
  factory Package.agricultural({
    required String productName,
    required double approximateWeight,
    required WeightUnit weightUnit,
    String? gstBillUrl,
    String? packageImageUrl,
    List<String> transportDocUrls = const [],
  }) {
    return Package(
      productType: ProductType.agricultural,
      approximateWeight: approximateWeight,
      weightUnit: weightUnit,
      // Agricultural Product Fields
      productName: productName,
      gstBillUrl: gstBillUrl,
      // Document URLs
      packageImageUrl: packageImageUrl,
      transportDocUrls: transportDocUrls,
    );
  }

  // Factory constructor for Non-Agricultural Products
  factory Package.nonAgricultural({
    required double approximateWeight,
    required double bundleWeight,
    required String gstBillUrl,
    WeightUnit weightUnit = WeightUnit.kg, // Defaults to kg for now
    int? numberOfProducts,
    double? length,
    double? width,
    double? height,
    DimensionUnit? dimensionUnit,
    String? description,
    String? packageImageUrl,
    List<String> transportDocUrls = const [],
  }) {
    return Package(
      productType: ProductType.nonAgricultural,
      approximateWeight: approximateWeight,
      weightUnit: weightUnit,
      // Non-Agricultural Product Fields
      bundleWeight: bundleWeight,
      numberOfProducts: numberOfProducts,
      length: length,
      width: width,
      height: height,
      dimensionUnit: dimensionUnit,
      description: description,
      gstBillUrl: gstBillUrl,
      // Document URLs
      packageImageUrl: packageImageUrl,
      transportDocUrls: transportDocUrls,
    );
  }

  /// toJson - NESTED structure for PackageDetailsDto (REQUEST)
  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{
      'productType': productType.value,
      'approximateWeight': approximateWeight,
      'weightUnit': weightUnit.value,
    };

    // Add nested product-specific fields based on productType
    if (productType == ProductType.personal) {
      json['personal'] = {
        'productName': productName,
      };
    } else if (productType == ProductType.agricultural) {
      json['agricultural'] = {
        'productName': productName,
        'gstBillUrl': gstBillUrl,
      };
    } else if (productType == ProductType.nonAgricultural) {
      json['nonAgricultural'] = {
        'bundleWeight': bundleWeight,
        if (numberOfProducts != null) 'numberOfProducts': numberOfProducts,
        if (length != null && width != null && height != null && dimensionUnit != null)
          'packageDimensions': {
            'length': length,
            'width': width,
            'height': height,
            'unit': dimensionUnit!.value,
          },
        if (description != null) 'packageDescription': description,
        'gstBillUrl': gstBillUrl,
      };
    }

    if (packageImageUrl != null) json['packageImageUrl'] = packageImageUrl;
    if (transportDocUrls.isNotEmpty) json['transportDocUrls'] = transportDocUrls;

    return json;
  }

  /// fromJson - FLAT structure from PackageDetailsResponseDto (RESPONSE)
  factory Package.fromJson(Map<String, dynamic> json) {
    return Package(
      productType: ProductType.fromString(json['productType']),
      approximateWeight: (json['approximateWeight'] as num).toDouble(),
      weightUnit: WeightUnit.fromString(json['weightUnit']),
      productName: json['productName'],
      bundleWeight: json['bundleWeight']?.toDouble(),
      numberOfProducts: json['numberOfProducts'],
      length: json['length']?.toDouble(),
      width: json['width']?.toDouble(),
      height: json['height']?.toDouble(),
      dimensionUnit: json['dimensionUnit'] != null
          ? DimensionUnit.fromString(json['dimensionUnit'])
          : null,
      description: json['description'],
      packageImageUrl: json['packageImageUrl'],
      gstBillUrl: json['gstBillUrl'],
      transportDocUrls: List<String>.from(json['transportDocUrls'] ?? []),
    );
  }

    /// Check if this is a personal package
  bool get isPersonal => productType == ProductType.personal;

  /// Check if this is agricultural
  bool get isAgricultural => productType == ProductType.agricultural;

  /// Check if this is non-agricultural
  bool get isNonAgricultural => productType == ProductType.nonAgricultural;

  /// Check if this is commercial (requires GST)
  bool get isCommercial => productType != ProductType.personal;

  /// Get the package type (personal or commercial) - derived from productType
  PackageType get packageType => isCommercial ? PackageType.commercial : PackageType.personal;
}