import 'enums/booking_enums.dart';
import 'package.dart';
import 'saved_address.dart';

class Booking {
  final String id;
  final Package package;
  final Address pickupAddress;
  final Address dropAddress;
  final double estimatedCost;
  final double? finalCost;
  final double distanceKm;
  final double baseFare;
  final double distanceCharge;
  final double weightMultiplier;
  final double vehicleMultiplier;
  final VehicleType suggestedVehicleType;
  final BookingStatus status;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? scheduledAt;

  const Booking({
    required this.id,
    required this.package,
    required this.pickupAddress,
    required this.dropAddress,
    required this.estimatedCost,
    this.finalCost,
    required this.distanceKm,
    required this.baseFare,
    required this.distanceCharge,
    required this.weightMultiplier,
    required this.vehicleMultiplier,
    required this.suggestedVehicleType,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
    this.scheduledAt,
  });

  factory Booking.fromJson(Map<String, dynamic> json) {
    return Booking(
      id: json['id'],
      package: Package.fromJson(json['package']),
      pickupAddress: Address.fromJson(json['pickupAddress']),
      dropAddress: Address.fromJson(json['dropAddress']),
      estimatedCost: json['estimatedCost'] != null
          ? double.parse(json['estimatedCost'].toString())
          : 0.0,
      finalCost: json['finalCost'] != null
          ? double.parse(json['finalCost'].toString())
          : null,
      distanceKm: json['distanceKm'] != null
          ? double.parse(json['distanceKm'].toString())
          : 0.0,
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
      suggestedVehicleType: VehicleType.fromString(json['suggestedVehicleType'] ?? 'FOUR_WHEELER'),
      status: BookingStatus.fromString(json['status'] ?? 'PENDING'),
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: DateTime.parse(json['updatedAt']),
      scheduledAt: json['scheduledAt'] != null
          ? DateTime.parse(json['scheduledAt'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'package': package.toJson(),
      'pickupAddress': pickupAddress.toJson(),
      'dropAddress': dropAddress.toJson(),
      'estimatedCost': estimatedCost,
      'finalCost': finalCost,
      'distanceKm': distanceKm,
      'baseFare': baseFare,
      'distanceCharge': distanceCharge,
      'weightMultiplier': weightMultiplier,
      'vehicleMultiplier': vehicleMultiplier,
      'suggestedVehicleType': suggestedVehicleType.value,
      'status': status.value,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'scheduledAt': scheduledAt?.toIso8601String(),
    };
  }
}

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