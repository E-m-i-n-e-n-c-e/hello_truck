import 'enums/booking_enums.dart';
import 'package.dart';
import 'saved_address.dart';

class Booking {
  final String id;
  final int bookingNumber;
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
  final String? assignedDriverId;
  final Driver? assignedDriver;
  final DateTime? pickupArrivedAt;
  final DateTime? pickupVerifiedAt;
  final DateTime? dropArrivedAt;
  final DateTime? dropVerifiedAt;
  final DateTime? completedAt;
  final String? rzpOrderId;
  final String? rzpPaymentId;
  final String? rzpPaymentUrl;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? scheduledAt;

  const Booking({
    required this.id,
    required this.bookingNumber,
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
    this.assignedDriverId,
    this.assignedDriver,
    this.pickupArrivedAt,
    this.pickupVerifiedAt,
    this.dropArrivedAt,
    this.dropVerifiedAt,
    this.completedAt,
    this.rzpOrderId,
    this.rzpPaymentId,
    this.rzpPaymentUrl,
    required this.createdAt,
    required this.updatedAt,
    this.scheduledAt,
  });

  factory Booking.fromJson(Map<String, dynamic> json) {
    return Booking(
      id: json['id'],
      bookingNumber: json['bookingNumber'],
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
      assignedDriverId: json['assignedDriverId'],
      assignedDriver: json['assignedDriver'] != null ? Driver.fromJson(json['assignedDriver']) : null,
      pickupArrivedAt: json['pickupArrivedAt'] != null ? DateTime.parse(json['pickupArrivedAt']) : null,
      pickupVerifiedAt: json['pickupVerifiedAt'] != null ? DateTime.parse(json['pickupVerifiedAt']) : null,
      dropArrivedAt: json['dropArrivedAt'] != null ? DateTime.parse(json['dropArrivedAt']) : null,
      dropVerifiedAt: json['dropVerifiedAt'] != null ? DateTime.parse(json['dropVerifiedAt']) : null,
      completedAt: json['completedAt'] != null ? DateTime.parse(json['completedAt']) : null,
      rzpOrderId: json['rzpOrderId'],
      rzpPaymentId: json['rzpPaymentId'],
      rzpPaymentUrl: json['rzpPaymentUrl'],
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: DateTime.parse(json['updatedAt']),
      scheduledAt: json['scheduledAt'] != null
          ? DateTime.parse(json['scheduledAt'])
          : null,
    );
  }
}

class BookingAddress {
  final String? addressName;
  final String contactName;
  final String contactPhone;
  final String? noteToDriver;
  final String formattedAddress;
  final String addressDetails;
  final double latitude;
  final double longitude;

  BookingAddress({
    this.addressName,
    required this.contactName,
    required this.contactPhone,
    this.noteToDriver,
    required this.formattedAddress,
    required this.addressDetails,
    required this.latitude,
    required this.longitude,
  });

  factory BookingAddress.fromJson(Map<String, dynamic> json) {
    return BookingAddress(
      addressName: json['addressName'],
      contactName: json['contactName'],
      contactPhone: json['contactPhone'],
      noteToDriver: json['noteToDriver'],
      formattedAddress: json['formattedAddress'],
      addressDetails: json['addressDetails'],
      latitude: json['latitude'].toDouble(),
      longitude: json['longitude'].toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'addressName': addressName,
      'contactName': contactName,
      'contactPhone': contactPhone,
      'noteToDriver': noteToDriver,
      'formattedAddress': formattedAddress,
      'addressDetails': addressDetails,
      'latitude': latitude,
      'longitude': longitude,
    };
  }
}


class Driver {
  final String phoneNumber;
  final String? firstName;
  final String? lastName;
  final String? email;
  final String? photo;
  final int score;

  const Driver({
    required this.phoneNumber,
    this.firstName,
    this.lastName,
    this.email,
    this.photo,
    required this.score,
  });

  factory Driver.fromJson(Map<String, dynamic> json) {
    return Driver(
      phoneNumber: json['phoneNumber'],
      firstName: json['firstName'],
      lastName: json['lastName'],
      email: json['email'],
      photo: json['photo'],
      score: json['score'],
    );
  }
}

class DriverNavigationUpdate {
  final String bookingId;
  final int timeToPickup;
  final int timeToDrop;
  final int distanceToPickup;
  final int distanceToDrop;
  final Location? location;
  final String? routePolyline;
  bool isStale;
  final DateTime sentAt;

  DriverNavigationUpdate({
    required this.bookingId,
    required this.timeToPickup,
    required this.timeToDrop,
    required this.distanceToPickup,
    required this.distanceToDrop,
    required this.location,
    required this.routePolyline,
    this.isStale = false,
    required this.sentAt,
  });

  factory DriverNavigationUpdate.fromJson(Map<String, dynamic> json, {required String bookingId}) {
    return DriverNavigationUpdate(
      bookingId: json['bookingId'],
      timeToPickup: json['timeToPickup'],
      timeToDrop: json['timeToDrop'],
      distanceToPickup: json['distanceToPickup'],
      distanceToDrop: json['distanceToDrop'],
      location: json['location'] != null ? Location.fromJson(json['location']) : null,
      routePolyline: json['routePolyline'],
      sentAt: json['sentAt'] != null ? DateTime.parse(json['sentAt']) : DateTime.now(),

      // data is stale if the booking id is different from the current booking id
      isStale: bookingId != json['bookingId'],
    );
  }
}

class Location {
  final double latitude;
  final double longitude;

  Location({
    required this.latitude,
    required this.longitude,
  });

  factory Location.fromJson(Map<String, dynamic> json) {
    return Location(
      latitude: json['latitude']?.toDouble(),
      longitude: json['longitude']?.toDouble(),
    );
  }
}