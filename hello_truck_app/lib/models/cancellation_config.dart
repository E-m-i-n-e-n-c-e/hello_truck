class CancellationConfig {
  final double minChargePercent;
  final double maxChargePercent;
  final double incrementPerKm;

  const CancellationConfig({
    required this.minChargePercent,
    required this.maxChargePercent,
    required this.incrementPerKm,
  });

  factory CancellationConfig.fromJson(Map<String, dynamic> json) {
    return CancellationConfig(
      minChargePercent: (json['minChargePercent'] ?? 0.1).toDouble(),
      maxChargePercent: (json['maxChargePercent'] ?? 0.5).toDouble(),
      incrementPerKm: (json['incrementPerKm'] ?? 0.05).toDouble(),
    );
  }

  /// Calculate cancellation charge percentage based on distance travelled
  double calculateChargePercent(double kmTravelled) {
    final chargePercent = minChargePercent + (kmTravelled * incrementPerKm);
    return chargePercent.clamp(minChargePercent, maxChargePercent);
  }

  /// Calculate refund percentage (inverse of charge)
  double calculateRefundPercent(double kmTravelled) {
    return 1 - calculateChargePercent(kmTravelled);
  }
}
