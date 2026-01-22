import 'package:equatable/equatable.dart';
import 'package:hello_truck_app/models/enums/invoice_enums.dart';

import 'enums/booking_enums.dart';
import 'package.dart';
import 'saved_address.dart';
import 'invoice.dart';
import 'booking_estimate.dart';

class Booking {
  final String id;
  final int bookingNumber;
  final Package package;
  final BookingAddress pickupAddress;
  final BookingAddress dropAddress;
  final String? pickupOtp;
  final String? dropOtp;
  final List<Invoice> invoices;
  final BookingStatus status;
  final Driver? assignedDriver;
  final DateTime? acceptedAt;
  final DateTime? pickupArrivedAt;
  final DateTime? pickupVerifiedAt;
  final DateTime? dropArrivedAt;
  final DateTime? dropVerifiedAt;
  final DateTime? completedAt;
  final DateTime? cancelledAt;
  final String? cancellationReason;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? scheduledAt;

  const Booking({
    required this.id,
    required this.bookingNumber,
    required this.package,
    required this.pickupAddress,
    required this.dropAddress,
    this.pickupOtp,
    this.dropOtp,
    required this.invoices,
    required this.status,
    this.assignedDriver,
    this.acceptedAt,
    this.pickupArrivedAt,
    this.pickupVerifiedAt,
    this.dropArrivedAt,
    this.dropVerifiedAt,
    this.completedAt,
    this.cancelledAt,
    this.cancellationReason,
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
      pickupOtp: json['pickupOtp'],
      dropOtp: json['dropOtp'],
      invoices: (json['invoices'] as List<dynamic>?)
              ?.map((invoice) => Invoice.fromJson(invoice))
              .toList() ??
          [],
      status: bookingStatus,
      assignedDriver: assignedDriver,
      acceptedAt: json['acceptedAt'] != null ? DateTime.parse(json['acceptedAt']) : null,
      pickupArrivedAt: json['pickupArrivedAt'] != null ? DateTime.parse(json['pickupArrivedAt']) : null,
      pickupVerifiedAt: json['pickupVerifiedAt'] != null ? DateTime.parse(json['pickupVerifiedAt']) : null,
      dropArrivedAt: json['dropArrivedAt'] != null ? DateTime.parse(json['dropArrivedAt']) : null,
      dropVerifiedAt: json['dropVerifiedAt'] != null ? DateTime.parse(json['dropVerifiedAt']) : null,
      completedAt: json['completedAt'] != null ? DateTime.parse(json['completedAt']) : null,
      cancelledAt: json['cancelledAt'] != null ? DateTime.parse(json['cancelledAt']) : null,
      cancellationReason: json['cancellationReason'],
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: DateTime.parse(json['updatedAt']),
      scheduledAt: json['scheduledAt'] != null
          ? DateTime.parse(json['scheduledAt'])
          : null,
    );
  }

    /// Get the estimate invoice if available
  Invoice? get estimateInvoice {
    if (invoices.isEmpty) return null;
    try {
      return invoices.firstWhere((inv) => inv.type == InvoiceType.estimate);
    } catch (_) {
      return null;
    }
  }

  /// Get the final invoice if available
  Invoice? get finalInvoice {
    if (invoices.isEmpty) return null;
    try {
      return invoices.firstWhere((inv) => inv.type == InvoiceType.final_);
    } catch (_) {
      return null;
    }
  }

  String get idealVehicle => estimateInvoice?.vehicleModelName ?? finalInvoice?.vehicleModelName ?? '';

  String? get assignedVehicle => finalInvoice?.vehicleModelName;

  /// Get estimated cost from estimate invoice
  double get estimatedCost => estimateInvoice?.totalPrice ?? finalInvoice?.totalPrice ?? 0.0;

  /// Get final cost from final invoice
  double? get finalCost => finalInvoice?.finalAmount;

  /// Get the distance from the final invoice or estimate
  double get distanceKm => finalInvoice?.distanceKm ?? estimateInvoice?.distanceKm ?? 0.0;
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
      latitude: json['latitude']?.toDouble(),
      longitude: json['longitude']?.toDouble(),
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

/// Generic class to represent updates made during the booking flow
/// Used to pass updated data back through the navigation stack
class BookingUpdate {
  final BookingAddress? pickupAddress;
  final BookingAddress? dropAddress;
  final Package? package;
  final BookingEstimate? estimate;

  const BookingUpdate({
    this.pickupAddress,
    this.dropAddress,
    this.package,
    this.estimate,
  });

  /// Check if any field was updated
  bool get hasUpdates =>
      pickupAddress != null ||
      dropAddress != null ||
      package != null ||
      estimate != null;

  /// Create a copy with updated fields
  BookingUpdate copyWith({
    BookingAddress? pickupAddress,
    BookingAddress? dropAddress,
    Package? package,
    BookingEstimate? estimate,
  }) {
    return BookingUpdate(
      pickupAddress: pickupAddress ?? this.pickupAddress,
      dropAddress: dropAddress ?? this.dropAddress,
      package: package ?? this.package,
      estimate: estimate ?? this.estimate,
    );
  }
}