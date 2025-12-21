import 'package:hello_truck_app/models/booking.dart';

class RefundIntent {
  final String id;
  final String status;
  final double walletRefundAmount;
  final double razorpayRefundAmount;
  final double cancellationCharge;
  final String? rzpRefundId;
  final DateTime createdAt;
  final DateTime? processedAt;
  final String? failureReason;

  const RefundIntent({
    required this.id,
    required this.status,
    required this.walletRefundAmount,
    required this.razorpayRefundAmount,
    required this.cancellationCharge,
    this.rzpRefundId,
    required this.createdAt,
    this.processedAt,
    this.failureReason,
  });

  factory RefundIntent.fromJson(Map<String, dynamic> json) {
    return RefundIntent(
      id: json['id'] ?? '',
      status: json['status'] ?? '',
      walletRefundAmount: (json['walletRefundAmount'] ?? 0).toDouble(),
      razorpayRefundAmount: (json['razorpayRefundAmount'] ?? 0).toDouble(),
      cancellationCharge: (json['cancellationCharge'] ?? 0).toDouble(),
      rzpRefundId: json['rzpRefundId'],
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : DateTime.now(),
      processedAt: json['processedAt'] != null
          ? DateTime.parse(json['processedAt'])
          : null,
      failureReason: json['failureReason'],
    );
  }

  double get totalRefundAmount => walletRefundAmount + razorpayRefundAmount;
  bool get isPending => status == 'PENDING';
  bool get isFailed => status == 'FAILED';
}

class PendingRefund {
  final String id;
  final String status;
  final double walletRefundAmount;
  final double razorpayRefundAmount;
  final double cancellationCharge;
  final String? rzpRefundId;
  final Booking booking;
  final DateTime createdAt;
  final DateTime? processedAt;
  final String? failureReason;

  const PendingRefund({
    required this.id,
    required this.status,
    required this.walletRefundAmount,
    required this.razorpayRefundAmount,
    required this.cancellationCharge,
    this.rzpRefundId,
    required this.booking,
    required this.createdAt,
    this.processedAt,
    this.failureReason,
  });

  factory PendingRefund.fromJson(Map<String, dynamic> json) {
    return PendingRefund(
      id: json['id'] ?? '',
      status: json['status'] ?? '',
      walletRefundAmount: (json['walletRefundAmount'] ?? 0).toDouble(),
      razorpayRefundAmount: (json['razorpayRefundAmount'] ?? 0).toDouble(),
      cancellationCharge: (json['cancellationCharge'] ?? 0).toDouble(),
      rzpRefundId: json['rzpRefundId'],
      booking: Booking.fromJson(json['booking']),
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : DateTime.now(),
      processedAt: json['processedAt'] != null
          ? DateTime.parse(json['processedAt'])
          : null,
      failureReason: json['failureReason'],
    );
  }

  double get totalRefundAmount => walletRefundAmount + razorpayRefundAmount;
  bool get isPending => status == 'PENDING';
  bool get isFailed => status == 'FAILED';
}
