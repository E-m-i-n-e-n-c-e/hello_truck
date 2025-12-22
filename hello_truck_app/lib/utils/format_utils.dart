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

/// Extension for formatting distance values
/// Input assumed to be in Kilometers (km)
extension DistanceFormat on num {
  /// Formats distance
  /// - < 1 km: show in meters (0.5 km → "500 m")
  /// - >= 1 km: show in km with 1 decimal (1.5 km → "1.5 km")
  String toDistance() {
    if (this < 1) {
      return '${(this * 1000).round()} m';
    }
    String s = toStringAsFixed(1);
    if (s.endsWith('.0')) {
      return '${s.substring(0, s.length - 2)} km';
    }
    return '$s km';
  }
}

/// Extension for formatting weight values
extension WeightFormat on num {
  /// Formats tons to kg string
  /// 1.5 → "1500 kg"
  String tonsToKg() {
    return '${(this * 1000).round()} kg';
  }
}
