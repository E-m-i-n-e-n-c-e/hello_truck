import 'enums/package_enums.dart';

class Package {
  final PackageType packageType;
  final ProductType productType;

  // Agricultural Product Fields
  final String? productName;
  final double? approximateWeight;
  final WeightUnit? weightUnit;

  // Non-Agricultural Product Fields
  final double? averageWeight;
  final double? bundleWeight;
  final int? numberOfProducts;
  final double? length;
  final double? width;
  final double? height;
  final DimensionUnit? dimensionUnit;
  final String? description;
  final String? packageImageUrl;

  // Document URLs
  final String? gstBillUrl;
  final List<String> transportDocUrls;

  const Package({
    required this.packageType,
    required this.productType,
    this.productName,
    this.approximateWeight,
    this.weightUnit,
    this.averageWeight,
    this.bundleWeight,
    this.length,
    this.width,
    this.height,
    this.dimensionUnit,
    this.numberOfProducts,
    this.description,
    this.packageImageUrl,
    this.gstBillUrl,
    this.transportDocUrls = const [],
  });

  // Factory constructor for Agricultural Products
  factory Package.agricultural({
    required PackageType packageType,
    required String productName,
    required double approximateWeight,
    required WeightUnit weightUnit,
    String? gstBillUrl,
    List<String> transportDocUrls = const [],
  }) {
    return Package(
      packageType: packageType,
      productType: ProductType.agricultural,
      productName: productName,
      approximateWeight: approximateWeight,
      weightUnit: weightUnit,
      gstBillUrl: gstBillUrl,
      transportDocUrls: transportDocUrls,
    );
  }

  // Factory constructor for Non-Agricultural Products
  factory Package.nonAgricultural({
    required PackageType packageType,
    required double averageWeight,
    double? bundleWeight,
    double? length,
    double? width,
    double? height,
    DimensionUnit? dimensionUnit,
    int? numberOfProducts,
    String? description,
    String? packageImageUrl,
    String? gstBillUrl,
    List<String> transportDocUrls = const [],
  }) {
    return Package(
      packageType: packageType,
      productType: ProductType.nonAgricultural,
      averageWeight: averageWeight,
      bundleWeight: bundleWeight,
      length: length,
      width: width,
      height: height,
      dimensionUnit: dimensionUnit,
      numberOfProducts: numberOfProducts,
      description: description,
      packageImageUrl: packageImageUrl,
      gstBillUrl: gstBillUrl,
      transportDocUrls: transportDocUrls,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'packageType': packageType.value,
      'productType': productType.value,
      if (productType == ProductType.agricultural) ...{
        'agricultural': {
          'productName': productName,
          'approximateWeight': approximateWeight,
          'weightUnit': weightUnit?.value,
        },
      },
      if (productType == ProductType.nonAgricultural) ...{
        'nonAgricultural': {
          'averageWeight': averageWeight,
          'bundleWeight': bundleWeight,
          'numberOfProducts': numberOfProducts,
          'packageDimensions': {
            'length': length,
            'width': width,
            'height': height,
            'unit': dimensionUnit?.value,
          },
          'packageDescription': description,
          'packageImageUrl': packageImageUrl,
        },
      },
      if (packageType == PackageType.commercial) ...{
        'gstBillUrl': gstBillUrl,
      },
      'transportDocUrls': transportDocUrls,
    };
  }

  factory Package.fromJson(Map<String, dynamic> json) {
    final packageType = PackageType.fromString(json['packageType'] ?? 'PERSONAL');
    final productType = ProductType.fromString(json['productType'] ?? 'AGRICULTURAL');

    return Package(
      packageType: packageType,
      productType: productType,
      productName: json['productName'],
      approximateWeight: json['approximateWeight']?.toDouble(),
      weightUnit: json['weightUnit'] != null
          ? WeightUnit.fromString(json['weightUnit'])
          : null,
      averageWeight: json['averageWeight']?.toDouble(),
      bundleWeight: json['bundleWeight']?.toDouble(),
      length: json['length']?.toDouble(),
      width: json['width']?.toDouble(),
      height: json['height']?.toDouble(),
      dimensionUnit: json['dimensionUnit'] != null
          ? DimensionUnit.fromString(json['dimensionUnit'])
          : null,
      numberOfProducts: json['numberOfProducts']?.toInt(),
      description: json['description'],
      packageImageUrl: json['packageImageUrl'],
      gstBillUrl: json['gstBillUrl'],
      transportDocUrls: List<String>.from(json['transportDocUrls'] ?? []),
    );
  }
}