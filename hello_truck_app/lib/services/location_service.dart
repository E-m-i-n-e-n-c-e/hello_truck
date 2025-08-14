import 'package:geolocator/geolocator.dart';
import 'package:hello_truck_app/services/google_places_service.dart';

enum LocationPermissionStatus {
  denied,
  deniedForever,
  granted,
  disabled,
}

class LocationService {
  static const LocationSettings _locationSettings = LocationSettings(
    accuracy: LocationAccuracy.high,
    distanceFilter: 5, // Update every 5 meters
  );

  // Stream of current position
  Stream<Position> get positionStream => Geolocator.getPositionStream(
        locationSettings: _locationSettings,
      );

  // Get current position once
  Future<Position> getCurrentPosition() async {
    return await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );
  }

  // Check and request location permissions
  Future<LocationPermissionStatus> checkAndRequestPermissions() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return LocationPermissionStatus.disabled;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return LocationPermissionStatus.denied;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      return LocationPermissionStatus.deniedForever;
    }

    return LocationPermissionStatus.granted;
  }

  // Get address from LatLng
  Future<Map<String, dynamic>> getAddressFromLatLng(double latitude, double longitude) async {
    try {
      final address = await GooglePlacesService.getAddressFromLatLng(latitude, longitude);

      if (address.isNotEmpty) {
        final addressParts = (address['formattedAddress'] ?? '').split(',');
        final addressLine1 = addressParts.length > 3
            ? addressParts.take(addressParts.length - 3).join(',').trim()
            : (address['formattedAddress'] ?? '').trim();
        return {
          'addressLine1': addressLine1,
          'landmark': address['sublocality'] ?? address['sublocalityLevel1'] ?? address['sublocalityLevel2'] ?? address['sublocalityLevel3'] ?? '',
          'pincode': address['postalCode'] ?? '',
          'city': address['locality'] ?? '',
          'district': address['administrativeAreaLevel2'] ?? address['administrativeAreaLevel3'] ?? '',
          'state': address['administrativeAreaLevel1'] ?? '',
          'country': address['country'] ?? '',
          'latitude': latitude,
          'longitude': longitude,
          'formattedAddress': address['formattedAddress'] ?? '',
        };
      }
    } catch (e) {
      // Handle error silently
    }

    // Return default values if geocoding fails
    return {
      'addressLine1': 'Unknown Address',
      'landmark': null,
      'pincode': '',
      'city': '',
      'district': '',
      'state': '',
      'latitude': latitude,
      'longitude': longitude,
      'formattedAddress': 'Unknown Address',
    };
  }
}