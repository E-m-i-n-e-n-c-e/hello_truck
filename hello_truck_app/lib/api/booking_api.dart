import 'package:hello_truck_app/auth/api.dart';
import 'package:hello_truck_app/models/booking.dart';
import 'package:hello_truck_app/models/booking_estimate.dart';
import 'package:hello_truck_app/models/cancellation_config.dart';
import 'package:hello_truck_app/models/package.dart';
import 'package:hello_truck_app/utils/constants.dart';
import 'package:hello_truck_app/utils/logger.dart';

/// Get booking estimate with all vehicle options
Future<BookingEstimate> getBookingEstimate(
  API api, {
  required BookingAddress pickupAddress,
  required BookingAddress dropAddress,
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
  required BookingAddress pickupAddress,
  required BookingAddress dropAddress,
  required Package package,
  String? gstNumber,
}) async {
  final response = await api.post('/bookings/customer', data: {
    'pickupAddress': {
      'addressName': pickupAddress.addressName,
      'contactName': pickupAddress.contactName,
      'contactPhone': pickupAddress.contactPhone,
      'noteToDriver': pickupAddress.noteToDriver,
      'formattedAddress': pickupAddress.formattedAddress,
      'addressDetails': pickupAddress.addressDetails,
      'latitude': pickupAddress.latitude,
      'longitude': pickupAddress.longitude,
    },
    'dropAddress': {
      'addressName': dropAddress.addressName,
      'contactName': dropAddress.contactName,
      'contactPhone': dropAddress.contactPhone,
      'noteToDriver': dropAddress.noteToDriver,
      'formattedAddress': dropAddress.formattedAddress,
      'addressDetails': dropAddress.addressDetails,
      'latitude': dropAddress.latitude,
      'longitude': dropAddress.longitude,
    },
    'package': package.toJson(),
    if (gstNumber != null) 'gstNumber': gstNumber,
  });

  return Booking.fromJson(response.data);
}

/// Stream live driver navigation updates for a specific booking (SSE)
Stream<Map<String, dynamic>> getDriverNavigationStream(API api, String bookingId) {
  final absoluteUrl = '$baseUrl/bookings/customer/driver-navigation/$bookingId';
  AppLogger.log('🚛 SSE connecting for booking $bookingId');
  return api.streamSseJson(absoluteUrl);
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

/// Get cancellation config
Future<CancellationConfig> getCancellationConfig(API api) async {
  final response = await api.get('/bookings/customer/cancellation-config');
  return CancellationConfig.fromJson(response.data);
}

/// Cancel a booking
Future<void> cancelBooking(API api, String bookingId, String reason) async {
  await api.post('/bookings/customer/cancel/$bookingId', data: {
    'reason': reason,
  });
}
