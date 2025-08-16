import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:hello_truck_app/providers/location_providers.dart';
import 'package:hello_truck_app/widgets/address_search_widget.dart';
import 'package:hello_truck_app/models/saved_address.dart';

class AddressConfirmationPage extends ConsumerStatefulWidget {
  final SavedAddress savedAddress;
  final Function(SavedAddress) onConfirm;

  const AddressConfirmationPage({
    super.key,
    required this.savedAddress,
    required this.onConfirm,
  });

  @override
  ConsumerState<AddressConfirmationPage> createState() => _AddressConfirmationPageState();
}

class _AddressConfirmationPageState extends ConsumerState<AddressConfirmationPage> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _formattedAddressController;
  late final TextEditingController _addressDetailsController;
  late final TextEditingController _floorUnitController;
  late final TextEditingController _contactNameController;
  late final TextEditingController _contactPhoneController;
  late final TextEditingController _noteToDriverController;
  bool _saveThisPlace = false;

  // Map related variables
  GoogleMapController? _mapController;
  final Set<Marker> _markers = {};

  @override
  void initState() {
    super.initState();
    _formattedAddressController = TextEditingController(text: widget.savedAddress.address.formattedAddress);
    _addressDetailsController = TextEditingController(text: widget.savedAddress.address.addressDetails ?? '');
    _floorUnitController = TextEditingController();
    _contactNameController = TextEditingController(text: widget.savedAddress.contactName ?? '');
    _contactPhoneController = TextEditingController(text: widget.savedAddress.contactPhone ?? '');
    _noteToDriverController = TextEditingController(text: widget.savedAddress.noteToDriver ?? '');

    // Initialize location from coordinates if available
    _initializeLocationFromCoordinates();
  }

  @override
  void dispose() {
    _formattedAddressController.dispose();
    _addressDetailsController.dispose();
    _floorUnitController.dispose();
    _contactNameController.dispose();
    _contactPhoneController.dispose();
    _noteToDriverController.dispose();
    super.dispose();
  }

  Future<void> _initializeLocationFromCoordinates() async {
    try {
      final location = LatLng(
        widget.savedAddress.address.latitude,
        widget.savedAddress.address.longitude,
      );
      _updateLocationAndAddress(location);
    } catch (e) {
      debugPrint('Error initializing location: $e');
    }
  }

  Future<void> _updateLocationAndAddress(LatLng location) async {
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

    // Get address details from coordinates
    final locationService = ref.read(locationServiceProvider);
    final addressData = await locationService.getAddressFromLatLng(
      location.latitude,
      location.longitude,
    );

    setState(() {
    });

    // Update formatted address
    final formattedAddress = addressData['formattedAddress'] ?? '';
    _formattedAddressController.text = formattedAddress;

    // Move camera to location
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_mapController != null) {
        _mapController!.animateCamera(
          CameraUpdate.newLatLngZoom(location, 16),
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
        currentAddress: _formattedAddressController.text,
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
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: Colors.white,
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
                  'Recipient 1',
                  style: textTheme.titleLarge?.copyWith(
                    color: Colors.black.withValues(alpha: 0.85),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),

            Expanded(
              child: Form(
                key: _formKey,
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Map Container
                      Container(
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
                                compassEnabled: true,
                                tiltGesturesEnabled: false,
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
                                      child: Icon(Icons.search_rounded, size: 20, color: colorScheme.primary),
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
                                      child: Icon(Icons.my_location_rounded, size: 20, color: colorScheme.primary),
                                    ),
                                  ),
                                ),
                              ),

                              // Zoom controls (bottom right)
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
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 24),

                      // Address Form Fields
                      _buildAddressForm(context),

                      const SizedBox(height: 32),
                    ],
                  ),
                ),
              ),
            ),

            // Confirm Button
            Container(
              width: double.infinity,
              margin: const EdgeInsets.all(16),
              child: ElevatedButton(
                onPressed: _canConfirm() ? _confirmAddress : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _canConfirm()
                      ? const Color(0xFF22AAAE)
                      : Colors.grey.shade200,
                  foregroundColor: _canConfirm() ? Colors.white : Colors.grey.shade500,
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  elevation: 0,
                ),
                child: Text(
                  'Confirm',
                  style: textTheme.titleMedium?.copyWith(
                    color: _canConfirm() ? Colors.white : Colors.grey.shade500,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAddressForm(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Address Field (Non-editable, opens search)
        _buildAddressField(context),

        const SizedBox(height: 16),

        _buildTextField(
          controller: _floorUnitController,
          label: 'Address details',
          hint: 'Apartment, floor, landmark, etc.',
          maxLines: 1,
          onChanged: (value) => setState(() {}),
        ),

        const SizedBox(height: 16),

        // Contact Name
        _buildTextField(
          controller: _contactNameController,
          label: 'Contact name',
          hint: 'Name',
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Contact name is required';
            }
            return null;
          },
        ),

        const SizedBox(height: 16),

        // Contact Phone
        _buildTextField(
          controller: _contactPhoneController,
          label: 'Contact number',
          hint: 'Phone number',
          keyboardType: TextInputType.phone,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(10)],
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Contact number is required';
            }
            if (value.trim().length < 10) {
              return 'Please enter a valid phone number';
            }
            return null;
          },
        ),

        const SizedBox(height: 16),

        // Note to Driver
        _buildTextField(
          controller: _noteToDriverController,
          label: 'Note to driver',
          hint: 'Add a note to driver',
          maxLines: 2,
          onChanged: (value) => setState(() {}),

        ),

        const SizedBox(height: 16),

        // Save This Place Checkbox
        Row(
          children: [
            Expanded(
              child: Text(
                'Save this place',
                style: textTheme.bodyMedium?.copyWith(
                  color: Colors.black87,
                ),
              ),
            ),
            Transform.scale(
              scale: 1.2,
              child: Checkbox(
                value: _saveThisPlace,
                onChanged: (value) {
                  setState(() {
                    _saveThisPlace = value ?? false;
                  });
                },
                activeColor: const Color(0xFF22AAAE),
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(4),
                ),
                side: BorderSide(
                  color: Colors.grey.shade400,
                  width: 1.5,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildAddressField(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'Address',
              style: textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w500,
                color: Colors.black87,
              ),
            ),
            Text(
              ' *',
              style: textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w500,
                color: Colors.red,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        InkWell(
          onTap: _showAddressSearchModal,
          borderRadius: BorderRadius.circular(8),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: Colors.grey.shade300,
                width: 1,
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      _formattedAddressController.text.isNotEmpty
                          ? _formattedAddressController.text
                          : 'Select address',
                      style: textTheme.bodyMedium?.copyWith(
                        color: _formattedAddressController.text.isNotEmpty
                            ? Colors.black87
                            : Colors.grey.shade500,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Icon(
                    Icons.arrow_forward_ios,
                    color: Colors.grey.shade600,
                    size: 16,
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    int maxLines = 1,
    TextInputType? keyboardType,
    List<TextInputFormatter>? inputFormatters,
    String? Function(String?)? validator,
    Function(String)? onChanged,
  }) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              label,
              style: textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w500,
                color: Colors.black87,
              ),
            ),
            if (validator != null)
              Text(
                ' *',
                style: textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w500,
                  color: Colors.red,
                ),
              ),
          ],
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurface.withValues(alpha: 0.5),
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(
                color: colorScheme.outline.withValues(alpha: 0.3),
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(
                color: colorScheme.outline.withValues(alpha: 0.3),
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(
                color: colorScheme.secondary,
                width: 2,
              ),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(
                color: colorScheme.error,
              ),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(
                color: colorScheme.error,
                width: 2,
              ),
            ),
            filled: true,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 16,
            ),
          ),
          style: textTheme.bodyMedium?.copyWith(
            color: Colors.black87,
          ),
          maxLines: maxLines,
          keyboardType: keyboardType,
          inputFormatters: inputFormatters,
          validator: validator,
          onChanged: onChanged,
        ),
      ],
    );
  }

  bool _canConfirm() {
    return _contactNameController.text.trim().isNotEmpty &&
           _contactPhoneController.text.trim().isNotEmpty &&
           _contactPhoneController.text.trim().length >= 10 &&
           (_formattedAddressController.text.trim().isNotEmpty);
  }

  void _confirmAddress() {
    if (_formKey.currentState!.validate()) {
      // Get current marker position (which might have changed from dragging)
      LatLng currentLocation;
      if (_markers.isNotEmpty) {
        currentLocation = _markers.first.position;
      } else {
        // Fallback to original location if no marker
        currentLocation = LatLng(
          widget.savedAddress.address.latitude,
          widget.savedAddress.address.longitude,
        );
      }

      // Create updated address with new details and current coordinates
      final updatedAddress = Address(
        formattedAddress: _formattedAddressController.text.trim(), // Use the current formatted address
        addressDetails: _addressDetailsController.text.trim().isNotEmpty ? _addressDetailsController.text.trim() : null, // Additional details like floor/unit
        latitude: currentLocation.latitude,
        longitude: currentLocation.longitude,
      );

      // Create updated saved address
      final updatedSavedAddress = SavedAddress(
        id: widget.savedAddress.id,
        name: widget.savedAddress.name,
        address: updatedAddress,
        contactName: _contactNameController.text.trim(),
        contactPhone: _contactPhoneController.text.trim(),
        noteToDriver: _noteToDriverController.text.trim(),
        isDefault: widget.savedAddress.isDefault,
        createdAt: widget.savedAddress.createdAt,
        updatedAt: DateTime.now(),
      );

      widget.onConfirm(updatedSavedAddress);
    }
  }
}
