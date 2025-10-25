import 'package:hello_truck_app/utils/logger.dart';
import 'package:http/http.dart' as http;
import 'package:uuid/uuid.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'dart:convert';
import '../models/place_prediction.dart';

class GooglePlacesService {
  static const String _googleApiKey = 'AIzaSyBS1YvHqfQSiiBb5d6FgrXtPRi_3VGiSMM';
  static const String _baseUrl = 'https://places.googleapis.com/v1';
  static String? _sessionToken;

  static void clearSessionToken() {
    _sessionToken = null;
  }

  // Google Places API search using new Autocomplete API
  static Future<List<PlacePrediction>> searchPlaces(String query, {LatLng? location, double radius = 5000.0}) async {
    if (query.isEmpty) return [];

    _sessionToken ??= const Uuid().v4();

    final String url = '$_baseUrl/places:autocomplete';

    final Map<String, dynamic> requestBody = {
      'input': query,
      'includedRegionCodes': ['in'], // Restrict to India
      'sessionToken': _sessionToken,
    };

    if(location != null) {
      requestBody['locationBias'] = {
        'circle': {
          'center': {
            'latitude': location.latitude,
            'longitude': location.longitude,
          },
          'radius': radius,
        },
      };
    }

    try {
      final response = await http.post(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'X-Goog-Api-Key': _googleApiKey,
          'X-Goog-FieldMask': 'suggestions.placePrediction.text.text,suggestions.placePrediction.placeId,suggestions.placePrediction.structuredFormat.mainText.text',
        },
        body: json.encode(requestBody),
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        if (data.containsKey('suggestions')) {
          final List<dynamic> suggestions = data['suggestions'];
          return suggestions
              .where((suggestion) => suggestion.containsKey('placePrediction'))
              .map((suggestion) => PlacePrediction.fromJson(suggestion))
              .toList();
        }
      }
    } catch (e) {
      AppLogger.log('Error searching places: $e');
    }
    return [];
  }

  // Get place details from place ID using new Places API
  static Future<LatLng?> getPlaceDetails(String placeId) async {
    // Generate a session token if missing to ensure compliance
    _sessionToken ??= const Uuid().v4();

    final String url = '$_baseUrl/places/$placeId?sessionToken=$_sessionToken';

    try {
      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'X-Goog-Api-Key': _googleApiKey,
          'X-Goog-FieldMask': 'id,formattedAddress,location',
        },
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        if (data.containsKey('location')) {
          final location = data['location'];
          return LatLng(location['latitude'], location['longitude']);
        }
      }
    } catch (e) {
      AppLogger.log('Error getting place details: $e');
    } finally {
      // Clear session token after request is complete
      clearSessionToken();
    }

    return null;
  }

    /// Helper method to extract address component
  static String? _extractAddressComponent(List components, String type) {
    try {
      return components
          .firstWhere((c) => (c['types'] as List).contains(type))['long_name'];
    } catch (_) {
      return null;
    }
  }

  /// Reverse geocode LatLng into a structured address
  static Future<Map<String, dynamic>> getAddressFromLatLng(
      double latitude, double longitude) async {
    final String url =
        'https://maps.googleapis.com/maps/api/geocode/json?'
        'latlng=$latitude,$longitude&'
        'key=$_googleApiKey';

    final response = await http.get(Uri.parse(url));
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      if (data['status'] == 'OK' && data['results'].isNotEmpty) {
        final result = data['results'][0];
        final components = result['address_components'];

        return {
          'sublocality': _extractAddressComponent(components, 'sublocality'),
          'sublocalityLevel1': _extractAddressComponent(components, 'sublocality_level_1'),
          'sublocalityLevel2': _extractAddressComponent(components, 'sublocality_level_2'),
          'sublocalityLevel3': _extractAddressComponent(components, 'sublocality_level_3'),
          'postalCode': _extractAddressComponent(components, 'postal_code'),
          'locality': _extractAddressComponent(components, 'locality'),
          'administrativeAreaLevel2': _extractAddressComponent(components, 'administrative_area_level_2'),
          'administrativeAreaLevel3': _extractAddressComponent(components, 'administrative_area_level_3'),
          'administrativeAreaLevel1': _extractAddressComponent(components, 'administrative_area_level_1'),
          'country': _extractAddressComponent(components, 'country'),
          'latitude': latitude,
          'longitude': longitude,
          'formattedAddress': result['formatted_address'],
        };
      }
    }
    return {};
  }

  // Get route polyline between two points
  static Future<List<LatLng>?> getRoutePolyline(LatLng origin, LatLng destination) async {
    final String url = 'https://maps.googleapis.com/maps/api/directions/json?'
        'origin=${origin.latitude},${origin.longitude}&'
        'destination=${destination.latitude},${destination.longitude}&'
        'key=$_googleApiKey';

    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        if (data['status'] == 'OK' && data['routes'].isNotEmpty) {
          final String encodedPolyline = data['routes'][0]['overview_polyline']['points'];
          final PolylinePoints polylinePoints = PolylinePoints();
          final List<PointLatLng> result = polylinePoints.decodePolyline(encodedPolyline);

          return result
              .map((point) => LatLng(point.latitude, point.longitude))
              .toList();
        }
      }
    } catch (e) {
      AppLogger.log('Error getting route polyline: $e');
    }
    return null;
  }
}