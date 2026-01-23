class CancellationConfig {
  final double minChargePercent;
  final double maxChargePercent;
  final double incrementPerMin;

  const CancellationConfig({
    required this.minChargePercent,
    required this.maxChargePercent,
    required this.incrementPerMin,
  });

  factory CancellationConfig.fromJson(Map<String, dynamic> json) {
    return CancellationConfig(
      minChargePercent: (json['minChargePercent'] ?? 0.1).toDouble(),
      maxChargePercent: (json['maxChargePercent'] ?? 0.7).toDouble(),
      incrementPerMin: (json['incrementPerMin'] ?? 0.01).toDouble(),
    );
  }

  /// Calculate cancellation charge percentage based on time elapsed since driver acceptance
  double calculateChargePercent(DateTime? acceptedAt) {
    if (acceptedAt == null) return 0;

    final minutesElapsed = DateTime.now().difference(acceptedAt).inMinutes;
    final calculatedCharge = minutesElapsed * incrementPerMin;
    return calculatedCharge.clamp(minChargePercent, maxChargePercent);
  }

  /// Calculate refund percentage (inverse of charge)
  double calculateRefundPercent(DateTime? acceptedAt) {
    return 1 - calculateChargePercent(acceptedAt);
  }
}
