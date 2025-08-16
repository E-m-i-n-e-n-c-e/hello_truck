import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hello_truck_app/models/saved_address.dart';
import 'package:hello_truck_app/models/place_prediction.dart';
import 'package:hello_truck_app/api/address_api.dart';
import 'package:hello_truck_app/providers/auth_providers.dart';
import 'package:hello_truck_app/services/google_places_service.dart';
import 'package:hello_truck_app/screens/home/booking/widgets/map_selection_page.dart';
import 'package:hello_truck_app/screens/home/booking/widgets/add_or_edit_address_page.dart';

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
  int _selectedTabIndex = 0; // 0: Recent, 1: Saved

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
                  _buildTabButton('Saved', 1),
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
                      child: InkWell(
                        onTap: _openMapSelection,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.map,
                                size: Theme.of(context).textTheme.titleLarge?.fontSize,
                                color: colorScheme.secondary.withValues(alpha: 0.8),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Choose on Map',
                                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                  color: colorScheme.secondary.withValues(alpha: 0.8),
                                ),
                              ),
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

  Widget _buildTabButton(String title, int index) {
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
            color: isSelected ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.25) : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            title,
            textAlign: TextAlign.center,
            style: textTheme.titleMedium?.copyWith(
              color: Colors.black87,
              fontWeight: FontWeight.w500,
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
      case 1: // Saved
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



  Widget _buildSavedAddresses() {
    final savedAddressesAsync = ref.watch(savedAddressesProvider);

    return savedAddressesAsync.when(
      data: (addresses) {
        return ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          itemCount: addresses.length + 1, // +1 for "Add new" option
          itemBuilder: (context, index) {
            if (index == 0) {
              // First item is "Add new"
              return Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: _buildAddNewTile(),
              );
            } else {
              // Rest are saved addresses
              final address = addresses[index - 1];
              return Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: _buildSavedAddressTile(address),
              );
            }
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

  Widget _buildAddNewTile() {
    final textTheme = Theme.of(context).textTheme;

    return InkWell(
      onTap: () {
        _onAddNewAddress();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
        child: Row(
          children: [
            Icon(Icons.add, color: Colors.blue, size: 24),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                'Add new',
                style: textTheme.titleMedium?.copyWith(
                  color: Colors.blue,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _onAddNewAddress() async {
    // 1) Open map in direct mode to pick address
    final address = await Navigator.push<Address>(
      context,
      MaterialPageRoute(
        builder: (context) => MapSelectionPage(
          mode: MapSelectionMode.direct,
        ),
      ),
    );

    if (!mounted || address == null) return;

    // 2) Open the add-address form prefilled with the picked address
    final saved = await Navigator.push<SavedAddress>(
      context,
      MaterialPageRoute(
        builder: (context) => AddOrEditAddressPage.add(initialAddress: address),
      ),
    );

    if (!mounted || saved == null) return;

    // 3) Just refresh the saved addresses list
    ref.invalidate(savedAddressesProvider);
  }

  Widget _buildSavedAddressTile(SavedAddress address) {
    final textTheme = Theme.of(context).textTheme;

    return InkWell(
      onTap: () => _selectSavedAddress(address),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
        child: Row(
          children: [
            const Icon(Icons.favorite, color: Colors.red, size: 20),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    address.name,
                    style: textTheme.titleMedium?.copyWith(
                      color: Colors.black87,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    address.address.formattedAddress,
                    style: textTheme.bodySmall?.copyWith(
                      color: Colors.grey.shade600,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            InkWell(
              onTap: () async {
                // Open edit page
                final updated = await Navigator.push<SavedAddress>(
                  context,
                  MaterialPageRoute(
                    builder: (context) => AddOrEditAddressPage.edit(savedAddress: address),
                  ),
                );
                if (updated != null && mounted) {
                  ref.invalidate(savedAddressesProvider);
                }
              },
              borderRadius: BorderRadius.circular(20),
              child: Padding(
                padding: const EdgeInsets.all(4),
                child: Icon(
                  Icons.edit,
                  color: Colors.grey.shade400,
                  size: 20,
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
          // Create initial saved address for map selection
          final initialAddress = Address(
            formattedAddress: prediction.description,
            latitude: placeDetails.latitude,
            longitude: placeDetails.longitude,
          );

          final initialSavedAddress = SavedAddress(
            id: '',
            name: prediction.structuredFormat ?? prediction.description.split(',').first,
            address: initialAddress,
            contactName: null,
            contactPhone: null,
            noteToDriver: null,
            isDefault: false,
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          );

          // Navigate to map selection page
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => MapSelectionPage(
                isPickup: widget.isPickup,
                initialSavedAddress: initialSavedAddress,
                onAddressSelected: (selectedAddress) {
                  widget.onAddressSelected(selectedAddress);
                  // Close the address search page as well
                  Navigator.pop(context);
                },
              ),
            ),
          );
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

    // Navigate to map selection page with existing saved address
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => MapSelectionPage(
          isPickup: widget.isPickup,
          initialSavedAddress: address,
          onAddressSelected: (selectedAddress) {
            widget.onAddressSelected(selectedAddress);
            // Close the address search page as well
            Navigator.pop(context);
          },
        ),
      ),
    );
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
