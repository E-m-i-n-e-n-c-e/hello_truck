import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:hello_truck_app/widgets/location_permission_handler.dart';
import 'package:hello_truck_app/providers/location_providers.dart';
import 'package:hello_truck_app/providers/auth_providers.dart';
import 'package:hello_truck_app/widgets/address_search_widget.dart';
import 'package:hello_truck_app/services/google_places_service.dart';
import 'package:hello_truck_app/services/pricing_service.dart';
import 'package:hello_truck_app/models/package.dart';
import 'package:hello_truck_app/models/address.dart';
import 'package:hello_truck_app/api/orders_api.dart' as orders_api;

class MapScreen extends ConsumerStatefulWidget {
  final Package? package;

  const MapScreen({super.key, this.package});

  @override
  ConsumerState<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends ConsumerState<MapScreen> with TickerProviderStateMixin {
  GoogleMapController? _mapController;
  LatLng? _deliveryLocation;
  final Set<Marker> _markers = {};
  final Set<Polyline> _polylines = {};
  bool _isLoading = true;
  Map<String, dynamic> _pickupAddress = {};
  Map<String, dynamic>? _deliveryAddress;
  int _selectedVehicleIndex = 1;
  bool _showVehiclePanel = false;
  List<PricingResult> _pricingResults = [];
  double _distanceKm = 0.0;

  // Panel animation
  late AnimationController _panelController;
  double _panelHeight = 0.3;
  final double _minPanelHeight = 0.3;
  final double _maxPanelHeight = 0.8;

  @override
  void initState() {
    super.initState();
    _panelController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    // Initialize with default pricing when no route is available
    _initializeDefaultPricing();
  }

  void _initializeDefaultPricing() {
    // Show default pricing with 5km distance
    final defaultPackage = _createDefaultPackage();
    final defaultDistance = 5.0; // 5km default distance

    final results = PricingService.calculatePricing(
      package: defaultPackage,
      distanceKm: defaultDistance,
      selfLoading: defaultPackage.loadingPreference == LoadingPreference.selfLoading,
    );

    setState(() {
      _pricingResults = results;
      _distanceKm = defaultDistance;
      _selectedVehicleIndex = 1; // Default to van
    });
  }

  @override
  void dispose() {
    _panelController.dispose();
    super.dispose();
  }

    // Calculate pricing based on current package and distance
  void _calculatePricing() {
    if (_distanceKm <= 0) {
      setState(() {
        _pricingResults = [];
      });
      return;
    }

    // Create a default package if none is provided
    Package packageToUse = widget.package ?? _createDefaultPackage();

    final selfLoading = packageToUse.loadingPreference == LoadingPreference.selfLoading;

    final results = PricingService.calculatePricing(
      package: packageToUse,
      distanceKm: _distanceKm,
      selfLoading: selfLoading,
    );

    setState(() {
      _pricingResults = results;

      // Auto-select recommended vehicle
      final recommended = PricingService.getRecommendedVehicle(results);
      if (recommended != null) {
        _selectedVehicleIndex = results.indexOf(recommended);
      }
    });

    // Print pricing details for debugging
    print('📊 DYNAMIC PRICING UPDATE 📊');
    print('Distance: ${_distanceKm.toStringAsFixed(1)}km');
    if (widget.package == null) {
      print('⚠️  Using default package (no package data provided)');
    }
    for (final result in results) {
      print(PricingService.formatPricingBreakdown(result));
      print('─' * 50);
    }
  }

  // Create a default package when none is provided
  Package _createDefaultPackage() {
    return Package.fromFormData(
      productType: ProductType.nonAgricultural,
      weight: 10.0, // Default 10kg
      dimensions: PackageDimensions(length: 30, width: 20, height: 15), // Default box
      loadingPreference: LoadingPreference.selfLoading,
    );
  }

  // Get route polyline between two points
  Future<void> _getRoutePolyline() async {
    // Use manually updated pickup location if available, otherwise use GPS position
    LatLng? pickupLocation;

    if (_pickupAddress.isNotEmpty && _markers.any((marker) => marker.markerId.value == 'pickup_location')) {
      // Use the manually set pickup location
      final pickupMarker = _markers.firstWhere((marker) => marker.markerId.value == 'pickup_location');
      pickupLocation = pickupMarker.position;
    } else {
      // Use GPS position
      final currentPosition = ref.read(currentPositionStreamProvider).value;
      if (currentPosition == null || _deliveryLocation == null) return;
      pickupLocation = LatLng(currentPosition.latitude, currentPosition.longitude);
    }

    if (_deliveryLocation == null) return;

    try {
      final polylineCoordinates = await GooglePlacesService.getRoutePolyline(
        pickupLocation,
        _deliveryLocation!,
      );

        if (polylineCoordinates != null) {
        // Calculate distance from polyline coordinates
        double totalDistance = 0.0;
        for (int i = 0; i < polylineCoordinates.length - 1; i++) {
          totalDistance += Geolocator.distanceBetween(
            polylineCoordinates[i].latitude,
            polylineCoordinates[i].longitude,
            polylineCoordinates[i + 1].latitude,
            polylineCoordinates[i + 1].longitude,
          );
        }

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
          _distanceKm = totalDistance / 1000.0; // Convert to kilometers
        });

        // Calculate pricing with the new distance
        _calculatePricing();
        _fitMarkersInView();
      }
    } catch (e) {
      debugPrint('Error getting route: $e');
    }
  }

  void _fitMarkersInView() {
    // Use manually updated pickup location if available, otherwise use GPS position
    LatLng? pickupLocation;

    if (_pickupAddress.isNotEmpty && _markers.any((marker) => marker.markerId.value == 'pickup_location')) {
      // Use the manually set pickup location
      final pickupMarker = _markers.firstWhere((marker) => marker.markerId.value == 'pickup_location');
      pickupLocation = pickupMarker.position;
    } else {
      // Use GPS position
      final currentPosition = ref.read(currentPositionStreamProvider).value;
      if (_mapController == null || currentPosition == null || _deliveryLocation == null) return;
      pickupLocation = LatLng(currentPosition.latitude, currentPosition.longitude);
    }

    if (_mapController == null || _deliveryLocation == null) return;

    final LatLngBounds bounds = LatLngBounds(
      southwest: LatLng(
        pickupLocation.latitude < _deliveryLocation!.latitude
            ? pickupLocation.latitude
            : _deliveryLocation!.latitude,
        pickupLocation.longitude < _deliveryLocation!.longitude
            ? pickupLocation.longitude
            : _deliveryLocation!.longitude,
      ),
      northeast: LatLng(
        pickupLocation.latitude > _deliveryLocation!.latitude
            ? pickupLocation.latitude
            : _deliveryLocation!.latitude,
        pickupLocation.longitude > _deliveryLocation!.longitude
            ? pickupLocation.longitude
            : _deliveryLocation!.longitude,
      ),
    );

    _mapController!.animateCamera(
      CameraUpdate.newLatLngBounds(bounds, 100.0),
    );
  }

  void _recenterMap() async{
    final currentPosition = ref.read(currentPositionStreamProvider).value;
    if (_mapController == null || currentPosition == null) return;

    final currentZoom = await _mapController!.getZoomLevel();

    _mapController!.animateCamera(
      CameraUpdate.newLatLngZoom(
        LatLng(currentPosition.latitude, currentPosition.longitude),
        max(16.0, currentZoom),
      ),
    );
  }

  Future<void> _getCurrentLocation() async {
    try {
      Position position = await ref.read(currentPositionStreamProvider.future);

      Map<String, dynamic> pickupAddr = await ref.read(locationServiceProvider).getAddressFromLatLng(
        position.latitude,
        position.longitude,
      );

      setState(() {
        _pickupAddress = pickupAddr;
        _isLoading = false;
        _markers.add(
          Marker(
            markerId: const MarkerId('pickup_location'),
            position: LatLng(position.latitude, position.longitude),
            infoWindow: InfoWindow(
              title: 'Pickup Location',
              snippet: _pickupAddress['addressLine1'] ?? '',
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
    // Use manually updated pickup location if available, otherwise use GPS position
    LatLng? zoomLocation;

    if (_pickupAddress.isNotEmpty && _markers.any((marker) => marker.markerId.value == 'pickup_location')) {
      // Use the manually set pickup location
      final pickupMarker = _markers.firstWhere((marker) => marker.markerId.value == 'pickup_location');
      zoomLocation = pickupMarker.position;
    } else {
      // Use GPS position
      final currentPosition = ref.read(currentPositionStreamProvider).value;
      if (_mapController == null || currentPosition == null) return;
      zoomLocation = LatLng(currentPosition.latitude, currentPosition.longitude);
    }

    if (_mapController == null) return;

    _mapController!.animateCamera(
      CameraUpdate.newLatLngZoom(zoomLocation, 16.0),
    );
  }

  void _onMapTapped(LatLng location) async {
    final locationService = ref.read(locationServiceProvider);
    Map<String, dynamic> address = await locationService.getAddressFromLatLng(location.latitude, location.longitude);

    setState(() {
      _deliveryLocation = location;
      _deliveryAddress = address;

      _markers.removeWhere((marker) => marker.markerId.value == 'delivery_location');
      _markers.add(
        Marker(
          markerId: const MarkerId('delivery_location'),
          position: location,
          infoWindow: InfoWindow(
            title: 'Delivery Location',
            snippet: _deliveryAddress!['addressLine1'] ?? '',
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
        currentAddress: isPickup ? _pickupAddress['formattedAddress'] : (_deliveryAddress?['formattedAddress'] ?? ''),
        onLocationSelected: (LatLng location) {
          if (isPickup) {
            _updatePickupLocation(location);
          } else {
            _updateDeliveryLocation(location);
          }
        },
        title: isPickup ? 'Set Pickup Location' : 'Set Drop Location',
      ),
    );
  }

  Future<void> _updatePickupLocation(LatLng location) async {
    final address = await ref.read(locationServiceProvider).getAddressFromLatLng(location.latitude, location.longitude);
    setState(() {
      _pickupAddress = address;
      _markers.removeWhere((marker) => marker.markerId.value == 'pickup_location');
      _markers.add(
        Marker(
          markerId: const MarkerId('pickup_location'),
          position: location,
          infoWindow: InfoWindow(
            title: 'Pickup Location',
            snippet: _pickupAddress['addressLine1'] ?? '',
          ),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
        ),
      );
    });

    _mapController?.animateCamera(
      CameraUpdate.newLatLngZoom(location, 16.0),
    );

    if (_deliveryLocation != null) {
      await _getRoutePolyline();
    }
  }

  Future<void> _updateDeliveryLocation(LatLng location) async {
    final address = await ref.read(locationServiceProvider).getAddressFromLatLng(location.latitude, location.longitude);
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
            snippet: _deliveryAddress?['addressLine1'] ?? '',
          ),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
        ),
      );
    });

    await _getRoutePolyline();
  }

  void _proceedWithBooking() async {
    if (_pricingResults.isEmpty || _selectedVehicleIndex >= _pricingResults.length) {
      return;
    }

    final selectedResult = _pricingResults[_selectedVehicleIndex];
    if (!selectedResult.isAvailable) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Selected vehicle is not available for this package'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final selectedVehicle = selectedResult.vehicle;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Confirm Booking'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Vehicle: ${selectedVehicle.name}', style: const TextStyle(fontSize: 16)),
            Text('Price: ${selectedResult.formattedPrice}', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF22AAAE))),
            Text('Capacity: ${selectedVehicle.weightCapacity.toStringAsFixed(0)}kg', style: const TextStyle(fontSize: 14, color: Colors.grey)),
            Text('Distance: ${_distanceKm.toStringAsFixed(1)}km', style: const TextStyle(fontSize: 14, color: Colors.grey)),
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
            onPressed: () => _confirmBooking(selectedResult),
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

  /// Create and submit order to API
  Future<void> _confirmBooking(PricingResult selectedResult) async {
    Navigator.pop(context); // Close dialog

    // Show loading
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const AlertDialog(
        content: Row(
          children: [
            CircularProgressIndicator(),
            SizedBox(width: 16),
            Text('Creating your order...'),
          ],
        ),
      ),
    );

    try {
      // Get API instance
      final api = await ref.read(apiProvider.future);

      // Get package data (use default if none provided)
      final packageData = widget.package ?? _createDefaultPackage();

      // Create pickup address from current location/address
      final pickupLocation = _markers
          .firstWhere((marker) => marker.markerId.value == 'pickup_location')
          .position;

      final now = DateTime.now();
      final pickupAddress = Address(
        id: 'pickup_temp',
        addressLine1: _pickupAddress['addressLine1'] ?? '',
        latitude: pickupLocation.latitude,
        longitude: pickupLocation.longitude,
        city: 'Current City', // Would be extracted from geocoding
        district: 'Current District',
        state: 'Current State',
        pincode: '000000',
        isDefault: false,
        createdAt: now,
        updatedAt: now,
      );

      // Create delivery address
      final deliveryAddress = Address(
        id: 'delivery_temp',
        addressLine1: _deliveryAddress?['addressLine1'] ?? '',
        latitude: _deliveryLocation!.latitude,
        longitude: _deliveryLocation!.longitude,
        city: 'Delivery City', // Would be extracted from geocoding
        district: 'Delivery District',
        state: 'Delivery State',
        pincode: '000000',
        isDefault: false,
        createdAt: now,
        updatedAt: now,
      );

      // Create order request
      final orderRequest = orders_api.CreateOrderRequest(
        package: packageData,
        pickupAddress: pickupAddress,
        deliveryAddress: deliveryAddress,
        vehicleType: selectedResult.vehicle.type,
        distanceKm: _distanceKm,
        metadata: {
          'appVersion': '1.0.0',
          'platform': 'mobile',
          'bookingSource': 'map_screen',
        },
      );

      // Submit order to API
      final order = await orders_api.createOrder(api, orderRequest);

      // Close loading dialog
      if (mounted) Navigator.pop(context);

      // Show success message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Order created successfully! Order ID: ${order.id}'),
            backgroundColor: Colors.green,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 3),
          ),
        );

        // Print order details for debugging
        print('🎉 ORDER CREATED SUCCESSFULLY 🎉');
        print('Order ID: ${order.id}');
        print('Status: ${order.status.name}');
        print('Vehicle: ${order.vehicleType.name}');
        print('Total Cost: ₹${order.totalCost.toStringAsFixed(2)}');
        print('=' * 50);
      }

    } catch (e) {
      // Close loading dialog
      if (mounted) Navigator.pop(context);

      // Show error message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to create order: ${e.toString()}'),
            backgroundColor: Colors.red,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 4),
          ),
        );
      }

      print('❌ ORDER CREATION FAILED: $e');
    }
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
                          _pickupAddress.isNotEmpty ? _pickupAddress['formattedAddress'] : 'Select pickup location',
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
                          _deliveryAddress?['formattedAddress'] ?? 'Where to?',
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

  Widget _buildVehicleCard(PricingResult result, int index) {
    final bool isSelected = _selectedVehicleIndex == index;
    final vehicle = result.vehicle;
    final isAvailable = result.isAvailable;

    // Map vehicle type to icon
    IconData getVehicleIcon(VehicleType type) {
      switch (type) {
        case VehicleType.bike:
          return Icons.motorcycle;
        case VehicleType.van:
          return Icons.airport_shuttle;
        case VehicleType.pickup:
          return Icons.local_shipping;
        case VehicleType.truck:
          return Icons.fire_truck;
      }
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: isAvailable ? () {
            setState(() {
              _selectedVehicleIndex = index;
            });
          } : null,
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: !isAvailable
                    ? Colors.grey.shade300
                    : isSelected
                        ? const Color(0xFF22AAAE)
                        : Colors.grey.shade200,
                width: isSelected ? 2 : 1,
              ),
              color: !isAvailable
                  ? Colors.grey.shade50
                  : isSelected
                      ? const Color(0xFF22AAAE).withValues(alpha: 0.05)
                      : Colors.white,
              boxShadow: isSelected && isAvailable
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
                      colors: isAvailable
                          ? vehicle.gradientColors.map((c) => Color(c)).toList()
                          : [Colors.grey.shade400, Colors.grey.shade500],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    getVehicleIcon(vehicle.type),
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
                            vehicle.name,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: isAvailable ? const Color(0xFF2C2C2C) : Colors.grey.shade500,
                            ),
                          ),
                          const Spacer(),
                          if (isAvailable) ...[
                            Text(
                              result.formattedPrice,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF22AAAE),
                              ),
                            ),
                          ] else ...[
                            Text(
                              'N/A',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.grey.shade400,
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        isAvailable ? vehicle.description : result.unavailableReason,
                        style: TextStyle(
                          fontSize: 13,
                          color: isAvailable ? Colors.grey.shade600 : Colors.red.shade400,
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
                            PricingService.getEstimatedTime(vehicle.type, _distanceKm),
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
                            '${vehicle.weightCapacity.toStringAsFixed(0)}kg',
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
                if (isSelected && isAvailable)
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
                if (!isAvailable)
                  Container(
                    margin: const EdgeInsets.only(left: 8),
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.close,
                      color: Colors.grey.shade600,
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
        onPressed: _deliveryAddress != null && _pricingResults.isNotEmpty ? _proceedWithBooking : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: _deliveryAddress != null && _pricingResults.isNotEmpty
              ? const Color(0xFF22AAAE)
              : Colors.grey.shade400,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 18),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: _deliveryAddress != null && _pricingResults.isNotEmpty ? 8 : 2,
          shadowColor: const Color(0xFF22AAAE).withValues(alpha: 0.3),
        ),
        child: Text(
          _deliveryAddress != null
              ? 'Book Transportation'
              : 'Select Drop Location First',
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
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
      body: LocationPermissionHandler(
        onPermissionGranted: _getCurrentLocation,
        child: isLoading || _isLoading
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
                      zoom: 16.0,
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

                  // Back button
                  Positioned(
                    top: MediaQuery.of(context).padding.top + 16,
                    left: 16,
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.1),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: IconButton(
                        icon: const Icon(Icons.arrow_back, color: Color(0xFF22AAAE)),
                        onPressed: () => Navigator.of(context).pop(),
                        iconSize: 24,
                        padding: const EdgeInsets.all(8),
                      ),
                    ),
                  ),

                  Positioned(
                    top: MediaQuery.of(context).padding.top + 16,
                    left: 70, // Adjusted to make room for back button
                    right: 16,
                    child: _buildLocationCard(),
                  ),

                  if ((_showVehiclePanel && _deliveryAddress != null) || _pricingResults.isNotEmpty)
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
                                      ..._pricingResults.asMap().entries.map((entry) {
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
                      onPressed: _recenterMap,
                      backgroundColor: Colors.white,
                      foregroundColor: const Color(0xFF22AAAE),
                      elevation: 8,
                      child: const Icon(Icons.my_location),
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}