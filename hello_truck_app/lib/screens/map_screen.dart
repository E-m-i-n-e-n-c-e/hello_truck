import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> with TickerProviderStateMixin {
  GoogleMapController? _mapController;
  Position? _currentPosition;
  LatLng? _deliveryLocation;
  final Set<Marker> _markers = {};
  bool _isLoading = true;
  final String _pickupAddress = '24, Ocean avenue';
  String _deliveryAddress = 'Kings Cross Underground';
  int _selectedVehicleIndex = 1; // Default to Small Van
  final TextEditingController _addressController = TextEditingController();

  // Panel animation
  late AnimationController _panelController;
  late Animation<double> _panelAnimation;
  double _panelHeight = 0.4; // Initial panel height (40% of screen)
  final double _minPanelHeight = 0.3; // Minimum panel height (30% of screen)
  final double _maxPanelHeight = 0.8; // Maximum panel height (80% of screen)

  // Vehicle options for goods transportation
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
    _panelAnimation = Tween<double>(
      begin: _minPanelHeight,
      end: _maxPanelHeight,
    ).animate(CurvedAnimation(
      parent: _panelController,
      curve: Curves.easeInOut,
    ));
    _getCurrentLocation();
  }

  @override
  void dispose() {
    _addressController.dispose();
    _panelController.dispose();
    super.dispose();
  }

  void _adjustMapZoom() {
    if (_mapController == null || _currentPosition == null) return;

    // Adjust zoom based on panel height
    double zoomLevel = _panelHeight < 0.5 ? 15.0 : 13.0;

    _mapController!.animateCamera(
      CameraUpdate.newLatLngZoom(
        LatLng(_currentPosition!.latitude, _currentPosition!.longitude),
        zoomLevel,
      ),
    );
  }

  Future<void> _getCurrentLocation() async {
    try {
      // Check if location services are enabled
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        _showLocationServiceDialog();
        return;
      }

      // Check location permissions
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          _showPermissionDeniedDialog();
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        _showPermissionDeniedForeverDialog();
        return;
      }

      // Get current position
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      setState(() {
        _currentPosition = position;
        _isLoading = false;
        _markers.add(
          Marker(
            markerId: const MarkerId('current_location'),
            position: LatLng(position.latitude, position.longitude),
            infoWindow: InfoWindow(
              title: 'Pickup Location',
              snippet: _pickupAddress,
            ),
            icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
          ),
        );
      });

      // Add a dummy delivery location for demo
      LatLng dummyDelivery = LatLng(
        position.latitude + 0.01,
        position.longitude + 0.01,
      );

      setState(() {
        _deliveryLocation = dummyDelivery;
        _markers.add(
          Marker(
            markerId: const MarkerId('delivery_location'),
            position: dummyDelivery,
            infoWindow: InfoWindow(
              title: 'Delivery Location',
              snippet: _deliveryAddress,
            ),
            icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
          ),
        );
      });

      // Move camera to show both locations
      _adjustMapZoom();
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      _showErrorDialog('Error getting location: $e');
    }
  }

  void _onMapTapped(LatLng location) {
    setState(() {
      _deliveryLocation = location;

      // Remove existing delivery marker if any
      _markers.removeWhere((marker) => marker.markerId.value == 'delivery_location');

      // Add new delivery marker
      _markers.add(
        Marker(
          markerId: const MarkerId('delivery_location'),
          position: location,
          infoWindow: const InfoWindow(
            title: 'Delivery Location',
            snippet: 'Tap to edit address',
          ),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
          onTap: () => _showAddressDialog(),
        ),
      );
    });
  }

  void _showAddressDialog() {
    _addressController.text = _deliveryAddress;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Enter Delivery Address'),
        content: TextField(
          controller: _addressController,
          decoration: InputDecoration(
            hintText: 'Enter the complete address...',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFF22AAAE), width: 2),
            ),
          ),
          maxLines: 3,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              setState(() {
                _deliveryAddress = _addressController.text;
              });
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF22AAAE),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _proceedWithBooking() {
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
            Text('Delivery: $_deliveryAddress', style: const TextStyle(fontSize: 14)),
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

  void _showLocationServiceDialog() {
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

  Widget _buildLocationCard() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha:0.08),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: Colors.green,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.green.withValues(alpha:0.3),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  _pickupAddress,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF2C2C2C),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: Colors.red,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.red.withValues(alpha:0.3),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: GestureDetector(
                  onTap: _showAddressDialog,
                  child: Text(
                    _deliveryAddress,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF2C2C2C),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildVehicleCard(Map<String, dynamic> vehicle, int index) {
    bool isSelected = index == _selectedVehicleIndex;

    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedVehicleIndex = index;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: isSelected ? LinearGradient(
            colors: vehicle['gradient'],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ) : null,
          color: isSelected ? null : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? Colors.transparent : Colors.grey.shade200,
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              color: isSelected
                ? vehicle['gradient'][0].withValues(alpha:0.3)
                : Colors.black.withValues(alpha:0.05),
              blurRadius: isSelected ? 15 : 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isSelected ? Colors.white.withValues(alpha:0.2) : Colors.grey.shade100,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                vehicle['icon'],
                size: 32,
                color: isSelected ? Colors.white : vehicle['gradient'][0],
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    vehicle['name'],
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: isSelected ? Colors.white : const Color(0xFF2C2C2C),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    vehicle['description'],
                    style: TextStyle(
                      fontSize: 13,
                      color: isSelected ? Colors.white.withValues(alpha:0.9) : Colors.grey.shade600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(
                        Icons.access_time,
                        size: 14,
                        color: isSelected ? Colors.white.withValues(alpha:0.8) : Colors.grey.shade500,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        vehicle['time'],
                        style: TextStyle(
                          fontSize: 12,
                          color: isSelected ? Colors.white.withValues(alpha:0.8) : Colors.grey.shade500,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Icon(
                        Icons.fitness_center,
                        size: 14,
                        color: isSelected ? Colors.white.withValues(alpha:0.8) : Colors.grey.shade500,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        vehicle['capacity'],
                        style: TextStyle(
                          fontSize: 12,
                          color: isSelected ? Colors.white.withValues(alpha:0.8) : Colors.grey.shade500,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  vehicle['price'],
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: isSelected ? Colors.white : const Color(0xFF2C2C2C),
                  ),
                ),
                if (isSelected)
                  Container(
                    margin: const EdgeInsets.only(top: 8),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha:0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text(
                      'SELECTED',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBookButton() {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.all(16),
      child: ElevatedButton(
        onPressed: _proceedWithBooking,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF22AAAE),
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 18),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: 8,
          shadowColor: const Color(0xFF22AAAE).withValues(alpha:0.3),
        ),
        child: const Text(
          'Book Transportation',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: _isLoading
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
                // Google Map
                AnimatedBuilder(
                  animation: _panelAnimation,
                  builder: (context, child) {
                    return GoogleMap(
                      onMapCreated: (GoogleMapController controller) {
                        _mapController = controller;
                      },
                      initialCameraPosition: CameraPosition(
                        target: _currentPosition != null
                            ? LatLng(_currentPosition!.latitude, _currentPosition!.longitude)
                            : const LatLng(28.6139, 77.2090), // Default to Delhi
                        zoom: 14.0,
                      ),
                      markers: _markers,
                      onTap: _onMapTapped,
                      myLocationEnabled: true,
                      myLocationButtonEnabled: false,
                      mapType: MapType.normal,
                      zoomControlsEnabled: false,
                      padding: EdgeInsets.only(
                        bottom: MediaQuery.of(context).size.height * _panelHeight,
                      ),
                    );
                  },
                ),

                // Top location card
                Positioned(
                  top: MediaQuery.of(context).padding.top + 16,
                  left: 0,
                  right: 0,
                  child: _buildLocationCard(),
                ),

                // Scrollable bottom panel
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
                        _adjustMapZoom();
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
                            // Drag handle
                            Container(
                              margin: const EdgeInsets.symmetric(vertical: 12),
                              width: 50,
                              height: 4,
                              decoration: BoxDecoration(
                                color: Colors.grey.shade400,
                                borderRadius: BorderRadius.circular(2),
                              ),
                            ),

                            // Header
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
                                      color: const Color(0xFF22AAAE).withValues(alpha:0.1),
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

                            // Scrollable vehicle list
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

                // Custom location button
                Positioned(
                  bottom: MediaQuery.of(context).size.height * _panelHeight + 20,
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