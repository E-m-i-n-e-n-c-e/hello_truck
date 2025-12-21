import 'package:hello_truck_app/models/booking.dart';
import 'package:hello_truck_app/models/pending_refund.dart';

enum TransactionType { credit, debit }

enum TransactionCategory {
  bookingPayment,
  bookingRefund,
  walletCredit,
  walletDebit,
  other,
}

enum PaymentMethod { cash, online, wallet }

class TransactionLog {
  final String id;
  final String? customerId;
  final String? driverId;
  final double amount;
  final TransactionType type;
  final TransactionCategory category;
  final String description;
  final String? bookingId;
  final Booking? booking;
  final String? payoutId;
  final String? refundIntentId;
  final RefundIntent? refundIntent;
  final PaymentMethod paymentMethod;
  final DateTime createdAt;

  const TransactionLog({
    required this.id,
    this.customerId,
    this.driverId,
    required this.amount,
    required this.type,
    required this.category,
    required this.description,
    this.bookingId,
    this.booking,
    this.payoutId,
    this.refundIntentId,
    this.refundIntent,
    required this.paymentMethod,
    required this.createdAt,
  });

  factory TransactionLog.fromJson(Map<String, dynamic> json) {
    return TransactionLog(
      id: json['id'] ?? '',
      customerId: json['customerId'],
      driverId: json['driverId'],
      amount: (json['amount'] ?? 0).toDouble(),
      type: _parseTransactionType(json['type']),
      category: _parseTransactionCategory(json['category']),
      description: json['description'] ?? '',
      bookingId: json['bookingId'],
      booking: json['booking'] != null ? Booking.fromJson(json['booking']) : null,
      payoutId: json['payoutId'],
      refundIntentId: json['refundIntentId'],
      refundIntent: json['refundIntent'] != null
          ? RefundIntent.fromJson(json['refundIntent'])
          : null,
      paymentMethod: _parsePaymentMethod(json['paymentMethod']),
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : DateTime.now(),
    );
  }

  static TransactionType _parseTransactionType(String? type) {
    switch (type?.toUpperCase()) {
      case 'CREDIT':
        return TransactionType.credit;
      case 'DEBIT':
        return TransactionType.debit;
      default:
        return TransactionType.debit;
    }
  }

  static TransactionCategory _parseTransactionCategory(String? category) {
    switch (category?.toUpperCase()) {
      case 'BOOKING_PAYMENT':
        return TransactionCategory.bookingPayment;
      case 'BOOKING_REFUND':
        return TransactionCategory.bookingRefund;
      case 'WALLET_CREDIT':
        return TransactionCategory.walletCredit;
      case 'WALLET_DEBIT':
        return TransactionCategory.walletDebit;
      default:
        return TransactionCategory.other;
    }
  }

  static PaymentMethod _parsePaymentMethod(String? method) {
    switch (method?.toUpperCase()) {
      case 'CASH':
        return PaymentMethod.cash;
      case 'ONLINE':
        return PaymentMethod.online;
      case 'WALLET':
        return PaymentMethod.wallet;
      default:
        return PaymentMethod.online;
    }
  }

  bool get isCredit => type == TransactionType.credit;
  bool get isDebit => type == TransactionType.debit;
}
