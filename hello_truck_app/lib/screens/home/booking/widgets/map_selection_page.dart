import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:hello_truck_app/models/place_prediction.dart';
import 'package:hello_truck_app/models/saved_address.dart';
import 'package:hello_truck_app/providers/location_providers.dart';
import 'package:hello_truck_app/widgets/location_permission_handler.dart';
import 'package:hello_truck_app/widgets/address_search_widget.dart';
import 'package:hello_truck_app/screens/home/booking/widgets/address_confirmation_modal.dart';
import 'package:hello_truck_app/widgets/snackbars.dart';
import 'package:hello_truck_app/providers/auth_providers.dart';

enum MapSelectionMode {
  booking, // Current mode - shows modals, save options, etc.
  direct,  // Direct mode - returns address directly without modals
}

const double predictionRadius = 50.0;

class MapSelectionPage extends ConsumerStatefulWidget {
  final bool isPickup;
  final Function(SavedAddress)? onAddressSelected;
  final String title;
  final MapSelectionMode mode;
  final SavedAddress? initialSavedAddress;
  final Address? initialAddress;
  final double? constraintRadius;

  // Constructor for booking (indirect) mode
  const MapSelectionPage.booking({
    super.key,
    this.isPickup = true,
    this.onAddressSelected,
    this.initialSavedAddress,
  })  : mode = MapSelectionMode.booking,
        initialAddress = null,
        constraintRadius = null,
        title = isPickup ? 'Pickup Location' : 'Drop Location';

  // Constructor for direct mode
  const MapSelectionPage.direct({
    super.key,
    this.initialAddress,
    this.constraintRadius,
    this.onAddressSelected,
  })  : mode = MapSelectionMode.direct,
        initialSavedAddress = null,
        title = 'Location',
        isPickup = true; // Not used in direct mode

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
  LatLng? _predictionCenter;
  String? _predictionName;

  void _initializeLocation() {
    if (widget.mode == MapSelectionMode.direct) {
      // For direct mode, initialize with provided initial address
      if (widget.initialAddress != null) {
        _selectedLocation = LatLng(
          widget.initialAddress!.latitude,
          widget.initialAddress!.longitude,
        );
        _selectedAddress = widget.initialAddress!.formattedAddress;

        if(widget.constraintRadius != null) {
          _circles.clear();
          _circles.add(
            Circle(
              circleId: const CircleId('constraint_radius'),
              center: LatLng(widget.initialAddress!.latitude, widget.initialAddress!.longitude),
              radius: widget.constraintRadius!,
              fillColor: Colors.blue.withValues(alpha: 0.1),
              strokeColor: Colors.blue.withValues(alpha: 0.3),
              strokeWidth: 2,
            ),
          );
        }

        // Add marker after the map is created
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (_selectedLocation != null) {
            _updateLocationAndAddress(_selectedLocation!);
          }
        });
      }
      return;
    }

    // Initialize with saved address if provided
    if (widget.initialSavedAddress != null && widget.mode == MapSelectionMode.booking) {
      _selectedLocation = LatLng(
        widget.initialSavedAddress!.address.latitude,
        widget.initialSavedAddress!.address.longitude,
      );
      _predictionCenter = LatLng(
        widget.initialSavedAddress!.address.latitude,
        widget.initialSavedAddress!.address.longitude,
      );
      _predictionName = widget.initialSavedAddress!.name;
      _selectedAddress = widget.initialSavedAddress!.address.formattedAddress;

      // Add radius circle around the prediction center
      _circles.clear();
      _circles.add(
        Circle(
          circleId: const CircleId('prediction_radius'),
          center: _predictionCenter!,
          radius: predictionRadius,
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

  Future<void> _updateLocationAndAddress(LatLng location, {PlacePrediction? prediction}) async {
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
      final formattedAddress = addressData.formattedAddress;

      // If prediction is provided, use it to set the address name and prediction center
      String addressName;
      if (prediction != null && prediction.description.isNotEmpty && widget.mode == MapSelectionMode.booking) {
        addressName = prediction.structuredFormat ?? prediction.description.split(',').first;
        _predictionCenter = LatLng(
          location.latitude,
          location.longitude,
        );
        _predictionName = addressName;
        _circles.clear();
        _circles.add(
          Circle(
            circleId: const CircleId('prediction_radius'),
            center: _predictionCenter!,
            radius: predictionRadius,
            fillColor: Colors.blue.withValues(alpha: 0.1),
            strokeColor: Colors.blue.withValues(alpha: 0.3),
            strokeWidth: 2,
          ),
        );
      } else {
        addressName = formattedAddress.split(',').length > 3
            ? formattedAddress.split(',').sublist(0, 3).join(',')
            : formattedAddress;
      }

      if (mounted) {
        setState(() {
          _selectedAddress = formattedAddress;
          _addressName = addressName;
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
  bool _isWithinPredictionRadius(LatLng location) {
    // If there is no prediction center then location is considered outside radius always
    if (_predictionCenter == null) return false;

    final distance = _calculateDistance(_predictionCenter!, location);
    return distance <= predictionRadius;
  }

  bool _isWithinConstraintRadius(LatLng location) {
    // return false;
    // If there is no constraint radius then location is considered within radius always
    if (widget.constraintRadius == null || widget.initialAddress == null) return true;

    final distance = _calculateDistance(LatLng(widget.initialAddress!.latitude, widget.initialAddress!.longitude), location);
    return distance <= widget.constraintRadius!;
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
          addressDetails: widget.initialAddress?.addressDetails,
        );

        Navigator.pop(context, address);
        return;
      }

      // Booking mode - show confirmation modal
      final address = Address(
        formattedAddress: _selectedAddress,
        latitude: _selectedLocation!.latitude,
        longitude: _selectedLocation!.longitude,
        // Prefill address details from initial saved address when available
        addressDetails: widget.initialSavedAddress?.address.addressDetails,
      );
        // If selected location is within allowed radius of prediction center, use prediction address and name
       if (_isWithinPredictionRadius(_selectedLocation!)) {
         _addressName = _predictionName ?? _addressName;
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
        useSafeArea: true,
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
        SnackBars.error(context, 'Error confirming location: $e');
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
    final authState = ref.watch(authStateProvider);

    // Check if user is offline
    if (authState.value?.isOffline == true) {
      return Scaffold(
        backgroundColor: colorScheme.surface,
        appBar: AppBar(
          backgroundColor: colorScheme.surface,
          elevation: 0,
          leading: IconButton(
            icon: Icon(Icons.arrow_back, color: colorScheme.onSurface),
            onPressed: () => Navigator.pop(context),
          ),
          title: Text(
            widget.title,
            style: textTheme.titleLarge?.copyWith(
              color: colorScheme.onSurface,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.wifi_off_rounded,
                  size: 80,
                  color: colorScheme.error,
                ),
                const SizedBox(height: 24),
                Text(
                  'No Internet Connection',
                  style: textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: colorScheme.onSurface,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                Text(
                  'Address selection requires an internet connection. Please check your network and try again.',
                  style: textTheme.bodyLarge?.copyWith(
                    color: colorScheme.onSurface.withValues(alpha: 0.7),
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),
                ElevatedButton.icon(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.arrow_back),
                  label: const Text('Go Back'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: colorScheme.primary,
                    foregroundColor: colorScheme.onPrimary,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 32,
                      vertical: 16,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: colorScheme.surface,
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
                      : (widget.initialAddress != null && widget.mode == MapSelectionMode.direct)
                          ? LatLng(
                              widget.initialAddress!.latitude,
                              widget.initialAddress!.longitude,
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
                  color: colorScheme.surface,
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
                                  _addressName.isEmpty
                                      ? widget.mode == MapSelectionMode.direct
                                          ? 'Pick up or drop item at?'
                                          : (widget.isPickup ? 'Pick up item at?' : 'Drop item at?')
                                      : (_predictionName != null && _isWithinPredictionRadius(_selectedLocation!))
                                          ? _predictionName!
                                          : _addressName,
                                  style: textTheme.bodyMedium?.copyWith(
                                    color: _addressName.isEmpty
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
                                  color: colorScheme.surface,
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
                                  color: colorScheme.surface,
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
                decoration: BoxDecoration(
                  color: colorScheme.surfaceBright,
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
                            // Constraint radius check message
                            if (_selectedLocation != null &&
                                !_isWithinConstraintRadius(_selectedLocation!))
                              Padding(
                                padding: const EdgeInsets.only(top: 10),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Icon(Icons.error_outline, size: 18, color: colorScheme.error),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        'Selected location is too far from the allowed area.',
                                        style: textTheme.bodySmall?.copyWith(
                                          color: colorScheme.error,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ),
                                  ],
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
                          onPressed: _selectedLocation != null &&
                                  !_isLoading &&
                                  _isWithinConstraintRadius(_selectedLocation!)
                              ? _confirmLocation
                              : null,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _selectedLocation != null &&
                                    _isWithinConstraintRadius(_selectedLocation!)
                                ? colorScheme.primary
                                : colorScheme.onSurface.withValues(alpha: 0.3),
                            foregroundColor: colorScheme.onPrimary,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 2,
                          ),
                          child: _isLoading
                              ? SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      colorScheme.onPrimary,
                                    ),
                                  ),
                                )
                              : Text(
                                  widget.mode == MapSelectionMode.direct
                                      ? 'Confirm Location'
                                      : 'Confirm ${widget.isPickup ? 'Pickup' : 'Drop'} Location',
                                  style: textTheme.titleMedium?.copyWith(
                                    color: colorScheme.onPrimary,
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
        onLocationSelected: (location, prediction) {
          _updateLocationAndAddress(location, prediction: prediction);
        },
        title: 'Search ${widget.title}',
      ),
    );
  }
}
