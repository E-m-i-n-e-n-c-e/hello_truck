import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:hello_truck_app/screens/onboarding/controllers/onboarding_controller.dart';
import 'package:hello_truck_app/screens/onboarding/widgets/onboarding_components.dart';
import 'package:hello_truck_app/screens/onboarding/widgets/location_permission_handler.dart';
import 'package:hello_truck_app/services/location_service.dart';
import 'package:hello_truck_app/providers/location_providers.dart';

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
  bool _isLoadingAddress = false;

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
        final position = await locationService.getCurrentPosition();
        await _updateLocationAndAddress(LatLng(position.latitude, position.longitude));
      } catch (e) {
        debugPrint('Error getting current position: $e');
      }
    }
  }

  Future<void> _updateLocationAndAddress(LatLng location) async {
    setState(() {
      _isLoadingAddress = true;
    });

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

    setState(() {
      _isLoadingAddress = false;
    });

    // Move camera to new location
    if (_mapController != null) {
      _mapController!.animateCamera(
        CameraUpdate.newLatLng(location),
      );
    }
  }

  Future<BitmapDescriptor> _createCustomMarkerIcon() async {
    return BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueOrange);
  }

  void _onMapTap(LatLng location) {
    _updateLocationAndAddress(location);
  }

  void _onMapCreated(GoogleMapController controller) {
    _mapController = controller;
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return OnboardingStepContainer(
      controller: widget.controller,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 16),

          // Step Icon
          Center(
            child: OnboardingStepIcon(
              controller: widget.controller,
              icon: Icons.location_on_rounded,
              color: colorScheme.primary,
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
            description: 'Tap on the map or drag the marker to select your precise location. The address fields will be automatically filled.',
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
                      myLocationButtonEnabled: false,
                      mapType: MapType.normal,
                      zoomControlsEnabled: false,
                      compassEnabled: false,
                      tiltGesturesEnabled: false,
                      gestureRecognizers: {
                        Factory<OneSequenceGestureRecognizer>(
                          () => EagerGestureRecognizer(),
                        ),
                      },
                    ),

                    // Loading indicator
                    if (_isLoadingAddress)
                      Container(
                        color: Colors.black.withValues(alpha: 0.3),
                        child: const Center(
                          child: CircularProgressIndicator(
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        ),
                      ),

                    // Current location button
                    Positioned(
                      bottom: 16,
                      right: 16,
                      child: FloatingActionButton.small(
                        onPressed: _initializeLocationAndMap,
                        backgroundColor: colorScheme.surface,
                        foregroundColor: colorScheme.primary,
                        child: const Icon(Icons.my_location),
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

          const SizedBox(height: 24),

          // Default Address Toggle
          _buildDefaultAddressToggle(context),

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
        Row(
          children: [
            Expanded(
              flex: 2,
              child: OnboardingTextField(
                controller: widget.controller,
                textController: widget.controller.pincodeController,
                focusNode: widget.controller.pincodeFocus,
                label: 'Pincode',
                hint: '560001',
                icon: Icons.pin_drop_rounded,
                isRequired: true,
                keyboardType: TextInputType.number,
                onSubmitted: (_) => widget.controller.cityFocus.requestFocus(),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              flex: 3,
              child: OnboardingTextField(
                controller: widget.controller,
                textController: widget.controller.cityController,
                focusNode: widget.controller.cityFocus,
                label: 'City',
                hint: 'City name',
                icon: Icons.location_city_rounded,
                isRequired: true,
                onSubmitted: (_) => widget.controller.districtFocus.requestFocus(),
              ),
            ),
          ],
        ),

        const SizedBox(height: 16),

        // District and State Row
        Row(
          children: [
            Expanded(
              child: OnboardingTextField(
                controller: widget.controller,
                textController: widget.controller.districtController,
                focusNode: widget.controller.districtFocus,
                label: 'District',
                hint: 'District name',
                icon: Icons.map_rounded,
                isRequired: true,
                onSubmitted: (_) => widget.controller.stateFocus.requestFocus(),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: OnboardingTextField(
                controller: widget.controller,
                textController: widget.controller.stateController,
                focusNode: widget.controller.stateFocus,
                label: 'State',
                hint: 'State name',
                icon: Icons.public_rounded,
                isRequired: true,
                onSubmitted: (_) => widget.controller.phoneNumberFocus.requestFocus(),
              ),
            ),
          ],
        ),

        const SizedBox(height: 16),

        // Phone Number and Label Row
        Row(
          children: [
            Expanded(
              flex: 3,
              child: OnboardingTextField(
                controller: widget.controller,
                textController: widget.controller.phoneNumberController,
                focusNode: widget.controller.phoneNumberFocus,
                label: 'Phone (Optional)',
                hint: '+91 98765 43210',
                icon: Icons.phone_rounded,
                keyboardType: TextInputType.phone,
                onSubmitted: (_) => widget.controller.addressLabelFocus.requestFocus(),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              flex: 2,
              child: OnboardingTextField(
                controller: widget.controller,
                textController: widget.controller.addressLabelController,
                focusNode: widget.controller.addressLabelFocus,
                label: 'Label (Optional)',
                hint: 'Home, Office',
                icon: Icons.label_rounded,
                onSubmitted: (_) => widget.onNext(),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildDefaultAddressToggle(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            colorScheme.surfaceContainerLowest,
            colorScheme.surfaceContainer.withValues(alpha: 0.5),
          ],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: colorScheme.outline.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.star_rounded,
            color: colorScheme.primary,
            size: 24,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Set as Default Address',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Use this address as your primary location',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurface.withValues(alpha: 0.7),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
