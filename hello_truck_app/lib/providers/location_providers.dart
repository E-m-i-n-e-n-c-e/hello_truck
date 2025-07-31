import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:hello_truck_app/services/location_service.dart';

// Location service provider
final locationServiceProvider = Provider<LocationService>((ref) {
  return LocationService();
});

// Real-time position stream provider
final currentPositionStreamProvider = StreamProvider<Position>((ref) async* {
  final locationService = ref.watch(locationServiceProvider);

  Position? initialPosition;

  while (initialPosition == null) {
    try {
      initialPosition = await locationService.getCurrentPosition();
    } catch (_) {
      await Future.delayed(const Duration(seconds: 1));
    }
  }

  yield initialPosition;
  yield* locationService.positionStream;
});