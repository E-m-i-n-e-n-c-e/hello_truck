import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';

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

  // Get address from coordinates
  Future<String> getAddressFromCoordinates(Position position) async {
    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );
      if (placemarks.isNotEmpty) {
        final placemark = placemarks.first;
        return '${placemark.name}, ${placemark.locality}, ${placemark.administrativeArea}';
      }
    } catch (e) {
      // Handle error silently
    }
    return 'Unknown location';
  }

  // Get address from LatLng
  Future<Map<String, dynamic>> getAddressFromLatLng(double latitude, double longitude) async {
    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(
        latitude,
        longitude,
      );

      if (placemarks.isNotEmpty) {
        final placemark = placemarks.first;

        return {
          'addressLine1': '${placemark.name}, ${placemark.subLocality}, ${placemark.locality}, ${placemark.administrativeArea}',
          'landmark': placemark.subLocality ?? '',
          'pincode': placemark.postalCode ?? '',
          'city': placemark.locality ??  '',
          'district': placemark.subAdministrativeArea ?? '',
          'state': placemark.administrativeArea ?? '',
          'latitude': latitude,
          'longitude': longitude,
          'fullAddress': '${placemark.name}, ${placemark.locality}, ${placemark.administrativeArea}',
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
      'fullAddress': 'Unknown location',
    };
  }
}