import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hello_truck_app/providers/auth_providers.dart';
import 'package:hello_truck_app/providers/booking_providers.dart';
import 'package:hello_truck_app/providers/customer_providers.dart';
import 'package:hello_truck_app/providers/fcm_providers.dart';
import 'package:hello_truck_app/providers/location_providers.dart';

import '../utils/logger.dart';

final appInitializerProvider = FutureProvider.autoDispose<void>((ref) async {
  final api = await ref.read(apiProvider.future);
  final fcmService = ref.read(fcmServiceProvider);
  await fcmService.initialize(api);

  // There are currently no FutureProviders to eagerly initialize in the customer app.
  final futureProvidersToEagerInit = [
    customerProvider,
    gstDetailsProvider,
    activeBookingsProvider,
    bookingHistoryProvider,
  ];

  // Only the FCM event stream needs eager initialization for now.
  final List<StreamProvider<Object>> streamProvidersToEagerInit = [
    fcmEventStreamProvider,
    currentPositionStreamProvider,
  ];

  final List<ProviderListenable> providersToEagerInit = [
    ...futureProvidersToEagerInit,
    ...streamProvidersToEagerInit,
  ];

  for (final provider in providersToEagerInit) {
    ref.read(provider);
  }

  ref.onDispose(() {
    AppLogger.log('AppInitializerProvider disposed');
    for (final provider in providersToEagerInit) {
      ref.invalidate(provider as ProviderOrFamily);
    }
    fcmService.stop();
  });
});
