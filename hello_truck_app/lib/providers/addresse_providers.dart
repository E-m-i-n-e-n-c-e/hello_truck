import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hello_truck_app/api/address_api.dart';
import 'package:hello_truck_app/models/saved_address.dart';
import 'package:hello_truck_app/providers/auth_providers.dart';
import 'package:hello_truck_app/services/recent_addresses_service.dart';

final recentAddressesServiceProvider = Provider<RecentAddressesService>((ref) {
  final service = RecentAddressesService();
  return service;
});

final recentAddressesProvider = FutureProvider<List<SavedAddress>>((ref) async {
  final service = ref.watch(recentAddressesServiceProvider);
  // Always return latest 5
  return service.getRecentAddresses(limit: 5);
});

final savedAddressesProvider = FutureProvider<List<SavedAddress>>((ref) async {
  final api = await ref.watch(apiProvider.future);
  return getSavedAddresses(api);
});

