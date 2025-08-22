import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:hello_truck_app/screens/onboarding/controllers/onboarding_controller.dart';
import 'package:hello_truck_app/screens/onboarding/widgets/onboarding_components.dart';
import 'package:hello_truck_app/widgets/location_permission_handler.dart';
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

    // Update formatted address
    final formattedAddress = addressData['formattedAddress'] ?? '';
    widget.controller.updateFormattedAddress(formattedAddress);

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
        currentAddress: widget.controller.formattedAddressController.text,
        onLocationSelected: (LatLng location) {
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
            title: 'Add Your First Address',
          ),

          const SizedBox(height: 12),

          OnboardingStepDescription(
            controller: widget.controller,
            description: 'Tap on the map or drag the marker to select your precise location. You can also search for an address.',
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
          if (!widget.controller.isAddressSkipped)
          _buildAddressForm(context),

          const SizedBox(height: 24),
          // Skip checkbox
          GestureDetector(
            onTap: () {
              widget.controller.setAddressSkipped(!widget.controller.isAddressSkipped);
            },
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              decoration: BoxDecoration(
                color: widget.controller.isAddressSkipped
                    ? const Color(0xFF22AAAE).withValues(alpha: 0.1)
                    : Colors.grey.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: widget.controller.isAddressSkipped
                      ? const Color(0xFF22AAAE).withValues(alpha: 0.5)
                      : Colors.grey.shade300,
                  width: 1,
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      'Skip for now',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: widget.controller.isAddressSkipped
                            ? Theme.of(context).colorScheme.primary
                            : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.8),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  Transform.scale(
                    scale: 1.2,
                    child: Checkbox(
                      value: widget.controller.isAddressSkipped,
                      onChanged: (value) {
                        widget.controller.setAddressSkipped(value ?? false);
                      },
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(4),
                      ),
                      side: BorderSide(
                        color: widget.controller.isAddressSkipped
                            ? const Color(0xFF22AAAE)
                            : Colors.grey.shade400,
                        width: 1.5,
                      ),
                      activeColor: const Color(0xFF22AAAE),
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildAddressForm(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Address Name (Required)
        OnboardingTextField(
          controller: widget.controller,
          textController: widget.controller.addressNameController,
          focusNode: widget.controller.addressNameFocus,
          label: 'Address Name',
          hint: 'Home, Office, etc.',
          icon: Icons.label_rounded,
          isRequired: true,
          onSubmitted: (_) => _showAddressSearchModal(),
        ),

        const SizedBox(height: 16),

        // Address Field (Non-editable, opens search)
        OnboardingAddressField(
          controller: widget.controller,
          label: 'Address',
          hint: 'Tap to search and select your address',
          icon: Icons.location_on_rounded,
          isRequired: true,
          onTap: _showAddressSearchModal,
        ),

        const SizedBox(height: 16),

        // Address Details (Optional)
        OnboardingTextField(
          controller: widget.controller,
          textController: widget.controller.addressDetailsController,
          focusNode: widget.controller.addressDetailsFocus,
          label: 'Address Details',
          hint: 'Apartment, floor, landmark, etc.',
          icon: Icons.home_rounded,
          maxLines: 2,
          onSubmitted: (_) => widget.controller.contactNameFocus.requestFocus(),
        ),

        const SizedBox(height: 24),

        // Divider
        Divider(color: colorScheme.primary.withValues(alpha: 0.6)),
        const SizedBox(height: 16),

        // Contact Details Section
        Padding(
          padding: const EdgeInsets.only(left: 8),
          child: Text(
            'Contact Details',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
              color: colorScheme.onSurface,
            ),
          ),
        ),

        const SizedBox(height: 16),

        // Contact Name
        OnboardingTextField(
          controller: widget.controller,
          textController: widget.controller.contactNameController,
          focusNode: widget.controller.contactNameFocus,
          label: 'Contact Name',
          hint: 'Name of person at this address',
          icon: Icons.person_rounded,
          isRequired: true,
          onSubmitted: (_) => widget.controller.contactPhoneFocus.requestFocus(),
        ),

        const SizedBox(height: 16),

        // Contact Phone
        OnboardingTextField(
          controller: widget.controller,
          textController: widget.controller.contactPhoneController,
          focusNode: widget.controller.contactPhoneFocus,
          label: 'Contact Phone',
          hint: 'Phone number',
          icon: Icons.phone_rounded,
          keyboardType: TextInputType.phone,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(10)],
          isRequired: true,
          onSubmitted: (_) => widget.controller.noteToDriverFocus.requestFocus(),
        ),

        const SizedBox(height: 24),

        // Driver Note Section
        Padding(
          padding: const EdgeInsets.only(left: 8),
          child: Text(
            'Note to Driver',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
              color: colorScheme.onSurface,
            ),
          ),
        ),

        const SizedBox(height: 16),

        // Note to Driver
        OnboardingTextField(
          controller: widget.controller,
          textController: widget.controller.noteToDriverController,
          focusNode: widget.controller.noteToDriverFocus,
          label: 'Note to Driver',
          hint: 'Any special instructions for the driver',
          icon: Icons.note_rounded,
          maxLines: 2,
          onSubmitted: (_) => widget.onNext(),
        ),
      ],
    );
  }
}