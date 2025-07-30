import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:hello_truck_app/services/location_service.dart';
import 'package:http/http.dart' as http;
import 'package:uuid/uuid.dart';
import 'dart:convert';
import 'package:hello_truck_app/providers/location_providers.dart';

// Model for Google Places prediction
class PlacePrediction {
  final String description;
  final String placeId;
  final String? structuredFormat;

  PlacePrediction({
    required this.description,
    required this.placeId,
    this.structuredFormat,
  });

  factory PlacePrediction.fromJson(Map<String, dynamic> json) {
    return PlacePrediction(
      description: json['description'] ?? '',
      placeId: json['place_id'] ?? '',
      structuredFormat: json['structured_formatting']?['main_text'],
    );
  }
}

class MapScreen extends ConsumerStatefulWidget {
  const MapScreen({super.key});

  @override
  ConsumerState<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends ConsumerState<MapScreen> with TickerProviderStateMixin {
  GoogleMapController? _mapController;
  LatLng? _deliveryLocation;
  final Set<Marker> _markers = {};
  final Set<Polyline> _polylines = {};
  bool _isLoading = true;
  String _pickupAddress = '';
  String? _deliveryAddress;
  int _selectedVehicleIndex = 1;
  bool _showVehiclePanel = false;

  // Google API key
  final String _googleApiKey = 'AIzaSyBqTOs9JWbrHqOIO10oGKpLhuvou37S6Aw';

  // Panel animation
  late AnimationController _panelController;
  double _panelHeight = 0.3;
  final double _minPanelHeight = 0.3;
  final double _maxPanelHeight = 0.8;

  // Vehicle options
  final List<Map<String, dynamic>> _vehicles = [
    {
      'name': 'Bike',
      'description': 'Quick delivery for small items',
      'price': '₹45',
      'time': '2-5 min',
      'capacity': 'Up to 5kg',
      'icon': Icons.motorcycle,
      'gradient': [Color(0xFF4CAF50), Color(0xFF66BB6A)],
    },
    {
      'name': 'Small Van',
      'description': 'Perfect for medium packages',
      'price': '₹120',
      'time': '5-10 min',
      'capacity': 'Up to 50kg',
      'icon': Icons.airport_shuttle,
      'gradient': [Color(0xFF22AAAE), Color(0xFF26C6DA)],
    },
    {
      'name': 'Pickup Truck',
      'description': 'Large items & furniture',
      'price': '₹250',
      'time': '10-15 min',
      'capacity': 'Up to 500kg',
      'icon': Icons.local_shipping,
      'gradient': [Color(0xFFFF9800), Color(0xFFFFB74D)],
    },
    {
      'name': 'Large Truck',
      'description': 'Heavy goods & bulk items',
      'price': '₹450',
      'time': '15-25 min',
      'capacity': 'Up to 2000kg',
      'icon': Icons.fire_truck,
      'gradient': [Color(0xFFE91E63), Color(0xFFF48FB1)],
    },
  ];

  @override
  void initState() {
    super.initState();
    _panelController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _getCurrentLocation();
  }

  @override
  void dispose() {
    _panelController.dispose();
    super.dispose();
  }

  // Google Places API search
  Future<List<PlacePrediction>> _searchPlaces(String query) async {
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
      debugPrint('Error searching places: $e');
    }
    return [];
  }

  // Get place details from place ID
  Future<LatLng?> _getPlaceDetails(String placeId) async {
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
      debugPrint('Error getting place details: $e');
    }
    return null;
  }

  // Get route polyline between two points
  Future<void> _getRoutePolyline() async {
    final currentPosition = ref.read(currentPositionStreamProvider).value;
    if (currentPosition == null || _deliveryLocation == null) return;

    try {
      final String url = 'https://maps.googleapis.com/maps/api/directions/json?'
          'origin=${currentPosition.latitude},${currentPosition.longitude}&'
          'destination=${_deliveryLocation!.latitude},${_deliveryLocation!.longitude}&'
          'key=$_googleApiKey';

      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);

        if (data['status'] == 'OK' && data['routes'].isNotEmpty) {
          final String encodedPolyline = data['routes'][0]['overview_polyline']['points'];
          final PolylinePoints polylinePoints = PolylinePoints();
          final List<PointLatLng> result = polylinePoints.decodePolyline(encodedPolyline);

          final List<LatLng> polylineCoordinates = result
              .map((point) => LatLng(point.latitude, point.longitude))
              .toList();

          setState(() {
            _polylines.clear();
            _polylines.add(
              Polyline(
                polylineId: const PolylineId('route'),
                points: polylineCoordinates,
                color: const Color(0xFF22AAAE),
                width: 5,
                patterns: [PatternItem.dash(20), PatternItem.gap(10)],
              ),
            );
          });

          _fitMarkersInView();
        }
      }
    } catch (e) {
      debugPrint('Error getting route: $e');
    }
  }

  void _fitMarkersInView() {
    final currentPosition = ref.read(currentPositionStreamProvider).value;
    if (_mapController == null || currentPosition == null || _deliveryLocation == null) return;

    final LatLngBounds bounds = LatLngBounds(
      southwest: LatLng(
        currentPosition.latitude < _deliveryLocation!.latitude
            ? currentPosition.latitude
            : _deliveryLocation!.latitude,
        currentPosition.longitude < _deliveryLocation!.longitude
            ? currentPosition.longitude
            : _deliveryLocation!.longitude,
      ),
      northeast: LatLng(
        currentPosition.latitude > _deliveryLocation!.latitude
            ? currentPosition.latitude
            : _deliveryLocation!.latitude,
        currentPosition.longitude > _deliveryLocation!.longitude
            ? currentPosition.longitude
            : _deliveryLocation!.longitude,
      ),
    );

    _mapController!.animateCamera(
      CameraUpdate.newLatLngBounds(bounds, 100.0),
    );
  }

  Future<void> _getCurrentLocation() async {
    try {
      final permission = await ref.read(locationServiceProvider).checkAndRequestPermissions();
      if (permission == LocationPermissionStatus.disabled) {
        _showLocationServiceDisabledDialog();
        return;
      }

      if (permission == LocationPermissionStatus.denied) {
        _showPermissionDeniedDialog();
        return;
      }

      if (permission == LocationPermissionStatus.deniedForever) {
        _showPermissionDeniedForeverDialog();
        return;
      }

      Position position = await ref.read(currentPositionStreamProvider.future);

      Map<String, dynamic> pickupAddr = await ref.read(locationServiceProvider).getAddressFromLatLng(
        position.latitude,
        position.longitude,
      );

      setState(() {
        _pickupAddress = pickupAddr['fullAddress'];
        _isLoading = false;
        _markers.add(
          Marker(
            markerId: const MarkerId('pickup_location'),
            position: LatLng(position.latitude, position.longitude),
            infoWindow: InfoWindow(
              title: 'Pickup Location',
              snippet: _pickupAddress,
            ),
            icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
          ),
        );
      });

      _adjustMapZoom();
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      _showErrorDialog('Error getting location: $e');
    }
  }

  void _adjustMapZoom() {
    final currentPosition = ref.read(currentPositionStreamProvider).value;
    if (_mapController == null || currentPosition == null) return;

    _mapController!.animateCamera(
      CameraUpdate.newLatLngZoom(
        LatLng(currentPosition.latitude, currentPosition.longitude),
        15.0,
      ),
    );
  }

  void _onMapTapped(LatLng location) async {
    final locationService = ref.read(locationServiceProvider);
    Map<String, dynamic> address = await locationService.getAddressFromLatLng(location.latitude, location.longitude);

    setState(() {
      _deliveryLocation = location;
      _deliveryAddress = address['fullAddress'];

      _markers.removeWhere((marker) => marker.markerId.value == 'delivery_location');
      _markers.add(
        Marker(
          markerId: const MarkerId('delivery_location'),
          position: location,
          infoWindow: InfoWindow(
            title: 'Delivery Location',
            snippet: _deliveryAddress!,
          ),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
        ),
      );

      _showVehiclePanel = true;
    });

    await _getRoutePolyline();
  }

  // Enhanced address input dialog with working Google Places
  void _showAddressInputDialog(bool isPickup) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => AddressSearchWidget(
        isPickup: isPickup,
        googleApiKey: _googleApiKey,
        currentAddress: isPickup ? _pickupAddress : (_deliveryAddress ?? ''),
        onLocationSelected: (LatLng location, String address) {
          if (isPickup) {
            _updatePickupLocation(location, address);
          } else {
            _updateDeliveryLocation(location, address);
          }
        },
        searchPlaces: _searchPlaces,
        getPlaceDetails: _getPlaceDetails,
      ),
    );
  }

  Future<void> _updatePickupLocation(LatLng location, String address) async {
    setState(() {
      _pickupAddress = address;

      _markers.removeWhere((marker) => marker.markerId.value == 'pickup_location');
      _markers.add(
        Marker(
          markerId: const MarkerId('pickup_location'),
          position: location,
          infoWindow: InfoWindow(
            title: 'Pickup Location',
            snippet: _pickupAddress,
          ),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
        ),
      );
    });

    _mapController?.animateCamera(
      CameraUpdate.newLatLngZoom(location, 15.0),
    );

    if (_deliveryLocation != null) {
      await _getRoutePolyline();
    }
  }

  Future<void> _updateDeliveryLocation(LatLng location, String address) async {
    setState(() {
      _deliveryLocation = location;
      _deliveryAddress = address;
      _showVehiclePanel = true;

      _markers.removeWhere((marker) => marker.markerId.value == 'delivery_location');
      _markers.add(
        Marker(
          markerId: const MarkerId('delivery_location'),
          position: location,
          infoWindow: InfoWindow(
            title: 'Delivery Location',
            snippet: _deliveryAddress!,
          ),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
        ),
      );
    });

    await _getRoutePolyline();
  }

  void _proceedWithBooking() async {
    final selectedVehicle = _vehicles[_selectedVehicleIndex];

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Confirm Booking'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Vehicle: ${selectedVehicle['name']}', style: const TextStyle(fontSize: 16)),
            Text('Price: ${selectedVehicle['price']}', style: const TextStyle(fontSize: 16)),
            Text('Capacity: ${selectedVehicle['capacity']}', style: const TextStyle(fontSize: 14, color: Colors.grey)),
            const SizedBox(height: 8),
            Text('Pickup: $_pickupAddress', style: const TextStyle(fontSize: 14)),
            Text('Delivery: ${_deliveryAddress ?? 'Not set'}', style: const TextStyle(fontSize: 14)),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: const Text('Booking confirmed! Driver will arrive soon.'),
                  backgroundColor: Colors.green,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF22AAAE),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text('Confirm'),
          ),
        ],
      ),
    );
  }

  Widget _buildLocationCard() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          InkWell(
            onTap: () => _showAddressInputDialog(true),
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(12),
              topRight: Radius.circular(12),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: Color(0xFF22AAAE),
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'PICKUP',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey.shade600,
                            letterSpacing: 0.5,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _pickupAddress.isNotEmpty ? _pickupAddress : 'Select pickup location',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                            color: _pickupAddress.isNotEmpty ? Colors.black87 : Colors.grey.shade400,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            height: 1,
            color: Colors.grey.shade200,
          ),
          InkWell(
            onTap: () => _showAddressInputDialog(false),
            borderRadius: const BorderRadius.only(
              bottomLeft: Radius.circular(12),
              bottomRight: Radius.circular(12),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'DROP',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey.shade600,
                            letterSpacing: 0.5,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _deliveryAddress ?? 'Where to?',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                            color: _deliveryAddress != null ? Colors.black87 : Colors.grey.shade400,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVehicleCard(Map<String, dynamic> vehicle, int index) {
    final bool isSelected = _selectedVehicleIndex == index;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {
            setState(() {
              _selectedVehicleIndex = index;
            });
          },
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isSelected ? const Color(0xFF22AAAE) : Colors.grey.shade200,
                width: isSelected ? 2 : 1,
              ),
              color: isSelected ? const Color(0xFF22AAAE).withValues(alpha: 0.05) : Colors.white,
              boxShadow: isSelected
                  ? [
                      BoxShadow(
                        color: const Color(0xFF22AAAE).withValues(alpha: 0.2),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      )
                    ]
                  : [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.05),
                        blurRadius: 4,
                        offset: const Offset(0, 1),
                      )
                    ],
            ),
            child: Row(
              children: [
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: vehicle['gradient'],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    vehicle['icon'],
                    color: Colors.white,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            vehicle['name'],
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF2C2C2C),
                            ),
                          ),
                          const Spacer(),
                          Text(
                            vehicle['price'],
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF22AAAE),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        vehicle['description'],
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey.shade600,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Icon(
                            Icons.access_time,
                            size: 14,
                            color: Colors.grey.shade500,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            vehicle['time'],
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade500,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Icon(
                            Icons.fitness_center,
                            size: 14,
                            color: Colors.grey.shade500,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            vehicle['capacity'],
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade500,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                if (isSelected)
                  Container(
                    margin: const EdgeInsets.only(left: 8),
                    padding: const EdgeInsets.all(8),
                    decoration: const BoxDecoration(
                      color: Color(0xFF22AAAE),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.check,
                      color: Colors.white,
                      size: 16,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBookButton() {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.all(16),
      child: ElevatedButton(
        onPressed: _deliveryAddress != null ? _proceedWithBooking : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF22AAAE),
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 18),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: 8,
          shadowColor: const Color(0xFF22AAAE).withValues(alpha: 0.3),
        ),
        child: Text(
          _deliveryAddress != null ? 'Book Transportation' : 'Select Drop Location',
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  // Error dialogs
  void _showLocationServiceDisabledDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Location Services Disabled'),
        content: const Text('Please enable location services to continue.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showPermissionDeniedDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Location Permission Denied'),
        content: const Text('Location permission is required to show your current location.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showPermissionDeniedForeverDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Location Permission Required'),
        content: const Text('Location permission is permanently denied. Please enable it in app settings.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Geolocator.openAppSettings();
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF22AAAE),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text('Open Settings'),
          ),
        ],
      ),
    );
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Error'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentPositionAsync = ref.watch(currentPositionStreamProvider);
    final isLoading = currentPositionAsync.isLoading;
    final currentPosition = currentPositionAsync.value;
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: isLoading || _isLoading
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(
                    color: Color(0xFF22AAAE),
                    strokeWidth: 3,
                  ),
                  SizedBox(height: 20),
                  Text(
                    'Getting your location...',
                    style: TextStyle(
                      fontSize: 16,
                      color: Color(0xFF6B7280),
                    ),
                  ),
                ],
              ),
            )
          : Stack(
              children: [
                GoogleMap(
                  onMapCreated: (GoogleMapController controller) {
                    _mapController = controller;
                  },
                  initialCameraPosition: CameraPosition(
                    target: currentPosition != null
                        ? LatLng(currentPosition.latitude, currentPosition.longitude)
                        : const LatLng(28.6139, 77.2090),
                    zoom: 14.0,
                  ),
                  markers: _markers,
                  polylines: _polylines,
                  onTap: _onMapTapped,
                  myLocationEnabled: true,
                  myLocationButtonEnabled: false,
                  mapType: MapType.normal,
                  zoomControlsEnabled: false,
                  padding: EdgeInsets.only(
                    bottom: _showVehiclePanel
                        ? MediaQuery.of(context).size.height * _panelHeight
                        : 0,
                    top: 140,
                  ),
                ),

                Positioned(
                  top: MediaQuery.of(context).padding.top + 16,
                  left: 0,
                  right: 0,
                  child: _buildLocationCard(),
                ),

                if (_showVehiclePanel && _deliveryAddress != null)
                  DraggableScrollableSheet(
                    initialChildSize: _panelHeight,
                    minChildSize: _minPanelHeight,
                    maxChildSize: _maxPanelHeight,
                    builder: (context, scrollController) {
                      return NotificationListener<DraggableScrollableNotification>(
                        onNotification: (notification) {
                          setState(() {
                            _panelHeight = notification.extent;
                          });
                          return true;
                        },
                        child: Container(
                          decoration: const BoxDecoration(
                            color: Color(0xFFF8F9FA),
                            borderRadius: BorderRadius.only(
                              topLeft: Radius.circular(24),
                              topRight: Radius.circular(24),
                            ),
                          ),
                          child: Column(
                            children: [
                              Container(
                                margin: const EdgeInsets.symmetric(vertical: 12),
                                width: 50,
                                height: 4,
                                decoration: BoxDecoration(
                                  color: Colors.grey.shade400,
                                  borderRadius: BorderRadius.circular(2),
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 20),
                                child: Row(
                                  children: [
                                    const Icon(
                                      Icons.local_shipping,
                                      color: Color(0xFF22AAAE),
                                      size: 24,
                                    ),
                                    const SizedBox(width: 12),
                                    const Text(
                                      'Choose Vehicle',
                                      style: TextStyle(
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFF2C2C2C),
                                      ),
                                    ),
                                    const Spacer(),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFF22AAAE).withValues(alpha: 0.1),
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                      child: const Row(
                                        children: [
                                          Icon(Icons.access_time, size: 16, color: Color(0xFF22AAAE)),
                                          SizedBox(width: 4),
                                          Text(
                                            'NOW',
                                            style: TextStyle(
                                              fontSize: 12,
                                              fontWeight: FontWeight.bold,
                                              color: Color(0xFF22AAAE),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 20),
                              Expanded(
                                child: ListView(
                                  controller: scrollController,
                                  padding: const EdgeInsets.symmetric(horizontal: 20),
                                  children: [
                                    ..._vehicles.asMap().entries.map((entry) {
                                      return _buildVehicleCard(entry.value, entry.key);
                                    }),
                                    _buildBookButton(),
                                    SizedBox(height: MediaQuery.of(context).padding.bottom),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),

                Positioned(
                  bottom: _showVehiclePanel
                      ? MediaQuery.of(context).size.height * _panelHeight + 20
                      : 20,
                  right: 20,
                  child: FloatingActionButton(
                    mini: true,
                    onPressed: _getCurrentLocation,
                    backgroundColor: Colors.white,
                    foregroundColor: const Color(0xFF22AAAE),
                    elevation: 8,
                    child: const Icon(Icons.my_location),
                  ),
                ),
              ],
            ),
    );
  }
}

// Separate widget for address search with working Google Places
class AddressSearchWidget extends StatefulWidget {
  final bool isPickup;
  final String googleApiKey;
  final String currentAddress;
  final Function(LatLng, String) onLocationSelected;
  final Future<List<PlacePrediction>> Function(String) searchPlaces;
  final Future<LatLng?> Function(String) getPlaceDetails;

  const AddressSearchWidget({
    super.key,
    required this.isPickup,
    required this.googleApiKey,
    required this.currentAddress,
    required this.onLocationSelected,
    required this.searchPlaces,
    required this.getPlaceDetails,
  });

  @override
  State<AddressSearchWidget> createState() => _AddressSearchWidgetState();
}

class _AddressSearchWidgetState extends State<AddressSearchWidget> {
  final TextEditingController _controller = TextEditingController();
  List<PlacePrediction> _predictions = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _controller.text = widget.currentAddress;
    _controller.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _controller.removeListener(_onSearchChanged);
    _controller.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    if (_controller.text.isNotEmpty) {
      _searchPlaces(_controller.text);
    } else {
      setState(() {
        _predictions.clear();
      });
    }
  }

  Future<void> _searchPlaces(String query) async {
    if (query.length < 3) {
      setState(() {
        _predictions.clear();
      });
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final predictions = await widget.searchPlaces(query);
      setState(() {
        _predictions = predictions;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _predictions.clear();
      });
    }
  }

  Future<void> _onPredictionTapped(PlacePrediction prediction) async {
    setState(() {
      _isLoading = true;
    });

    final LatLng? location = await widget.getPlaceDetails(prediction.placeId);

    setState(() {
      _isLoading = false;
    });

    if (location != null) {
      widget.onLocationSelected(location, prediction.description);
      if (mounted) {
        Navigator.pop(context);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.9,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      child: Column(
        children: [
          // Handle bar
          Container(
            margin: const EdgeInsets.symmetric(vertical: 12),
            width: 50,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.arrow_back),
                ),
                Text(
                  widget.isPickup ? 'Set Pickup Location' : 'Set Drop Location',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),

          // Search field
          Padding(
            padding: const EdgeInsets.all(20),
            child: TextField(
              controller: _controller,
              decoration: InputDecoration(
                hintText: 'Search for location...',
                prefixIcon: const Icon(Icons.search, color: Color(0xFF22AAAE)),
                suffixIcon: _isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: Padding(
                          padding: EdgeInsets.all(12),
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Color(0xFF22AAAE),
                          ),
                        ),
                      )
                    : _controller.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              _controller.clear();
                              setState(() {
                                _predictions.clear();
                              });
                            },
                          )
                        : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFF22AAAE), width: 2),
                ),
                filled: true,
                fillColor: Colors.grey.shade50,
              ),
              onSubmitted: (value) {
                if (value.isNotEmpty) {
                  _searchPlaces(value);
                }
              },
            ),
          ),

          // Results
          Expanded(
            child: _predictions.isEmpty && !_isLoading
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.search,
                          size: 64,
                          color: Colors.grey.shade400,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Start typing to search for locations',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    itemCount: _predictions.length,
                    itemBuilder: (context, index) {
                      final prediction = _predictions[index];
                      return InkWell(
                        onTap: () => _onPredictionTapped(prediction),
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          child: Row(
                            children: [
                              const Icon(Icons.location_on, color: Colors.grey),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      prediction.structuredFormat ?? prediction.description.split(',').first,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w600,
                                        fontSize: 16,
                                      ),
                                    ),
                                    if (prediction.structuredFormat != null)
                                      const SizedBox(height: 2),
                                    Text(
                                      prediction.description,
                                      style: TextStyle(
                                        color: Colors.grey.shade600,
                                        fontSize: 14,
                                      ),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
                              ),
                              const Icon(Icons.north_west, color: Colors.grey, size: 16),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}