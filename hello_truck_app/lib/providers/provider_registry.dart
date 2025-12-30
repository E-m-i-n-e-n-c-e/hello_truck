import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hello_truck_app/providers/addresse_providers.dart';
import 'package:hello_truck_app/providers/booking_providers.dart';
import 'package:hello_truck_app/providers/customer_providers.dart';

/// Central registry of all data providers
/// Simple approach: Invalidate all when coming back online
class ProviderRegistry {
  /// All data providers that should be refreshed when network is restored
  static final List<ProviderOrFamily> allProviders = [
    // Booking providers
    activeBookingsProvider,
    bookingDetailsProvider,
    bookingHistoryProvider,
    cancellationConfigProvider,

    // Customer providers
    customerProvider,

    // Address providers
    savedAddressesProvider,
  ];

  /// Invalidate all data providers
  /// Call this when network is restored to fetch fresh data
  static void invalidateAll(dynamic ref) {
    for (final provider in allProviders) {
      ref.invalidate(provider);
    }
  }
}
