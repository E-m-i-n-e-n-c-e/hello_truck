import 'package:hello_truck_app/models/enums/booking_enums.dart';

class BookingEstimate {
  final double distanceKm;
  final VehicleType suggestedVehicleType;
  final List<VehicleOption> vehicleOptions;

  const BookingEstimate({
    required this.distanceKm,
    required this.suggestedVehicleType,
    required this.vehicleOptions,
  });

  factory BookingEstimate.fromJson(Map<String, dynamic> json) {
    return BookingEstimate(
      distanceKm: json['distanceKm'] != null
          ? double.parse(json['distanceKm'].toString())
          : 0.0,
      suggestedVehicleType: VehicleType.fromString(json['suggestedVehicleType'] ?? 'FOUR_WHEELER'),
      vehicleOptions: (json['vehicleOptions'] as List<dynamic>)
          .map((option) => VehicleOption.fromJson(option))
          .toList(),
    );
  }
}

class VehicleOption {
  final VehicleType vehicleType;
  final double estimatedCost;
  final bool isAvailable;
  final double weightLimit;
  final PricingBreakdown breakdown;

  const VehicleOption({
    required this.vehicleType,
    required this.estimatedCost,
    required this.isAvailable,
    required this.weightLimit,
    required this.breakdown,
  });

  factory VehicleOption.fromJson(Map<String, dynamic> json) {
    return VehicleOption(
      vehicleType: VehicleType.fromString(json['vehicleType'] ?? 'FOUR_WHEELER'),
      estimatedCost: json['estimatedCost'] != null
          ? double.parse(json['estimatedCost'].toString())
          : 0.0,
      isAvailable: json['isAvailable'] ?? false,
      weightLimit: json['weightLimit'] != null
          ? double.parse(json['weightLimit'].toString())
          : 0.0,
      breakdown: PricingBreakdown.fromJson(json['breakdown'] ?? {}),
    );
  }
}

class PricingBreakdown {
  final double baseFare;
  final double distanceCharge;
  final double weightMultiplier;
  final double vehicleMultiplier;
  final double totalMultiplier;

  const PricingBreakdown({
    required this.baseFare,
    required this.distanceCharge,
    required this.weightMultiplier,
    required this.vehicleMultiplier,
    required this.totalMultiplier,
  });

  factory PricingBreakdown.fromJson(Map<String, dynamic> json) {
    return PricingBreakdown(
      baseFare: json['baseFare'] != null
          ? double.parse(json['baseFare'].toString())
          : 0.0,
      distanceCharge: json['distanceCharge'] != null
          ? double.parse(json['distanceCharge'].toString())
          : 0.0,
      weightMultiplier: json['weightMultiplier'] != null
          ? double.parse(json['weightMultiplier'].toString())
          : 1.0,
      vehicleMultiplier: json['vehicleMultiplier'] != null
          ? double.parse(json['vehicleMultiplier'].toString())
          : 1.0,
      totalMultiplier: json['totalMultiplier'] != null
          ? double.parse(json['totalMultiplier'].toString())
          : 1.0,
    );
  }
}