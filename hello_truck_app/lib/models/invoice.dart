

import 'package:hello_truck_app/models/enums/invoice_enums.dart';

class Invoice {
  final String id;
  final String bookingId;
  final InvoiceType type;
  final String vehicleModelName;
  final double basePrice;
  final double perKmPrice;
  final int baseKm;
  final double distanceKm;
  final double weightInTons;
  final double effectiveBasePrice;
  final double platformFee;
  final double totalPrice;
  final String? gstNumber;
  final double walletApplied;
  final double finalAmount;
  final String? paymentLinkUrl;
  final String? rzpPaymentLinkId;
  final String? rzpPaymentId;
  final bool isPaid;
  final DateTime? paidAt;
  final PaymentMethod? paymentMethod;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Invoice({
    required this.id,
    required this.bookingId,
    required this.type,
    required this.vehicleModelName,
    required this.basePrice,
    required this.perKmPrice,
    required this.baseKm,
    required this.distanceKm,
    required this.weightInTons,
    required this.effectiveBasePrice,
    required this.platformFee,
    required this.totalPrice,
    this.gstNumber,
    required this.walletApplied,
    required this.finalAmount,
    this.paymentLinkUrl,
    this.rzpPaymentLinkId,
    this.rzpPaymentId,
    required this.isPaid,
    this.paidAt,
    this.paymentMethod,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Invoice.fromJson(Map<String, dynamic> json) {
    return Invoice(
      id: json['id'],
      bookingId: json['bookingId'],
      type: InvoiceType.fromString(json['type']),
      vehicleModelName: json['vehicleModelName'],
      basePrice: json['basePrice']?.toDouble(),
      perKmPrice: json['perKmPrice']?.toDouble(),
      baseKm: json['baseKm'],
      distanceKm: json['distanceKm']?.toDouble(),
      weightInTons: json['weightInTons']?.toDouble(),
      effectiveBasePrice: json['effectiveBasePrice']?.toDouble(),
      platformFee: json['platformFee']?.toDouble() ?? 0.0,
      totalPrice: json['totalPrice']?.toDouble(),
      gstNumber: json['gstNumber'] ?? 'test',
      walletApplied: json['walletApplied']?.toDouble(),
      finalAmount: json['finalAmount']?.toDouble(),
      paymentLinkUrl: json['paymentLinkUrl'],
      rzpPaymentLinkId: json['rzpPaymentLinkId'],
      rzpPaymentId: json['rzpPaymentId'],
      isPaid: json['isPaid'],
      paidAt: json['paidAt'] != null ? DateTime.parse(json['paidAt']) : null,
      paymentMethod: json['paymentMethod'] != null
          ? PaymentMethod.fromString(json['paymentMethod'])
          : null,
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: DateTime.parse(json['updatedAt']),
    );
  }
}
