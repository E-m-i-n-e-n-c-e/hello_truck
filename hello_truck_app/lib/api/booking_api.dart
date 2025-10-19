import 'package:hello_truck_app/auth/api.dart';
import 'package:hello_truck_app/models/booking.dart';
import 'package:hello_truck_app/models/booking_estimate.dart';
import 'package:hello_truck_app/models/package.dart';
import 'package:hello_truck_app/models/saved_address.dart';
import 'package:hello_truck_app/models/enums/booking_enums.dart';

/// Get booking estimate with all vehicle options
Future<BookingEstimate> getBookingEstimate(
  API api, {
  required Address pickupAddress,
  required Address dropAddress,
  required Package package,
}) async {
  final response = await api.post('/bookings/customer/estimate', data: {
    'pickupAddress': pickupAddress.toJson(),
    'dropAddress': dropAddress.toJson(),
    'packageDetails': package.toJson(),
  });

  return BookingEstimate.fromJson(response.data);
}

/// Create a new booking
Future<Booking> createBooking(
  API api, {
  required SavedAddress pickupAddress,
  required SavedAddress dropAddress,
  required Package package,
  required VehicleType selectedVehicleType,
}) async {
  final response = await api.post('/bookings/customer', data: {
    'pickupAddress': {
      'addressName': pickupAddress.name,
      'contactName': pickupAddress.contactName,
      'contactPhone': pickupAddress.contactPhone,
      'noteToDriver': pickupAddress.noteToDriver,
      'formattedAddress': pickupAddress.address.formattedAddress,
      'addressDetails': pickupAddress.address.addressDetails,
      'latitude': pickupAddress.address.latitude,
      'longitude': pickupAddress.address.longitude,
    },
    'dropAddress': {
      'addressName': dropAddress.name,
      'contactName': dropAddress.contactName,
      'contactPhone': dropAddress.contactPhone,
      'noteToDriver': dropAddress.noteToDriver,
      'formattedAddress': dropAddress.address.formattedAddress,
      'addressDetails': dropAddress.address.addressDetails,
      'latitude': dropAddress.address.latitude,
      'longitude': dropAddress.address.longitude,
    },
    'package': package.toJson(),
    'selectedVehicleType': selectedVehicleType.value,
  });

  return Booking.fromJson(response.data);
}

Future<Booking> getBookingDetails(API api, String bookingId) async {
  final response = await api.get('/bookings/customer/$bookingId');
  return Booking.fromJson(response.data);
}

Future<List<Booking>> getBookingHistory(API api) async {
  final response = await api.get('/bookings/customer/history');
  return (response.data as List).map((json) => Booking.fromJson(json)).toList();
}

Future<List<Booking>> getActiveBookings(API api) async {
  final response = await api.get('/bookings/customer/active');
  return (response.data as List).map((json) => Booking.fromJson(json)).toList();
}

/// Cancel a booking
Future<void> cancelBooking(API api, String bookingId) async {
  await api.delete('/bookings/customer/$bookingId');
}

/// Update a booking
Future<Booking> updateBooking(
  API api,
  String bookingId, {
  Address? dropAddress,
  Package? package,
}) async {
  final body = <String, dynamic>{};
  if (dropAddress != null) {
    body['dropAddress'] = dropAddress.toJson();
  }
  if (package != null) {
    body['package'] = package.toJson();
  }

  final response = await api.put('/bookings/customer/$bookingId', data: body);
  return Booking.fromJson(response.data);
}