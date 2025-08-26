enum PackageType {
  personal('PERSONAL'),
  commercial('COMMERCIAL');

  const PackageType(this.value);
  final String value;

  static PackageType fromString(String value) {
    return PackageType.values.firstWhere(
      (type) => type.value == value,
    );
  }
}

enum ProductType {
  agricultural('AGRICULTURAL'),
  nonAgricultural('NON_AGRICULTURAL');

  const ProductType(this.value);
  final String value;

  static ProductType fromString(String value) {
    return ProductType.values.firstWhere(
      (type) => type.value == value,
    );
  }
}

enum WeightUnit {
  kg('KG'),
  quintal('QUINTAL');

  const WeightUnit(this.value);
  final String value;

  static WeightUnit fromString(String value) {
    return WeightUnit.values.firstWhere(
      (unit) => unit.value == value,
    );
  }
}

enum DimensionUnit {
  cm('CM'),
  inches('INCHES');

  const DimensionUnit(this.value);
  final String value;

  static DimensionUnit fromString(String value) {
    return DimensionUnit.values.firstWhere(
      (unit) => unit.value == value,
    );
  }
}
