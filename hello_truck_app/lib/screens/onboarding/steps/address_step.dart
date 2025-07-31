import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:hello_truck_app/screens/onboarding/controllers/onboarding_controller.dart';
import 'package:hello_truck_app/screens/onboarding/widgets/onboarding_components.dart';
import 'package:hello_truck_app/screens/onboarding/widgets/location_permission_handler.dart';
import 'package:hello_truck_app/services/location_service.dart';
import 'package:hello_truck_app/providers/location_providers.dart';
import 'package:hello_truck_app/widgets/address_search_widget.dart';

class AddressStep extends ConsumerStatefulWidget {
  final OnboardingController controller;
  final VoidCallback onNext;

  const AddressStep({
    super.key,
    required this.controller,
    required this.onNext,
  });

  @override
  ConsumerState<AddressStep> createState() => _AddressStepState();
}

class _AddressStepState extends ConsumerState<AddressStep> {
  GoogleMapController? _mapController;
  final Set<Marker> _markers = {};

  @override
  void initState() {
    super.initState();
    _initializeLocationAndMap();
  }

  Future<void> _initializeLocationAndMap() async {
    final locationService = ref.read(locationServiceProvider);
    final permission = await locationService.checkAndRequestPermissions();

    if (permission == LocationPermissionStatus.granted) {
      try {
        final position = await ref.read(currentPositionStreamProvider.future);
          await Future.delayed(const Duration(milliseconds: 200));
          await _updateLocationAndAddress(LatLng(position.latitude, position.longitude),zoom: 16);
        } catch (e) {
        debugPrint('Error getting current position: $e');
      }
    }
  }

  Future<void> _updateLocationAndAddress(LatLng location,{double? zoom}) async {
    // Update marker
    _markers.clear();
    _markers.add(
      Marker(
        markerId: const MarkerId('address_marker'),
        position: location,
        draggable: true,
        onDragEnd: (newPosition) => _updateLocationAndAddress(newPosition),
        icon: await _createCustomMarkerIcon(),
      ),
    );

    // Update controller with coordinates
    widget.controller.updateSelectedLocation(location.latitude, location.longitude);

    // Get address details from coordinates
    final locationService = ref.read(locationServiceProvider);
    final addressData = await locationService.getAddressFromLatLng(
      location.latitude,
      location.longitude,
    );

    // Update all address fields
    widget.controller.addressLine1Controller.text = addressData['addressLine1'] ?? '';
    widget.controller.landmarkController.text = addressData['landmark'] ?? '';
    widget.controller.pincodeController.text = addressData['pincode'] ?? '';
    widget.controller.cityController.text = addressData['city'] ?? '';
    widget.controller.districtController.text = addressData['district'] ?? '';
    widget.controller.stateController.text = addressData['state'] ?? '';

    // Move camera to location
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_mapController != null) {
        _mapController!.animateCamera(
          zoom != null ? CameraUpdate.newLatLngZoom(location, zoom) : CameraUpdate.newLatLng(location),
        );
      }
    });
  }

  Future<BitmapDescriptor> _createCustomMarkerIcon() async {
    return BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen);
  }

  void _onMapTap(LatLng location) {
    _updateLocationAndAddress(location);
  }

  void _onMapCreated(GoogleMapController controller) {
    _mapController = controller;
  }

  // Show address search modal
  void _showAddressSearchModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => AddressSearchWidget(
        currentAddress: widget.controller.addressLine1Controller.text,
        onLocationSelected: (LatLng location, String address) {
          _updateLocationAndAddress(location);
        },
        title: 'Search for Address',
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return OnboardingStepContainer(
      controller: widget.controller,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const SizedBox(height: 16),

          // Step Icon
          Center(
            child: OnboardingStepIcon(
              controller: widget.controller,
              icon: Icons.location_on_rounded,
              color: colorScheme.secondary,
            ),
          ),

          const SizedBox(height: 24),

          // Title
          OnboardingStepTitle(
            controller: widget.controller,
            title: 'Select Your Address',
          ),

          const SizedBox(height: 12),

          OnboardingStepDescription(
            controller: widget.controller,
            description: 'Tap the search icon to search for your address and tap on the map or drag the marker to select your precise location.',
          ),

          const SizedBox(height: 32),

          // Map Container
          LocationPermissionHandler(
            onPermissionGranted: _initializeLocationAndMap,
            child: Container(
              height: 280,
              width: double.infinity,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Stack(
                  children: [
                    GoogleMap(
                      onMapCreated: _onMapCreated,
                      initialCameraPosition: const CameraPosition(
                        target: LatLng(12.9716, 77.5946), // Bangalore default
                        zoom: 14.0,
                      ),
                      markers: _markers,
                      onTap: _onMapTap,
                      myLocationEnabled: true,
                      myLocationButtonEnabled: false, // Disable default button
                      mapType: MapType.normal,
                      zoomControlsEnabled: false, //Disable default zoom controls
                      compassEnabled: true,
                      tiltGesturesEnabled: false,
                      gestureRecognizers: {
                        Factory<OneSequenceGestureRecognizer>(
                          () => EagerGestureRecognizer(),
                        ),
                      },
                    ),

                  // Loading indicator
                  if (ref.read(currentPositionStreamProvider).isLoading)
                    Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          CircularProgressIndicator(
                            valueColor: AlwaysStoppedAnimation<Color>(colorScheme.primary),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Getting your location...',
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: colorScheme.onSurface.withValues(alpha: 0.7),
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Floating search icon
                    Positioned(
                      top: 12,
                      right: 12,
                      child: Material(
                        elevation: 4,
                        borderRadius: BorderRadius.circular(12),
                        color: Colors.white,
                        child: InkWell(
                          onTap: _showAddressSearchModal,
                          borderRadius: BorderRadius.circular(12),
                          child: Container(
                            width: 40,
                            height: 36,
                            alignment: Alignment.center,
                            child: Icon(Icons.search_rounded, size: 20, color: Theme.of(context).colorScheme.primary),
                          ),
                        ),
                      ),
                    ),

                    // Custom My Location button (bottom left)
                    Positioned(
                      bottom: 12,
                      left: 12,
                      child: Material(
                        elevation: 4,
                        borderRadius: BorderRadius.circular(12),
                        color: Colors.white,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(12),
                          onTap: () async {
                            final position = await ref.read(currentPositionStreamProvider.future);
                            await _updateLocationAndAddress(LatLng(position.latitude, position.longitude));
                          },
                          child: Container(
                            width: 40,
                            height: 36,
                            alignment: Alignment.center,
                            child:  Icon(Icons.my_location_rounded, size: 20, color: Theme.of(context).colorScheme.primary),
                          ),
                        ),
                      ),
                    ),

                    Positioned(
                      right: 12,
                      bottom: 12,
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
                                child: Icon(Icons.add, size: 20, color: Theme.of(context).colorScheme.primary),
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
                                child: Icon(Icons.remove, size: 20, color: Theme.of(context).colorScheme.primary),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          const SizedBox(height: 24),

          // Address Form Fields
          _buildAddressForm(context),

          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildAddressForm(BuildContext context) {
    return Column(
      children: [
        // Address Line 1
        OnboardingTextField(
          controller: widget.controller,
          textController: widget.controller.addressLine1Controller,
          focusNode: widget.controller.addressLine1Focus,
          label: 'Address Line 1',
          hint: 'House/Building, Street',
          icon: Icons.home_rounded,
          isRequired: true,
          onSubmitted: (_) => widget.controller.landmarkFocus.requestFocus(),
        ),

        const SizedBox(height: 16),

        // Landmark
        OnboardingTextField(
          controller: widget.controller,
          textController: widget.controller.landmarkController,
          focusNode: widget.controller.landmarkFocus,
          label: 'Landmark (Optional)',
          hint: 'Near landmark or area',
          icon: Icons.place_rounded,
          onSubmitted: (_) => widget.controller.pincodeFocus.requestFocus(),
        ),

        const SizedBox(height: 16),

        // Pincode and City Row
        OnboardingTextField(
          controller: widget.controller,
          textController: widget.controller.pincodeController,
          focusNode: widget.controller.pincodeFocus,
          label: 'Pincode',
          hint: 'Enter Pincode',
          icon: Icons.pin_drop_rounded,
          isRequired: true,
          keyboardType: TextInputType.number,
          onSubmitted: (_) => widget.controller.cityFocus.requestFocus(),
        ),

        const SizedBox(height: 16),

        OnboardingTextField(
          controller: widget.controller,
          textController: widget.controller.cityController,
          focusNode: widget.controller.cityFocus,
          label: 'City',
          hint: 'City name',
          icon: Icons.location_city_rounded,
          isRequired: true,
          onSubmitted: (_) => widget.controller.districtFocus.requestFocus(),
        ),

        const SizedBox(height: 16),

        // District and State Row
        OnboardingTextField(
          controller: widget.controller,
          textController: widget.controller.districtController,
          focusNode: widget.controller.districtFocus,
          label: 'District',
          hint: 'District name',
          icon: Icons.map_rounded,
          isRequired: true,
          onSubmitted: (_) => widget.controller.stateFocus.requestFocus(),
        ),

        const SizedBox(height: 16),

        OnboardingTextField(
          controller: widget.controller,
          textController: widget.controller.stateController,
          focusNode: widget.controller.stateFocus,
          label: 'State',
          hint: 'State name',
          icon: Icons.public_rounded,
          isRequired: true,
          onSubmitted: (_) => widget.controller.phoneNumberFocus.requestFocus(),
        ),

        const SizedBox(height: 16),
        Divider(color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.6)),
        const SizedBox(height: 16),


        // Phone Number and Label Row
        OnboardingTextField(
          controller: widget.controller,
          textController: widget.controller.phoneNumberController,
          focusNode: widget.controller.phoneNumberFocus,
          label: 'Phone (Optional)',
          inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(10)],
          hint: 'Enter Phone Number',
          icon: Icons.phone_rounded,
          keyboardType: TextInputType.phone,
          onSubmitted: (_) => widget.controller.addressLabelFocus.requestFocus(),
        ),

        const SizedBox(height: 16),

        OnboardingTextField(
          controller: widget.controller,
          textController: widget.controller.addressLabelController,
          focusNode: widget.controller.addressLabelFocus,
          label: 'Label (Optional)',
          hint: 'Home, Office, etc.',
          icon: Icons.label_rounded,
          onSubmitted: (_) => widget.onNext(),
        ),
      ],
    );
  }
}