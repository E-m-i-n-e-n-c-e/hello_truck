import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hello_truck_app/api/booking_api.dart';
import 'package:hello_truck_app/models/booking.dart';
import 'package:hello_truck_app/models/booking_estimate.dart';
import 'package:hello_truck_app/models/package.dart';
import 'package:hello_truck_app/models/saved_address.dart';
import 'package:hello_truck_app/providers/auth_providers.dart';

// Provider for active bookings
final activeBookingsProvider = FutureProvider<List<Booking>>((ref) async {
  final api = await ref.read(apiProvider.future);
  return getActiveBookings(api);
});

// Provider for booking history
final bookingHistoryProvider = FutureProvider<List<Booking>>((ref) async {
  final api = await ref.read(apiProvider.future);
  return getBookingHistory(api);
});

// Provider for individual booking details
final bookingDetailsProvider = FutureProvider.autoDispose.family<Booking, String>((ref, bookingId) async {
  final api = await ref.read(apiProvider.future);
  return getBookingDetails(api, bookingId);
});

// Provider for booking estimate (already exists in estimate_screen.dart, but keeping it here for consistency)
final bookingEstimateProvider = FutureProvider.autoDispose.family<BookingEstimate, ({
  SavedAddress pickupAddress,
  SavedAddress dropAddress,
  Package package,
})>((ref, params) async {
  final api = await ref.read(apiProvider.future);
  return getBookingEstimate(
    api,
    pickupAddress: params.pickupAddress.address,
    dropAddress: params.dropAddress.address,
    package: params.package,
  );
});
