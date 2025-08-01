import 'package:http/http.dart' as http;
import 'package:uuid/uuid.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'dart:convert';
import '../models/place_prediction.dart';

class GooglePlacesService {
  static const String _googleApiKey = 'AIzaSyBqTOs9JWbrHqOIO10oGKpLhuvou37S6Aw';

  // Google Places API search
  static Future<List<PlacePrediction>> searchPlaces(String query) async {
    if (query.isEmpty) return [];

    final String sessionToken = const Uuid().v4();
    final String url = 'https://maps.googleapis.com/maps/api/place/autocomplete/json?'
        'input=${Uri.encodeComponent(query)}&'
        'key=$_googleApiKey&'
        'sessiontoken=$sessionToken&'
        'components=country:in'; // Restrict to India

    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        if (data['status'] == 'OK') {
          final List<dynamic> predictions = data['predictions'];
          return predictions
              .map((prediction) => PlacePrediction.fromJson(prediction))
              .toList();
        }
      }
    } catch (e) {
      print('Error searching places: $e');
    }
    return [];
  }

  // Get place details from place ID
  static Future<LatLng?> getPlaceDetails(String placeId) async {
    final String url = 'https://maps.googleapis.com/maps/api/place/details/json?'
        'place_id=$placeId&'
        'fields=geometry&'
        'key=$_googleApiKey';

    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        if (data['status'] == 'OK') {
          final location = data['result']['geometry']['location'];
          return LatLng(location['lat'], location['lng']);
        }
      }
    } catch (e) {
      print('Error getting place details: $e');
    }
    return null;
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
      print('Error getting route polyline: $e');
    }
    return null;
  }
}