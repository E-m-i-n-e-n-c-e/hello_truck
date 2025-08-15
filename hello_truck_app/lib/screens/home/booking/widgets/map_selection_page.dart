import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:hello_truck_app/models/saved_address.dart';
import 'package:hello_truck_app/providers/location_providers.dart';
import 'package:hello_truck_app/screens/home/booking/widgets/contact_details_dialog.dart';
import 'package:hello_truck_app/screens/home/booking/widgets/save_address_dialog.dart';
import 'package:hello_truck_app/api/address_api.dart';
import 'package:hello_truck_app/providers/auth_providers.dart';
import 'package:hello_truck_app/widgets/location_permission_handler.dart';
import 'package:hello_truck_app/widgets/address_search_widget.dart';

class MapSelectionPage extends ConsumerStatefulWidget {
  final bool isPickup;
  final Function(SavedAddress) onAddressSelected;
  final String title;

  const MapSelectionPage({
    super.key,
    required this.isPickup,
    required this.onAddressSelected,
  }): title = isPickup ? 'Pickup Location' : 'Drop Location';

  @override
  ConsumerState<MapSelectionPage> createState() => _MapSelectionPageState();
}

class _MapSelectionPageState extends ConsumerState<MapSelectionPage> {
  GoogleMapController? _mapController;
  LatLng? _selectedLocation;
  final Set<Marker> _markers = {};
  bool _isLoading = false;
  String _selectedAddress = '';

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
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _selectedAddress = 'Unable to get address';
          _isLoading = false;
        });
      }
      debugPrint('Error getting address: $e');
    }
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
      // Get detailed address information
      final addressData = await ref.read(locationServiceProvider).getAddressFromLatLng(
        _selectedLocation!.latitude,
        _selectedLocation!.longitude,
      );

      if (!mounted) return;

      // Show contact details dialog
      final contactDetails = await showDialog<Map<String, String>>(
        context: context,
        builder: (context) => ContactDetailsDialog(
          addressName:
              addressData['locality'] ??
              addressData['sublocality'] ??
              'Selected Location',
        ),
      );

      if (contactDetails != null && mounted) {
        // Create address object
        final address = Address(
          formattedAddress: addressData['formattedAddress'] ?? _selectedAddress,
          latitude: _selectedLocation!.latitude,
          longitude: _selectedLocation!.longitude,
        );

        // Check if user wants to save this address
        final shouldSave = await showDialog<bool>(
          context: context,
          builder: (context) => SaveAddressDialog(
            addressName:
                addressData['locality'] ??
                addressData['sublocality'] ??
                'Selected Location',
          ),
        );

        if (!mounted) return;

        SavedAddress savedAddress;

        if (shouldSave == true) {
          // Save the address
          try {
            final api = await ref.read(apiProvider.future);
            savedAddress = await createSavedAddress(
              api,
              name:
                  addressData['locality'] ??
                  addressData['sublocality'] ??
                  'Selected Location',
              address: address,
              contactName: contactDetails['contactName'],
              contactPhone: contactDetails['contactPhone'],
              noteToDriver: contactDetails['noteToDriver'],
            );
          } catch (e) {
            // If saving fails, create a temporary saved address
            savedAddress = SavedAddress(
              id: 'temp_${DateTime.now().millisecondsSinceEpoch}',
              name:
                  addressData['locality'] ??
                  addressData['sublocality'] ??
                  'Selected Location',
              address: address,
              contactName: contactDetails['contactName'],
              contactPhone: contactDetails['contactPhone'],
              noteToDriver: contactDetails['noteToDriver'],
              isDefault: false,
              createdAt: DateTime.now(),
              updatedAt: DateTime.now(),
            );
          }
        } else {
          // Create temporary saved address without saving to backend
          savedAddress = SavedAddress(
            id: 'temp_${DateTime.now().millisecondsSinceEpoch}',
            name:
                addressData['locality'] ??
                addressData['sublocality'] ??
                'Selected Location',
            address: address,
            contactName: contactDetails['contactName'],
            contactPhone: contactDetails['contactPhone'],
            noteToDriver: contactDetails['noteToDriver'],
            isDefault: false,
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          );
        }

        widget.onAddressSelected(savedAddress);
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
        onPermissionGranted: () {},
        child: Stack(
          children: [
            // Google Map
            currentPositionAsync.when(
              data: (position) => GoogleMap(
                onMapCreated: (GoogleMapController controller) {
                  _mapController = controller;
                },
                initialCameraPosition: CameraPosition(
                  target: LatLng(position.latitude, position.longitude),
                  zoom: 16.0,
                ),
                markers: _markers,
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
                                      ? widget.isPickup ? 'Pick up item at?' : 'Drop item at?'
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

            // My Location Button
            Positioned(
              bottom: 220,
              right: 20,
              child: FloatingActionButton(
                mini: true,
                onPressed: _recenterMap,
                backgroundColor: Colors.white,
                foregroundColor: colorScheme.primary,
                elevation: 8,
                child: const Icon(Icons.my_location),
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
                                  'Confirm ${widget.isPickup ? 'Pickup' : 'Drop'} Location',
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
