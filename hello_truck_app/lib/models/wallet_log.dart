import 'package:hello_truck_app/models/pending_refund.dart';

class WalletLog {
  final String id;
  final double beforeBalance;
  final double afterBalance;
  final double amount;
  final String reason;
  final String? bookingId;
  final String? refundIntentId;
  final RefundIntent? refundIntent;
  final DateTime createdAt;

  const WalletLog({
    required this.id,
    required this.beforeBalance,
    required this.afterBalance,
    required this.amount,
    required this.reason,
    this.bookingId,
    this.refundIntentId,
    this.refundIntent,
    required this.createdAt,
  });

  factory WalletLog.fromJson(Map<String, dynamic> json) {
    return WalletLog(
      id: json['id'] ?? '',
      beforeBalance: (json['beforeBalance'] ?? 0).toDouble(),
      afterBalance: (json['afterBalance'] ?? 0).toDouble(),
      amount: (json['amount'] ?? 0).toDouble(),
      reason: json['reason'] ?? '',
      bookingId: json['bookingId'],
      refundIntentId: json['refundIntentId'],
      refundIntent: json['refundIntent'] != null
          ? RefundIntent.fromJson(json['refundIntent'])
          : null,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : DateTime.now(),
    );
  }

  bool get isCredit => amount > 0;
  bool get isDebit => amount < 0;
}
