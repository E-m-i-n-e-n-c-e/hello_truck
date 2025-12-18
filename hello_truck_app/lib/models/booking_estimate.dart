class BookingEstimate {
  final double distanceKm;
  final String idealVehicleModel;
  final List<VehicleOption> topVehicles;

  const BookingEstimate({
    required this.distanceKm,
    required this.idealVehicleModel,
    required this.topVehicles,
  });

  factory BookingEstimate.fromJson(Map<String, dynamic> json) {
    return BookingEstimate(
      distanceKm: json['distanceKm'] != null
          ? double.parse(json['distanceKm'].toString())
          : 0.0,
      idealVehicleModel: json['idealVehicleModel'] ?? '',
      topVehicles: (json['topVehicles'] as List<dynamic>)
          .map((option) => VehicleOption.fromJson(option))
          .toList(),
    );
  }
}

class VehicleOption {
  final String vehicleModelName;
  final double estimatedCost;
  final double maxWeightTons;
  final PricingBreakdown breakdown;

  const VehicleOption({
    required this.vehicleModelName,
    required this.estimatedCost,
    required this.maxWeightTons,
    required this.breakdown,
  });

  factory VehicleOption.fromJson(Map<String, dynamic> json) {
    return VehicleOption(
      vehicleModelName: json['vehicleModelName'] ?? '',
      estimatedCost: json['estimatedCost'] != null
          ? double.parse(json['estimatedCost'].toString())
          : 0.0,
      maxWeightTons: json['maxWeightTons'] != null
          ? double.parse(json['maxWeightTons'].toString())
          : 0.0,
      breakdown: PricingBreakdown.fromJson(json['breakdown'] ?? {}),
    );
  }
}

class PricingBreakdown {
  final double baseFare;
  final int baseKm;
  final double perKm;
  final double distanceKm;
  final double weightInTons;
  final double effectiveBasePrice;

  const PricingBreakdown({
    required this.baseFare,
    required this.baseKm,
    required this.perKm,
    required this.distanceKm,
    required this.weightInTons,
    required this.effectiveBasePrice,
  });

  factory PricingBreakdown.fromJson(Map<String, dynamic> json) {
    return PricingBreakdown(
      baseFare: json['baseFare'] != null
          ? double.parse(json['baseFare'].toString())
          : 0.0,
      baseKm: json['baseKm'] ?? 0,
      perKm: json['perKm'] != null
          ? double.parse(json['perKm'].toString())
          : 0.0,
      distanceKm: json['distanceKm'] != null
          ? double.parse(json['distanceKm'].toString())
          : 0.0,
      weightInTons: json['weightInTons'] != null
          ? double.parse(json['weightInTons'].toString())
          : 0.0,
      effectiveBasePrice: json['effectiveBasePrice'] != null
          ? double.parse(json['effectiveBasePrice'].toString())
          : 0.0,
    );
  }
}