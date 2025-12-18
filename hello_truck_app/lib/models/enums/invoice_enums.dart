enum PaymentMethod {
  online('ONLINE'),
  cash('CASH');

  const PaymentMethod(this.value);
  final String value;

  static PaymentMethod fromString(String value) {
    return PaymentMethod.values.firstWhere(
      (method) => method.value == value,
    );
  }
}

enum InvoiceType {
  estimate('ESTIMATE'),
  final_('FINAL');

  const InvoiceType(this.value);
  final String value;

  static InvoiceType fromString(String value) {
    return InvoiceType.values.firstWhere(
      (type) => type.value == value,
    );
  }
}