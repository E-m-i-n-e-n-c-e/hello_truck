import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:hello_truck_app/models/booking.dart';
import 'package:hello_truck_app/models/saved_address.dart';
import 'package:hello_truck_app/providers/addresse_providers.dart';
import 'package:hello_truck_app/providers/location_providers.dart';
import 'package:hello_truck_app/providers/customer_providers.dart';
import 'package:hello_truck_app/services/google_places_service.dart';
import 'package:hello_truck_app/screens/home/booking/widgets/address_search_page.dart';
import 'package:hello_truck_app/screens/home/booking/package_details_screen.dart';
import 'package:hello_truck_app/widgets/location_permission_handler.dart';
import 'package:hello_truck_app/api/address_api.dart';
import 'package:hello_truck_app/providers/auth_providers.dart';

class AddressSelectionScreen extends ConsumerStatefulWidget {
  const AddressSelectionScreen({super.key});

  @override
  ConsumerState<AddressSelectionScreen> createState() =>
      _AddressSelectionScreenState();
}

class _AddressSelectionScreenState
      extends ConsumerState<AddressSelectionScreen> {
  SavedAddress? _pickupAddress;
  SavedAddress? _dropAddress;
  GoogleMapController? _mapController;
  final Set<Marker> _markers = {};
  final Set<Polyline> _polylines = {};
  double _distanceKm = 0.0;
  bool _hasInitializedCurrentLocation = false;
  bool _hasCheckedDefaultAddress = false;
  String? get _pickupContactNumber => _pickupAddress?.contactPhone;
  String? get _pickupContactName => _pickupAddress?.contactName;
  String? get _dropContactNumber => _dropAddress?.contactPhone;
  String? get _dropContactName => _dropAddress?.contactName;

  Future<void> _checkDefaultAddress() async {
    if (_hasCheckedDefaultAddress) return;

    try {
      final api = await ref.read(apiProvider.future);
      final defaultAddress = await getDefaultSavedAddress(api);

      if (mounted) {
        setState(() {
          _pickupAddress = defaultAddress;
          _hasCheckedDefaultAddress = true;
        });
        _updateMapView();
      }
    } catch (e) {
      debugPrint('Error fetching default address: $e');
      _hasCheckedDefaultAddress = true;
    }
  }

  void _showAddressSearch(bool isPickup) {
    ref.invalidate(savedAddressesProvider);
    ref.invalidate(recentAddressesProvider);
    showModalBottomSheet<BuildContext>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      enableDrag: false,
      builder: (context) => AddressSearchPage(
        isPickup: isPickup,
        onAddressSelected: (address) {
          setState(() {
            if (isPickup) {
              _pickupAddress = address;
            } else {
              _dropAddress = address;
            }
          });
          _updateMapView();
        },
      ),
    );
  }

  void _proceedToPackageDetails() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PackageDetailsScreen(
          pickupAddress: BookingAddress.fromSavedAddress(_pickupAddress!),
          dropAddress: BookingAddress.fromSavedAddress(_dropAddress!),
        ),
      ),
    );
  }

  Future<void> _initializeCurrentLocation() async {
    if (_hasInitializedCurrentLocation) return;

    // First try to get default address
    await _checkDefaultAddress();

    // If we already have a pickup address from default, don't override it
    if (_pickupAddress != null) {
      _hasInitializedCurrentLocation = true;
      return;
    }

    try {
      final position = await ref.read(currentPositionStreamProvider.future);
      final locationService = ref.read(locationServiceProvider);
      final customer = await ref.read(customerProvider.future);
      final customerName = '${customer.firstName} ${customer.lastName}'.trim();

      final addressData = await locationService.getAddressFromLatLng(
        position.latitude,
        position.longitude,
      );

      // Create a SavedAddress for current location
      final currentLocationAddress = SavedAddress(
        id: 'current_location',
        name: addressData.formattedAddress.split(',').length > 3
            ? addressData.formattedAddress.split(',').sublist(0, 3).join(',')
            : addressData.formattedAddress,
        address: Address(
          formattedAddress: addressData.formattedAddress,
          latitude: position.latitude,
          longitude: position.longitude,
        ),
        contactName: customerName,
        contactPhone: customer.phoneNumber,
        noteToDriver: null,
        isDefault: false,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      setState(() {
        _pickupAddress = currentLocationAddress;
        _hasInitializedCurrentLocation = true;
      });

      _updateMapView();
    } catch (e) {
      debugPrint('Error getting current location: $e');
    }
  }

  void _updateMapView() {
    if (_mapController == null) return;

    _updateMarkers();
    _getRoutePolyline();
    _centerMapToMarkers();
  }

  void _updateMarkers() {
    _markers.clear();

    // Add pickup marker
    if (_pickupAddress != null) {
      _markers.add(
        Marker(
          markerId: const MarkerId('pickup_location'),
          position: LatLng(
            _pickupAddress!.address.latitude,
            _pickupAddress!.address.longitude,
          ),
          infoWindow: InfoWindow(
            title: 'Pickup',
            snippet: _pickupAddress!.name,
          ),
          icon: BitmapDescriptor.defaultMarkerWithHue(
            BitmapDescriptor.hueGreen,
          ),
        ),
      );
    }

    // Add drop marker
    if (_dropAddress != null) {
      _markers.add(
        Marker(
          markerId: const MarkerId('drop_location'),
          position: LatLng(
            _dropAddress!.address.latitude,
            _dropAddress!.address.longitude,
          ),
          infoWindow: InfoWindow(title: 'Drop', snippet: _dropAddress!.name),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
        ),
      );
    }

    setState(() {});

    // Center map after updating markers
    _centerMapToMarkers();
  }

  Future<void> _getRoutePolyline() async {
    if (_pickupAddress == null || _dropAddress == null) return;

    final pickupLocation = LatLng(
      _pickupAddress!.address.latitude,
      _pickupAddress!.address.longitude,
    );
    final dropLocation = LatLng(
      _dropAddress!.address.latitude,
      _dropAddress!.address.longitude,
    );

    try {
      final polylineCoordinates = await GooglePlacesService.getRoutePolyline(
        pickupLocation,
        dropLocation,
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

        _fitMarkersInView();
      }
    } catch (e) {
      debugPrint('Error getting route: $e');
    }
  }

  void _centerMapToMarkers() {
    if (_mapController == null) return;

    // If both addresses are available, fit both markers
    if (_pickupAddress != null && _dropAddress != null) {
      final pickupLocation = LatLng(
        _pickupAddress!.address.latitude,
        _pickupAddress!.address.longitude,
      );
      final dropLocation = LatLng(
        _dropAddress!.address.latitude,
        _dropAddress!.address.longitude,
      );

      final LatLngBounds bounds = LatLngBounds(
        southwest: LatLng(
          pickupLocation.latitude < dropLocation.latitude
              ? pickupLocation.latitude
              : dropLocation.latitude,
          pickupLocation.longitude < dropLocation.longitude
              ? pickupLocation.longitude
              : dropLocation.longitude,
        ),
        northeast: LatLng(
          pickupLocation.latitude > dropLocation.latitude
              ? pickupLocation.latitude
              : dropLocation.latitude,
          pickupLocation.longitude > dropLocation.longitude
              ? pickupLocation.longitude
              : dropLocation.longitude,
        ),
      );

      _mapController!.animateCamera(
        CameraUpdate.newLatLngBounds(bounds, 100.0),
      );
    }
    // If only one address is available, center on that with zoom level 16
    else if (_pickupAddress != null) {
      _mapController!.animateCamera(
        CameraUpdate.newLatLngZoom(
          LatLng(
            _pickupAddress!.address.latitude,
            _pickupAddress!.address.longitude,
          ),
          16.0,
        ),
      );
    } else if (_dropAddress != null) {
      _mapController!.animateCamera(
        CameraUpdate.newLatLngZoom(
          LatLng(
            _dropAddress!.address.latitude,
            _dropAddress!.address.longitude,
          ),
          16.0,
        ),
      );
    }
  }

  void _fitMarkersInView() {
    _centerMapToMarkers();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final currentPositionAsync = ref.watch(currentPositionStreamProvider);

    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: SafeArea(
        child: Column(
          children: [
            // Header with back button and title
            Row(
              children: [
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: BackButton(color: Colors.black.withValues(alpha: 0.8)),
                ),
                Text(
                  'Select Addresses',
                  style: textTheme.titleLarge?.copyWith(
                    color: Colors.black.withValues(alpha: 0.85),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            Expanded(
              child: LocationPermissionHandler(
                onPermissionGranted: _initializeCurrentLocation,
                child: Stack(
                  children: [
                    // Full Map Section
                      Stack(
                        children: [
                          GoogleMap(
                            onMapCreated: (GoogleMapController controller) {
                              _mapController = controller;
                              _updateMapView();
                            },
                            initialCameraPosition: CameraPosition(
                            target: LatLng(
                              _pickupAddress?.address.latitude ?? currentPositionAsync.value?.latitude ?? 9.75603120,
                              _pickupAddress?.address.longitude ?? currentPositionAsync.value?.longitude ?? 76.64798330,
                            ),
                              zoom: 14.0,
                            ),
                            markers: _markers,
                            polylines: _polylines,
                            myLocationEnabled: true,
                            myLocationButtonEnabled: false,
                            mapType: MapType.normal,
                            zoomControlsEnabled: false,
                            scrollGesturesEnabled: true,
                            zoomGesturesEnabled: true,
                            tiltGesturesEnabled: false,
                            rotateGesturesEnabled: false,
                          ),

                           // Search Bars Overlay (top)
                           Positioned(
                             top: 16,
                             left: 16,
                             right: 16,
                             child: Column(
                               children: [
                                 // Pickup Location Card
                                 Container(
                                   decoration: BoxDecoration(
                                     color: colorScheme.surfaceBright,
                                     borderRadius: BorderRadius.circular(12),
                                     boxShadow: [
                                       BoxShadow(
                                         color: Colors.black.withValues(
                                           alpha: 0.1,
                                         ),
                                         blurRadius: 8,
                                         offset: const Offset(0, 2),
                                       ),
                                     ],
                                   ),
                                   child: InkWell(
                                     onTap: () => _showAddressSearch(true),
                                     borderRadius: BorderRadius.circular(12),
                                     child: Padding(
                                       padding: const EdgeInsets.all(12),
                                       child: Row(
                                         children: [
                                           Container(
                                             width: 8,
                                             height: 8,
                                             decoration: BoxDecoration(
                                               color: colorScheme.primary,
                                               shape: BoxShape.circle,
                                             ),
                                           ),
                                           const SizedBox(width: 12),
                                           Expanded(
                                             child: Column(
                                               crossAxisAlignment:
                                                   CrossAxisAlignment.start,
                                               children: [
                                                 Text(
                                                   'Pickup Address',
                                                   style: textTheme.bodySmall
                                                       ?.copyWith(
                                                         color: colorScheme
                                                             .onSurface
                                                             .withValues(
                                                               alpha: 0.6,
                                                             ),
                                                         fontWeight:
                                                             FontWeight.w500,
                                                         letterSpacing: 0.5,
                                                       ),
                                                 ),
                                                 const SizedBox(height: 2),
                                                 Text(
                                                   _pickupAddress?.name ??
                                                       'Select pickup address',
                                                   style: textTheme.titleSmall
                                                       ?.copyWith(
                                                         color:
                                                             _pickupAddress !=
                                                                 null
                                                             ? colorScheme
                                                                   .onSurface
                                                             : colorScheme
                                                                   .onSurface
                                                                   .withValues(
                                                                     alpha: 0.5,
                                                                   ),
                                                         fontWeight:
                                                             FontWeight.w600,
                                                       ),
                                                   maxLines: 1,
                                                   overflow:
                                                       TextOverflow.ellipsis,
                                                 ),
                                                 // Contact details below address
                                                 if (_pickupContactName != null &&
                                                     _pickupContactName!.isNotEmpty)
                                                   Padding(
                                                     padding: const EdgeInsets.only(top: 2),
                                                     child: Text(
                                                       '$_pickupContactName • ${_pickupContactNumber ?? ''}',
                                                       style: textTheme.bodySmall?.copyWith(
                                                         color: colorScheme.onSurface.withValues(alpha: 0.6),
                                                         fontWeight: FontWeight.w400,
                                                       ),
                                                       maxLines: 1,
                                                       overflow: TextOverflow.ellipsis,
                                                     ),
                                                   ),
                                               ],
                                             ),
                                           ),
                                           IconButton(
                                             icon: Icon(
                                               Icons.search,
                                               color: Colors.black.withValues(alpha: 0.7),
                                             ),
                                             onPressed: () => _showAddressSearch(true),
                                           ),
                                         ],
                                       ),
                                     ),
                                   ),
                                 ),

                                 const SizedBox(height: 8),

                                 // Drop Location Card
                                 Container(
                                   decoration: BoxDecoration(
                                     color: colorScheme.surfaceBright,
                                     borderRadius: BorderRadius.circular(12),
                                     boxShadow: [
                                       BoxShadow(
                                         color: Colors.black.withValues(
                                           alpha: 0.1,
                                         ),
                                         blurRadius: 8,
                                         offset: const Offset(0, 2),
                                       ),
                                     ],
                                   ),
                                   child: InkWell(
                                     onTap: () => _showAddressSearch(false),
                                     borderRadius: BorderRadius.circular(12),
                                     child: Padding(
                                       padding: const EdgeInsets.all(12),
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
                                               crossAxisAlignment:
                                                   CrossAxisAlignment.start,
                                               children: [
                                                 Text(
                                                   'Drop Address',
                                                   style: textTheme.bodySmall
                                                       ?.copyWith(
                                                         color: colorScheme
                                                             .onSurface
                                                             .withValues(
                                                               alpha: 0.6,
                                                             ),
                                                         fontWeight:
                                                             FontWeight.w500,
                                                         letterSpacing: 0.5,
                                                       ),
                                                 ),
                                                 const SizedBox(height: 2),
                                                 Text(
                                                   _dropAddress?.name ??
                                                       'Where to?',
                                                   style: textTheme.titleSmall
                                                       ?.copyWith(
                                                         color:
                                                             _dropAddress != null
                                                             ? colorScheme
                                                                   .onSurface
                                                             : colorScheme
                                                                   .onSurface
                                                                   .withValues(
                                                                     alpha: 0.5,
                                                                   ),
                                                         fontWeight:
                                                             FontWeight.w600,
                                                       ),
                                                   maxLines: 1,
                                                   overflow:
                                                       TextOverflow.ellipsis,
                                                 ),
                                                 // Contact details below address
                                                 if (_dropContactName != null &&
                                                     _dropContactName!.isNotEmpty)
                                                   Padding(
                                                     padding: const EdgeInsets.only(top: 2),
                                                     child: Text(
                                                       '$_dropContactName • ${_dropContactNumber ?? ''}',
                                                       style: textTheme.bodySmall?.copyWith(
                                                         color: colorScheme.onSurface.withValues(alpha: 0.6),
                                                         fontWeight: FontWeight.w400,
                                                       ),
                                                       maxLines: 1,
                                                       overflow: TextOverflow.ellipsis,
                                                     ),
                                                   ),
                                               ],
                                             ),
                                           ),
                                           IconButton(
                                             icon: Icon(
                                               Icons.search,
                                               color: Colors.black.withValues(alpha: 0.7),
                                             ),
                                             onPressed: () => _showAddressSearch(false),
                                           ),
                                         ],
                                       ),
                                     ),
                                   ),
                                 ),
                              ],
                            ),
                          ),

                          // Distance Info Overlay (top right, below search bars)
                          if (_distanceKm > 0)
                            Positioned(
                              top:
                                  200, // Position further below the search bars
                              right: 16,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 8,
                                ),
                                decoration: BoxDecoration(
                                  color: colorScheme.surface,
                                  borderRadius: BorderRadius.circular(20),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withValues(
                                        alpha: 0.1,
                                      ),
                                      blurRadius: 8,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.route,
                                      color: colorScheme.primary,
                                      size: 16,
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      '${_distanceKm.toStringAsFixed(1)} km',
                                      style: textTheme.bodySmall?.copyWith(
                                        color: colorScheme.primary,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),

                          // Recenter button (bottom left)
                          Positioned(
                            bottom: 16,
                            left: 16,
                            child: Material(
                              elevation: 4,
                              borderRadius: BorderRadius.circular(12),
                              color: colorScheme.surface,
                              child: InkWell(
                                borderRadius: BorderRadius.circular(12),
                                onTap: _centerMapToMarkers,
                                child: Container(
                                  width: 40,
                                  height: 36,
                                  alignment: Alignment.center,
                                  child: Icon(
                                    Icons.my_location_rounded,
                                    size: 20,
                                    color: colorScheme.primary,
                                  ),
                                ),
                              ),
                            ),
                          ),

                          // Zoom controls (bottom right)
                          Positioned(
                            right: 16,
                            bottom: 16,
                            child: Material(
                              elevation: 4,
                              borderRadius: BorderRadius.circular(12),
                              color: colorScheme.surface,
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  InkWell(
                                    onTap: () {
                                      _mapController?.moveCamera(
                                        CameraUpdate.zoomIn(),
                                      );
                                    },
                                    borderRadius: const BorderRadius.only(
                                      topLeft: Radius.circular(12),
                                      topRight: Radius.circular(12),
                                    ),
                                    child: Container(
                                      width: 40,
                                      height: 36,
                                      alignment: Alignment.center,
                                      child: Icon(
                                        Icons.add,
                                        size: 20,
                                        color: colorScheme.primary,
                                      ),
                                    ),
                                  ),
                                  const Divider(
                                    height: 1,
                                    thickness: 1,
                                    color: Color(0xFFDDDDDD),
                                  ),
                                  InkWell(
                                    onTap: () {
                                      _mapController?.moveCamera(
                                        CameraUpdate.zoomOut(),
                                      );
                                    },
                                    borderRadius: const BorderRadius.only(
                                      bottomLeft: Radius.circular(12),
                                      bottomRight: Radius.circular(12),
                                    ),
                                    child: Container(
                                      width: 40,
                                      height: 36,
                                      alignment: Alignment.center,
                                      child: Icon(
                                        Icons.remove,
                                        size: 20,
                                        color: colorScheme.primary,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
              ),
            ),

            // Continue Button
            Container(
              width: double.infinity,
              margin: const EdgeInsets.all(16),
              child: ElevatedButton(
                onPressed: _pickupAddress != null && _dropAddress != null
                    ? _proceedToPackageDetails
                    : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor:
                      _pickupAddress != null && _dropAddress != null
                      ? colorScheme.primary
                      : colorScheme.onSurface.withValues(alpha: 0.3),
                  foregroundColor: colorScheme.onPrimary,
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: _pickupAddress != null && _dropAddress != null
                      ? 2
                      : 1,
                ),
                child: Text(
                  'Continue',
                  style: textTheme.titleMedium?.copyWith(
                    color: colorScheme.onPrimary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
