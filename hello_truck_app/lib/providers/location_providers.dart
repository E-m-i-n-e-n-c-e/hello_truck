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
    try {
      // Get initial position
      final initialPosition = await locationService.getCurrentPosition();
      yield initialPosition;

      // Stream of current position
      yield* locationService.positionStream;
    } catch (e) {
      while (true) {
        await Future.delayed(const Duration(seconds: 1));
        try {
          final retryPosition = await locationService.getCurrentPosition();
          yield retryPosition;
          yield* locationService.positionStream;
          break; // Break loop if successful
        } catch (e) {
          // Continue loop if error occurs
          continue;
        }
      }
    }
});