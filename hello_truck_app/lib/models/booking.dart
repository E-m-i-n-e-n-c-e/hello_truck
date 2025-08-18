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
      estimatedCost: json['estimatedCost']?.toDouble(),
      finalCost: json['finalCost']?.toDouble(),
      distanceKm: json['distanceKm']?.toDouble(),
      baseFare: json['baseFare']?.toDouble(),
      distanceCharge: json['distanceCharge']?.toDouble(),
      weightMultiplier: json['weightMultiplier']?.toDouble(),
      vehicleMultiplier: json['vehicleMultiplier']?.toDouble(),
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