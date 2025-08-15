import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hello_truck_app/models/saved_address.dart';
import 'package:hello_truck_app/models/place_prediction.dart';
import 'package:hello_truck_app/api/address_api.dart';
import 'package:hello_truck_app/providers/auth_providers.dart';
import 'package:hello_truck_app/services/google_places_service.dart';
import 'package:hello_truck_app/screens/home/booking/widgets/contact_details_dialog.dart';
import 'package:hello_truck_app/screens/home/booking/widgets/save_address_dialog.dart';
import 'package:hello_truck_app/screens/home/booking/widgets/map_selection_page.dart';
import 'package:hello_truck_app/widgets/snackbars.dart';

// Provider for saved addresses
final savedAddressesProvider = FutureProvider.autoDispose<List<SavedAddress>>((ref) async {
  final api = await ref.watch(apiProvider.future);
  return getSavedAddresses(api);
});

class AddressSearchPage extends ConsumerStatefulWidget {
  final bool isPickup;
  final Function(SavedAddress) onAddressSelected;
  final String title;

  const AddressSearchPage({
    super.key,
    required this.isPickup,
    required this.onAddressSelected,
  }): title = isPickup ? 'Pickup Address' : 'Drop Address';

  @override
  ConsumerState<AddressSearchPage> createState() =>
      _AddressSearchPageState();
}

class _AddressSearchPageState extends ConsumerState<AddressSearchPage> {
  final TextEditingController _searchController = TextEditingController();
  List<PlacePrediction> _predictions = [];
  bool _isLoading = false;
  int _selectedTabIndex = 0; // 0: Recent, 1: Suggested, 2: Saved

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    if (_searchController.text.isNotEmpty) {
      _searchPlaces(_searchController.text);
    } else {
      setState(() {
        _predictions.clear();
      });
    }
  }

  Future<void> _searchPlaces(String query) async {
    if (query.length < 3) {
      setState(() {
        _predictions.clear();
      });
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final predictions = await GooglePlacesService.searchPlaces(query);
      setState(() {
        _predictions = predictions;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _predictions.clear();
      });
      print('Error searching places: $e');
    }
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
                  widget.title,
                  style: textTheme.titleLarge?.copyWith(
                    color: Colors.black.withValues(alpha: 0.85),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),

          const SizedBox(height: 16),

          // Search Bar
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: colorScheme.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: colorScheme.outline.withValues(alpha: 0.3),
              ),
            ),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search for area, street name...',
                hintStyle: textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurface.withValues(alpha: 0.5),
                ),
                prefixIcon: Icon(Icons.search, color: colorScheme.primary),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 16,
                ),
              ),
              style: textTheme.bodyMedium,
            ),
          ),

          const SizedBox(height: 20),

          // Tab Bar
          if (_searchController.text.isEmpty) ...[
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  _buildTabButton('Recent', 0),
                  _buildTabButton('Suggested', 1),
                  _buildTabButton('Saved', 2),
                ],
              ),
            ),
            const SizedBox(height: 20),
          ],

                    // Content
                    Expanded(
                      child: _searchController.text.isNotEmpty
                          ? _buildSearchResults()
                          : _buildTabContent(),
                    ),

                    // Choose on Map button
                    Padding(
                      padding: const EdgeInsets.only(bottom: 40.0),
                      child: TextButton.icon(
                        onPressed: _openMapSelection,
                        icon: Icon(
                          Icons.map,
                          color: colorScheme.secondary.withValues(alpha: 0.8),
                        ),
                        label: Text(
                          'Choose on Map',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            color: colorScheme.secondary.withValues(alpha: 0.8),
                          ),
                        ),
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
  }

  Widget _buildTabButton(String title, int index) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final isSelected = _selectedTabIndex == index;

    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            _selectedTabIndex = index;
          });
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: isSelected ? colorScheme.primary : Colors.transparent,
                width: 2,
              ),
            ),
          ),
          child: Text(
            title,
            textAlign: TextAlign.center,
            style: textTheme.titleMedium?.copyWith(
              color: isSelected
                  ? colorScheme.primary
                  : colorScheme.onSurface.withValues(alpha: 0.6),
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSearchResults() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_predictions.isEmpty) {
      return Center(
        child: Text(
          'No results found',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: Theme.of(
              context,
            ).colorScheme.onSurface.withValues(alpha: 0.6),
          ),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: _predictions.length,
      itemBuilder: (context, index) {
        final prediction = _predictions[index];
        return _buildPredictionTile(prediction);
      },
    );
  }

  Widget _buildTabContent() {
    switch (_selectedTabIndex) {
      case 0: // Recent
        return _buildRecentAddresses();
      case 1: // Suggested
        return _buildSuggestedAddresses();
      case 2: // Saved
        return _buildSavedAddresses();
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildRecentAddresses() {
    final savedAddressesAsync = ref.watch(savedAddressesProvider);

    return savedAddressesAsync.when(
      data: (addresses) {
        final recentAddresses = addresses.take(3).toList();
        if (recentAddresses.isEmpty) {
          return const Center(child: Text('No recent addresses'));
        }

        return ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          itemCount: recentAddresses.length,
          itemBuilder: (context, index) {
            final address = recentAddresses[index];
            return _buildSavedAddressTile(address);
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) =>
          Center(child: Text('Error loading addresses: $error')),
    );
  }

  Widget _buildSuggestedAddresses() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          _buildSuggestedTile(
            icon: Icons.add,
            title: 'Add new',
            subtitle: '',
            color: Theme.of(context).colorScheme.primary,
            onTap: () {
              // TODO: Add new address functionality
            },
          ),
          const SizedBox(height: 12),
          _buildSuggestedTile(
            icon: Icons.home,
            title: 'Add home',
            subtitle: '',
            color: Colors.orange,
            onTap: () {
              // TODO: Add home address functionality
            },
          ),
          const SizedBox(height: 12),
          _buildSuggestedTile(
            icon: Icons.work,
            title: 'Add work',
            subtitle: '',
            color: Colors.blue,
            onTap: () {
              // TODO: Add work address functionality
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSavedAddresses() {
    final savedAddressesAsync = ref.watch(savedAddressesProvider);

    return savedAddressesAsync.when(
      data: (addresses) {
        if (addresses.isEmpty) {
          return const Center(child: Text('No saved addresses'));
        }

        return ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          itemCount: addresses.length,
          itemBuilder: (context, index) {
            final address = addresses[index];
            return _buildSavedAddressTile(address);
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) =>
          Center(child: Text('Error loading addresses: $error')),
    );
  }

  Widget _buildPredictionTile(PlacePrediction prediction) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return InkWell(
      onTap: () => _selectPrediction(prediction),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: colorScheme.outline.withValues(alpha: 0.2),
            ),
          ),
        ),
        child: Row(
          children: [
            Icon(
              Icons.location_on,
              color: colorScheme.onSurface.withValues(alpha: 0.6),
              size: 20,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    prediction.structuredFormat ??
                        prediction.description.split(',').first,
                    style: textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    prediction.description,
                    style: textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurface.withValues(alpha: 0.6),
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
    );
  }

  Widget _buildSavedAddressTile(SavedAddress address) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return InkWell(
      onTap: () => _selectSavedAddress(address),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: colorScheme.outline.withValues(alpha: 0.2),
            ),
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.red.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.favorite, color: Colors.red, size: 16),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    address.name,
                    style: textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    address.address.formattedAddress,
                    style: textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurface.withValues(alpha: 0.6),
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            Icon(
              Icons.edit,
              color: colorScheme.onSurface.withValues(alpha: 0.4),
              size: 20,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSuggestedTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    final textTheme = Theme.of(context).textTheme;

    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
        child: Row(
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                title,
                style: textTheme.titleMedium?.copyWith(
                  color: color,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _selectPrediction(PlacePrediction prediction) async {
    if (!mounted) return;

    try {
      final placeDetails = await GooglePlacesService.getPlaceDetails(
        prediction.placeId,
      );
      if (placeDetails != null && mounted) {
        // Show contact details dialog for new address
        final contactDetails = await showDialog<Map<String, String>>(
          context: context,
          builder: (context) => ContactDetailsDialog(
            addressName:
                prediction.structuredFormat ??
                prediction.description.split(',').first,
          ),
        );

        if (contactDetails != null && mounted) {
          // Create address object
          final address = Address(
            formattedAddress: prediction.description,
            latitude: placeDetails.latitude,
            longitude: placeDetails.longitude,
          );

          // Check if user wants to save this address
          final shouldSave = await showDialog<bool>(
            context: context,
            builder: (context) => SaveAddressDialog(
              addressName:
                  prediction.structuredFormat ??
                  prediction.description.split(',').first,
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
                    prediction.structuredFormat ??
                    prediction.description.split(',').first,
                address: address,
                contactName: contactDetails['contactName'],
                contactPhone: contactDetails['contactPhone'],
                noteToDriver: contactDetails['noteToDriver'],
              );
              ref.invalidate(savedAddressesProvider);
            } catch (e) {
              if (mounted) {
                SnackBars.error(context, 'Error saving address: $e');
              }
              return;
            }
          } else {
            // Create temporary saved address without saving to backend
            savedAddress = SavedAddress(
              id: '', // Will be set by the backend
              name:
                  prediction.structuredFormat ??
                  prediction.description.split(',').first,
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
      }
    } catch (e) {
      print('Error selecting prediction: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error selecting location: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _selectSavedAddress(SavedAddress address) async {
    if (!mounted) return;

    // Show contact details dialog with pre-filled data
    final contactDetails = await showDialog<Map<String, String>>(
      context: context,
      builder: (context) => ContactDetailsDialog(
        addressName: address.name,
        initialContactName: address.contactName,
        initialContactPhone: address.contactPhone,
        initialNoteToDriver: address.noteToDriver,
      ),
    );

    if (contactDetails != null && mounted) {
      // Update the address with new contact details
      final updatedAddress = SavedAddress(
        id: address.id,
        name: address.name,
        address: address.address,
        contactName: contactDetails['contactName'],
        contactPhone: contactDetails['contactPhone'],
        noteToDriver: contactDetails['noteToDriver'],
        isDefault: address.isDefault,
        createdAt: address.createdAt,
        updatedAt: DateTime.now(),
      );

      widget.onAddressSelected(updatedAddress);
      if (mounted) {
        Navigator.pop(context);
      }
    }
  }

  void _openMapSelection() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => MapSelectionPage(
          isPickup: widget.isPickup,
          onAddressSelected: (address) {
            widget.onAddressSelected(address);
            Navigator.pop(context);
          },
        ),
      ),
    );
  }
}
