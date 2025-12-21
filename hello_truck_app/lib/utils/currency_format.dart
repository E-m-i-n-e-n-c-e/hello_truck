/// Extension for formatting currency values
/// Shows decimals only when needed (e.g., 500 → "500", 500.50 → "500.50")
extension CurrencyFormat on num {
  /// Format as currency string
  /// - Whole numbers: no decimals (500 → "500")
  /// - 1-2 decimals: show as-is (500.5 → "500.5", 500.50 → "500.50")
  /// - More decimals: truncate to 2 (500.123 → "500.12")
  String toCurrency() {
    if (this == toInt()) {
      return toInt().toString();
    }
    // Round to 2 decimal places
    final rounded = (this * 100).round() / 100;
    if (rounded == rounded.toInt()) {
      return rounded.toInt().toString();
    }
    return rounded.toStringAsFixed(2).replaceAll(RegExp(r'\.?0+$'), '');
  }

  /// Format with rupee symbol
  String toRupees() => '₹${toCurrency()}';
}
