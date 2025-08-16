import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:hello_truck_app/models/saved_address.dart';
import 'package:hello_truck_app/providers/location_providers.dart';
import 'package:hello_truck_app/widgets/location_permission_handler.dart';
import 'package:hello_truck_app/widgets/address_search_widget.dart';
import 'package:hello_truck_app/screens/home/booking/widgets/address_confirmation_modal.dart';

enum MapSelectionMode {
  booking, // Current mode - shows modals, save options, etc.
  direct,  // Direct mode - returns address directly without modals
}

class MapSelectionPage extends ConsumerStatefulWidget {
  final bool isPickup;
  final Function(SavedAddress)? onAddressSelected;
  final String title;
  final MapSelectionMode mode;
  final SavedAddress? initialSavedAddress;

  const MapSelectionPage({
    super.key,
    this.isPickup = true,
    this.onAddressSelected,
    this.mode = MapSelectionMode.booking,
    this.initialSavedAddress,
  }): title = mode == MapSelectionMode.direct
      ? 'Location'
      : (isPickup ? 'Pickup Location' : 'Drop Location');

  @override
  ConsumerState<MapSelectionPage> createState() => _MapSelectionPageState();
}

class _MapSelectionPageState extends ConsumerState<MapSelectionPage> {
  GoogleMapController? _mapController;
  LatLng? _selectedLocation;
  final Set<Marker> _markers = {};
  final Set<Circle> _circles = {};
  bool _isLoading = false;
  String _selectedAddress = '';
  String _addressName = '';

  // Constants for distance calculation
  static const double allowedRadiusMeters = 500.0; // 500m radius

  void _initializeLocation() {
    // Initialize with saved address if provided
    if (widget.initialSavedAddress != null) {
      _selectedLocation = LatLng(
        widget.initialSavedAddress!.address.latitude,
        widget.initialSavedAddress!.address.longitude,
      );
      _selectedAddress = widget.initialSavedAddress!.address.formattedAddress;

      // Add 500m radius circle around the initial address
      _circles.clear();
      _circles.add(
        Circle(
          circleId: const CircleId('allowed_radius'),
          center: _selectedLocation!,
          radius: allowedRadiusMeters,
          fillColor: Colors.blue.withValues(alpha: 0.1),
          strokeColor: Colors.blue.withValues(alpha: 0.3),
          strokeWidth: 2,
        ),
      );

      // Add initial marker after the map is created
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_selectedLocation != null) {
          _updateLocationAndAddress(_selectedLocation!);
        }
      });
    }
  }

  Future<BitmapDescriptor> _createCustomMarkerIcon() async {
    return BitmapDescriptor.defaultMarkerWithHue(
      widget.isPickup ? BitmapDescriptor.hueGreen : BitmapDescriptor.hueRed,
    );
  }

  Future<void> _updateLocationAndAddress(LatLng location) async {
    // Update marker
    _markers.clear();
    _markers.add(
      Marker(
        markerId: const MarkerId('selected_location'),
        position: location,
        draggable: true,
        onDragEnd: (newPosition) => _updateLocationAndAddress(newPosition),
        icon: await _createCustomMarkerIcon(),
        infoWindow: InfoWindow(title: widget.title),
      ),
    );

    setState(() {
      _selectedLocation = location;
      _isLoading = true;
    });

    // Animate camera to selected location
    _mapController?.animateCamera(CameraUpdate.newLatLngZoom(location, 18.0));

    try {
      // Get address from coordinates
      final addressData = await ref.read(locationServiceProvider).getAddressFromLatLng(
        location.latitude,
        location.longitude,
      );

      if (mounted) {
        setState(() {
          _selectedAddress = addressData['formattedAddress'] ?? 'Unknown location';
          _addressName = addressData['formattedAddress'] ?? 'Unknown location';
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _selectedAddress = 'Unable to get address';
          _addressName = 'Unknown location';
          _isLoading = false;
        });
      }
      debugPrint('Error getting address: $e');
    }
  }

    // Calculate distance between two points using Geolocator
  double _calculateDistance(LatLng point1, LatLng point2) {
    return Geolocator.distanceBetween(
      point1.latitude,
      point1.longitude,
      point2.latitude,
      point2.longitude,
    );
  }

  // Check if location is within allowed radius of initial address
  bool _isWithinAllowedRadius(LatLng location) {
    // If there is no initial address then location is considered out of radius
    if (widget.initialSavedAddress == null) return false;

    final initialLocation = LatLng(
      widget.initialSavedAddress!.address.latitude,
      widget.initialSavedAddress!.address.longitude,
    );

    final distance = _calculateDistance(initialLocation, location);
    return distance <= allowedRadiusMeters;
  }

  void _recenterMap() async {
    final currentPosition = ref.read(currentPositionStreamProvider).value;
    if (_mapController == null || currentPosition == null) return;

    final currentZoom = await _mapController!.getZoomLevel();

    _mapController!.animateCamera(
      CameraUpdate.newLatLngZoom(
        LatLng(currentPosition.latitude, currentPosition.longitude),
        currentZoom > 16.0 ? currentZoom : 16.0,
      ),
    );
  }

  Future<void> _confirmLocation() async {
    if (_selectedLocation == null || !mounted) return;

    setState(() {
      _isLoading = true;
    });

    try {
      if (!mounted) return;

      if (widget.mode == MapSelectionMode.direct) {
        // Direct mode - return address directly without modals
        final address = Address(
          formattedAddress: _selectedAddress,
          latitude: _selectedLocation!.latitude,
          longitude: _selectedLocation!.longitude,
        );

        Navigator.pop(context, address);
        return;
      }

      // Booking mode - show confirmation modal
      final address = Address(
        formattedAddress: _selectedAddress,
        latitude: _selectedLocation!.latitude,
        longitude: _selectedLocation!.longitude,
      );
        // If selected location is within allowed radius of initial saved address, use same name
       if (_isWithinAllowedRadius(_selectedLocation!)) {
         _addressName = widget.initialSavedAddress?.name ?? _addressName;
       }

      final initialSavedAddress = SavedAddress(
        id: widget.initialSavedAddress?.id ?? '',
        name: _addressName,
        address: address,
        contactName: widget.initialSavedAddress?.contactName ?? '',
        contactPhone: widget.initialSavedAddress?.contactPhone ?? '',
        noteToDriver: widget.initialSavedAddress?.noteToDriver,
        isDefault: widget.initialSavedAddress?.isDefault ?? false,
        createdAt: widget.initialSavedAddress?.createdAt ?? DateTime.now(),
        updatedAt: widget.initialSavedAddress?.updatedAt ?? DateTime.now(),
      );

      // Show address confirmation modal
      final confirmedAddress = await showModalBottomSheet<SavedAddress>(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (context) => AddressConfirmationModal(
          savedAddress: initialSavedAddress,
          onConfirm: (address) {
            Navigator.pop(context, address);
          },
        ),
      );

      if (confirmedAddress != null && mounted) {
        widget.onAddressSelected?.call(confirmedAddress);
        if (mounted) {
          Navigator.pop(context);
        }
      }
    } catch (e) {
      debugPrint('Error confirming location: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error confirming location: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final currentPositionAsync = ref.watch(currentPositionStreamProvider);

    return Scaffold(
      backgroundColor: Colors.white,
      body: LocationPermissionHandler(
        onPermissionGranted: _initializeLocation,
        child: Stack(
          children: [
            // Google Map
            currentPositionAsync.when(
              data: (position) => GoogleMap(
                onMapCreated: (GoogleMapController controller) {
                  _mapController = controller;
                },
                initialCameraPosition: CameraPosition(
                  target: widget.initialSavedAddress != null
                      ? LatLng(
                          widget.initialSavedAddress!.address.latitude,
                          widget.initialSavedAddress!.address.longitude,
                        )
                      : LatLng(position.latitude, position.longitude),
                  zoom: 16.0,
                ),
                markers: _markers,
                circles: _circles,
                onTap: _updateLocationAndAddress,
                myLocationEnabled: true,
                myLocationButtonEnabled: false,
                mapType: MapType.normal,
                zoomControlsEnabled: false,
                padding: const EdgeInsets.only(top: 80, bottom: 200),
              ),
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, stack) =>
                  Center(child: Text('Error loading map: $error')),
            ),

            // Search Overlay at Top
            Positioned(
              top: MediaQuery.of(context).padding.top + 16,
              left: 16,
              right: 16,
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.1),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    IconButton(
                      icon: Icon(
                        Icons.arrow_back,
                        color: Colors.black.withValues(alpha: 0.8),
                      ),
                      onPressed: () => Navigator.pop(context),
                    ),
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 4,
                          vertical: 8,
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 8,
                              height: 8,
                              decoration: BoxDecoration(
                                color: widget.isPickup ? colorScheme.primary : Colors.red,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: GestureDetector(
                                behavior: HitTestBehavior.opaque,
                                onTap: _showSearchOverlay,
                                child: Text(
                                  _selectedAddress.isEmpty
                                      ? widget.mode == MapSelectionMode.direct
                                          ? 'Pick up or drop item at?'
                                          : (widget.isPickup ? 'Pick up item at?' : 'Drop item at?')
                                      : (widget.initialSavedAddress != null && _isWithinAllowedRadius(_selectedLocation!))
                                          ? widget.initialSavedAddress!.name
                                          : _selectedAddress,
                                  style: textTheme.bodyMedium?.copyWith(
                                    color: _selectedAddress.isEmpty
                                        ? Colors.grey.shade600
                                        : Colors.black87,
                                    fontWeight: FontWeight.w500,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    IconButton(
                      icon: Icon(
                        Icons.search,
                        color: Colors.black.withValues(alpha: 0.7),
                      ),
                      onPressed: _showSearchOverlay,
                    ),
                  ],
                ),
              ),
            ),

                              // Custom My Location button (bottom left)
                              Positioned(
                                bottom: 280,
                                left: 16,
                                child: Material(
                                  elevation: 4,
                                  borderRadius: BorderRadius.circular(12),
                                  color: Colors.white,
                                  child: InkWell(
                                    borderRadius: BorderRadius.circular(12),
                                    onTap: _recenterMap,
                                    child: Container(
                                      width: 40,
                                      height: 36,
                                      alignment: Alignment.center,
                                      child: Icon(Icons.my_location_rounded, size: 20, color: colorScheme.primary),
                                    ),
                                  ),
                                ),
                              ),

                              // Zoom controls (bottom right)
                              Positioned(
                                right: 16,
                                bottom: 280,
                                child: Material(
                                  elevation: 4,
                                  borderRadius: BorderRadius.circular(12),
                                  color: Colors.white,
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      InkWell(
                                        onTap: () {
                                          _mapController?.moveCamera(CameraUpdate.zoomIn());
                                        },
                                        borderRadius: const BorderRadius.only(
                                          topLeft: Radius.circular(12),
                                          topRight: Radius.circular(12),
                                        ),
                                        child: Container(
                                          width: 40,
                                          height: 36,
                                          alignment: Alignment.center,
                                          child: Icon(Icons.add, size: 20, color: colorScheme.primary),
                                        ),
                                      ),
                                      const Divider(height: 1, thickness: 1, color: Color(0xFFDDDDDD)),
                                      InkWell(
                                        onTap: () {
                                          _mapController?.moveCamera(CameraUpdate.zoomOut());
                                        },
                                        borderRadius: const BorderRadius.only(
                                          bottomLeft: Radius.circular(12),
                                          bottomRight: Radius.circular(12),
                                        ),
                                        child: Container(
                                          width: 40,
                                          height: 36,
                                          alignment: Alignment.center,
                                          child: Icon(Icons.remove, size: 20, color: colorScheme.primary),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),

            // Bottom Sheet
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(20),
                    topRight: Radius.circular(20),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black26,
                      blurRadius: 10,
                      offset: Offset(0, -2),
                    ),
                  ],
                ),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Handle bar
                      Container(
                        width: 50,
                        height: 4,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade300,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Selected Address
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: colorScheme.surface,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: colorScheme.outline.withValues(alpha: 0.3),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  Icons.location_on,
                                  color: colorScheme.primary,
                                  size: 20,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'Selected Location',
                                  style: textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: colorScheme.primary,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              _selectedAddress.isEmpty
                                  ? 'Tap on the map or drag the marker to select a location'
                                  : _selectedAddress,
                              style: textTheme.bodyMedium?.copyWith(
                                color: _selectedAddress.isEmpty
                                    ? colorScheme.onSurface.withValues(
                                        alpha: 0.6,
                                      )
                                    : colorScheme.onSurface,
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 20),

                      // Confirm Button
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _selectedLocation != null && !_isLoading
                              ? _confirmLocation
                              : null,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _selectedLocation != null
                                ? colorScheme.primary
                                : colorScheme.onSurface.withValues(alpha: 0.3),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 2,
                          ),
                          child: _isLoading
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      Colors.white,
                                    ),
                                  ),
                                )
                              : Text(
                                  widget.mode == MapSelectionMode.direct
                                      ? 'Confirm Location'
                                      : 'Confirm ${widget.isPickup ? 'Pickup' : 'Drop'} Location',
                                  style: textTheme.titleMedium?.copyWith(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                        ),
                      ),

                      // Add bottom padding for safe area
                      SizedBox(height: MediaQuery.of(context).padding.bottom),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showSearchOverlay() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => AddressSearchWidget(
        currentAddress: _selectedAddress,
        onLocationSelected: (location) {
          _updateLocationAndAddress(location);
        },
        title: 'Search ${widget.title}',
      ),
    );
  }
}
