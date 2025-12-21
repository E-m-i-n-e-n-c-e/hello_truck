class CancellationConfig {
  final double minChargePercent;
  final double maxChargePercent;
  final double incrementPerMinute;

  const CancellationConfig({
    required this.minChargePercent,
    required this.maxChargePercent,
    required this.incrementPerMinute,
  });

  factory CancellationConfig.fromJson(Map<String, dynamic> json) {
    return CancellationConfig(
      minChargePercent: (json['minChargePercent'] ?? 0.1).toDouble(),
      maxChargePercent: (json['maxChargePercent'] ?? 0.5).toDouble(),
      incrementPerMinute: (json['incrementPerMinute'] ?? 0.01).toDouble(),
    );
  }

  /// Calculate cancellation charge percentage based on time elapsed since acceptance
  double calculateChargePercent(DateTime? acceptedAt) {
    if (acceptedAt == null) return minChargePercent;

    final minutesElapsed = DateTime.now().difference(acceptedAt).inMinutes;
    final chargePercent = minChargePercent + (minutesElapsed * incrementPerMinute);
    return chargePercent.clamp(minChargePercent, maxChargePercent);
  }

  /// Calculate refund percentage (inverse of charge)
  double calculateRefundPercent(DateTime? acceptedAt) {
    return 1 - calculateChargePercent(acceptedAt);
  }
}
