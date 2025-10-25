import 'package:equatable/equatable.dart';

import 'enums/booking_enums.dart';
import 'package.dart';
import 'saved_address.dart';

class Booking {
  final String id;
  final int bookingNumber;
  final Package package;
  final BookingAddress pickupAddress;
  final BookingAddress dropAddress;
  final double estimatedCost;
  final double? finalCost;
  final double distanceKm;
  final double baseFare;
  final double distanceCharge;
  final double weightMultiplier;
  final double vehicleMultiplier;
  final VehicleType suggestedVehicleType;
  final BookingStatus status;
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
    final bookingStatus = BookingStatus.fromString(json['status'] ?? 'PENDING');
    // Hold off on showing driver until the booking is confirmed(driver accepts ride)
    final shouldShowDriver = bookingStatus != BookingStatus.driverAssigned && json['assignedDriver'] != null;
    final assignedDriver = shouldShowDriver ? Driver.fromJson(json['assignedDriver']) : null;
    return Booking(
      id: json['id'],
      bookingNumber: json['bookingNumber'],
      package: Package.fromJson(json['package']),
      pickupAddress: BookingAddress.fromJson(json['pickupAddress']),
      dropAddress: BookingAddress.fromJson(json['dropAddress']),
      estimatedCost: json['estimatedCost']?.toDouble(),
      finalCost: json['finalCost']?.toDouble(),
      distanceKm: json['distanceKm']?.toDouble(),
      baseFare: json['baseFare']?.toDouble(),
      distanceCharge: json['distanceCharge']?.toDouble(),
      weightMultiplier: json['weightMultiplier']?.toDouble(),
      vehicleMultiplier: json['vehicleMultiplier']?.toDouble(),
      suggestedVehicleType: VehicleType.fromString(json['suggestedVehicleType'] ?? 'FOUR_WHEELER'),
      status: bookingStatus,
      assignedDriver: assignedDriver,
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

class BookingAddress extends Equatable {
  final String? addressName;
  final String contactName;
  final String contactPhone;
  final String? noteToDriver;
  final String formattedAddress;
  final String? addressDetails;
  final double latitude;
  final double longitude;

  const BookingAddress({
    this.addressName,
    required this.contactName,
    required this.contactPhone,
    this.noteToDriver,
    required this.formattedAddress,
    this.addressDetails,
    required this.latitude,
    required this.longitude,
  });

  @override
  List<Object?> get props => [
    addressName,
    contactName,
    contactPhone,
    noteToDriver,
    formattedAddress,
    addressDetails,
    latitude,
    longitude,
  ];


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

  factory BookingAddress.fromSavedAddress(SavedAddress savedAddress) {
    return BookingAddress(
      addressName: savedAddress.name,
      contactName: savedAddress.contactName,
      contactPhone: savedAddress.contactPhone,
      noteToDriver: savedAddress.noteToDriver,
      formattedAddress: savedAddress.address.formattedAddress,
      addressDetails: savedAddress.address.addressDetails,
      latitude: savedAddress.address.latitude,
      longitude: savedAddress.address.longitude,
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
  final String firstName;
  final String? lastName;
  final String? email;
  final String? photo;
  final int score;

  const Driver({
    required this.phoneNumber,
    required this.firstName,
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