import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:hello_truck_app/models/saved_address.dart';
import 'package:hello_truck_app/models/place_prediction.dart';
import 'package:hello_truck_app/api/address_api.dart';
import 'package:hello_truck_app/providers/auth_providers.dart';
import 'package:hello_truck_app/providers/location_providers.dart';
import 'package:hello_truck_app/services/google_places_service.dart';
import 'package:hello_truck_app/screens/home/booking/widgets/map_selection_page.dart';
import 'package:hello_truck_app/screens/home/booking/widgets/add_or_edit_address_page.dart';
import 'package:hello_truck_app/widgets/snackbars.dart';
import 'package:hello_truck_app/providers/addresse_providers.dart';
import 'package:hello_truck_app/utils/logger.dart';

enum _SavedAddressMenuAction { edit, delete }

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

class _AddressSearchPageState extends ConsumerState<AddressSearchPage> with SingleTickerProviderStateMixin {
  final TextEditingController _searchController = TextEditingController();
  List<PlacePrediction> _predictions = [];
  bool _isLoading = false;
  late TabController _tabController; // 0: Recent, 1: Saved

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    _tabController.dispose();
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
    if (query.length < 2) {
      setState(() {
        _predictions.clear();
      });
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final position = ref.read(currentPositionStreamProvider);
      final currentPosition = position.value;
      final predictions = await GooglePlacesService.searchPlaces(
        query,
        location: currentPosition != null
            ? LatLng(currentPosition.latitude, currentPosition.longitude)
            : null,
      );
      setState(() {
        _predictions = predictions;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _predictions.clear();
      });
      AppLogger.log('Error searching places: $e');
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
              child: TabBar(
                controller: _tabController,
                tabs: const [
                  Tab(text: 'Recent'),
                  Tab(text: 'Saved'),
                ],
                indicator: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.25),
                  borderRadius: BorderRadius.circular(8),
                ),
                indicatorSize: TabBarIndicatorSize.tab,
                indicatorPadding: const EdgeInsets.only(left: 1, right: 1, top: 0, bottom: 1),
                dividerColor: Colors.transparent,
                labelStyle: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w500),
                unselectedLabelStyle: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w500),
                labelColor: Colors.black87,
                unselectedLabelColor: Colors.black87,
                overlayColor: WidgetStateProperty.all(Colors.transparent),
              ),
            ),
            const SizedBox(height: 14),
          ],

                    // Content
                    Expanded(
                      child: _searchController.text.isNotEmpty
                          ? _buildSearchResults()
                          : TabBarView(
                              controller: _tabController,
                              children: [
                                _buildRecentAddresses(),
                                _buildSavedAddresses(),
                              ],
                            ),
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

  // Removed custom tab button; using TabBar/TabBarView for swipeable tabs

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

  // Tab content handled by TabBarView

  Widget _buildRecentAddresses() {
    final savedAddressesAsync = ref.watch(savedAddressesProvider);
    final localRecentAsync = ref.watch(recentAddressesProvider);

    return savedAddressesAsync.when(
      data: (savedAddresses) {
        return localRecentAsync.when(
          data: (localRecents) {
            // Index saved addresses by formattedAddress (case-insensitive)
            final Map<String, SavedAddress> savedByFormatted = {
              for (final a in savedAddresses) a.address.formattedAddress.trim().toLowerCase(): a,
            };

            // Compose the list of up to 5 recent items, preferring saved if formattedAddress matches
            final List<SavedAddress> composed = localRecents
                .map((r) {
                  final key = r.address.formattedAddress.trim().toLowerCase();
                  return savedByFormatted[key] ?? r;
                })
                .toList();

            if (composed.isEmpty) {
              return const Center(child: Text('No recent addresses'));
            }

            return ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: composed.length,
              itemBuilder: (context, index) {
                final item = composed[index];
                return item.isLocalRecent ? _buildRecentLocalTile(item) : _buildSavedAddressTile(item, isRecentTab: true);
              },
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, stack) => Center(child: Text('Error: $error')),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => Center(child: Text('Error: $error')),
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
              return _buildAddNewTile();
            } else {
              // Rest are saved addresses
              final address = addresses[index - 1];
              return _buildSavedAddressTile(address);
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
        builder: (context) => MapSelectionPage.direct(
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

  Widget _buildSavedAddressTile(SavedAddress address, {bool isRecentTab = false}) {
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
            PopupMenuButton<_SavedAddressMenuAction>(
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: _SavedAddressMenuAction.edit,
                  child: Row(
                    children: [
                      Icon(Icons.edit, size: 18),
                      SizedBox(width: 8),
                      Text('Edit'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: _SavedAddressMenuAction.delete,
                  child: Row(
                    children: [
                      Icon(Icons.delete_outline, size: 18, color: Colors.red),
                      SizedBox(width: 8),
                      Text('Delete'),
                    ],
                  ),
                ),
              ],
              onSelected: (action) async {
                switch (action) {
                  case _SavedAddressMenuAction.edit:
                    final saved = await Navigator.push<SavedAddress>(
                      context,
                      MaterialPageRoute(
                        builder: (context) => AddOrEditAddressPage.edit(savedAddress: address),
                      ),
                    );
                    if (!mounted || saved == null) return;
                    ref.invalidate(savedAddressesProvider);
                    break;
                  case _SavedAddressMenuAction.delete:
                    final confirm = await showDialog<bool>(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text('Delete address?'),
                        content: Text('"${address.name}" will be removed. This action cannot be undone.'),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context, false),
                            child: const Text('Cancel'),
                          ),
                          TextButton(
                            onPressed: () => Navigator.pop(context, true),
                            style: TextButton.styleFrom(foregroundColor: Colors.red),
                            child: const Text('Delete'),
                          ),
                        ],
                      ),
                    );
                    if (confirm != true) return;
                    try {
                      final api = await ref.read(apiProvider.future);
                      await deleteSavedAddress(api, address.id);
                      if (!mounted) return;
                      if (isRecentTab) {
                        final service = ref.read(recentAddressesServiceProvider);
                        await service.deleteByFormattedAddress(address.address.formattedAddress);
                        ref.invalidate(recentAddressesProvider);
                      }
                      ref.invalidate(savedAddressesProvider);
                    } catch (e) {
                      if (!mounted) return;
                        SnackBars.error(context, 'Failed to delete: $e');
                    }
                    break;
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentLocalTile(SavedAddress address) {
    final textTheme = Theme.of(context).textTheme;

    return InkWell(
      onTap: () => _selectSavedAddress(address),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
        child: Row(
          children: [
            Icon(Icons.access_time, color: Colors.grey.shade600, size: 20),
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
            PopupMenuButton<int>(
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 1,
                  child: Row(
                    children: [
                      Icon(Icons.favorite_border, size: 18, color: Colors.red),
                      SizedBox(width: 8),
                      Text('Save as Favorite'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 2,
                  child: Row(
                    children: [
                      Icon(Icons.delete_outline, size: 18, color: Colors.red),
                      SizedBox(width: 8),
                      Text('Delete'),
                    ],
                  ),
                ),
              ],
              onSelected: (value) async {
                if (value == 1) {
                  // Save as favorite (prefill full details except name)
                  final saved = await Navigator.push<SavedAddress>(
                    context,
                    MaterialPageRoute(
                      builder: (context) => AddOrEditAddressPage.add(
                        initialAddress: address.address,
                        initialContactName: address.contactName,
                        initialContactPhone: address.contactPhone,
                        initialNoteToDriver: address.noteToDriver,
                        initialAddressDetails: address.address.addressDetails,
                      ),
                    ),
                  );

                  if (saved != null && mounted) {
                    ref.invalidate(recentAddressesProvider);
                    ref.invalidate(savedAddressesProvider);
                  }
                } else if (value == 2) {
                  // Confirm delete
                  final confirm = await showDialog<bool>(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text('Remove recent address?'),
                      content: Text('"${address.name}" will be removed from your recent addresses.'),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context, false),
                          child: const Text('Cancel'),
                        ),
                        TextButton(
                          onPressed: () => Navigator.pop(context, true),
                          style: TextButton.styleFrom(foregroundColor: Colors.red),
                          child: const Text('Remove'),
                        ),
                      ],
                    ),
                  );
                  if (confirm != true) return;

                  // Delete
                  try {
                    final service = ref.read(recentAddressesServiceProvider);
                    await service.deleteByFormattedAddress(address.address.formattedAddress);
                    if (!mounted) return;
                    ref.invalidate(recentAddressesProvider);
                  } catch (e) {
                    if (!mounted) return;
                    SnackBars.error(context, 'Failed to delete: $e');
                  }
                }
              },
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
            contactName: '',
            contactPhone: '',
            noteToDriver: null,
            isDefault: false,
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          );

          // Navigate to map selection page
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => MapSelectionPage.booking(
                isPickup: widget.isPickup,
                initialSavedAddress: initialSavedAddress,
                onAddressSelected: (selectedAddress) {
                  _cacheRecent(selectedAddress);
                  widget.onAddressSelected(selectedAddress);
                  // Close the address search page as well
                  Navigator.pop(context);
                },
              ),
            ),
          );
      }
    } catch (e) {
      AppLogger.log('Error selecting prediction: $e');
      if (mounted) {
        SnackBars.error(context, 'Error selecting location: $e');
      }
    }
  }

  Future<void> _selectSavedAddress(SavedAddress address) async {
    if (!mounted) return;

    // Navigate to map selection page with existing saved address
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => MapSelectionPage.booking(
          isPickup: widget.isPickup,
          initialSavedAddress: address,
          onAddressSelected: (selectedAddress) {
            widget.onAddressSelected(selectedAddress);
            _cacheRecent(selectedAddress);
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
        builder: (context) => MapSelectionPage.booking(
          isPickup: widget.isPickup,
          onAddressSelected: (address) {
            widget.onAddressSelected(address);
            _cacheRecent(address);
            Navigator.pop(context);
          },
        ),
      ),
    );
  }

  Future<void> _cacheRecent(SavedAddress address) async {
    try {
      final service = ref.read(recentAddressesServiceProvider);
      await service.addRecent(address);
      if (mounted) {
        ref.invalidate(recentAddressesProvider);
      }
    } catch (_) {}
  }
}
