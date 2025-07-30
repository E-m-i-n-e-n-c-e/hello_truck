import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../models/place_prediction.dart';
import '../services/google_places_service.dart';

class AddressSearchWidget extends StatefulWidget {
  final String currentAddress;
  final Function(LatLng, String) onLocationSelected;
  final String? title;
  final bool showBackButton;

  const AddressSearchWidget({
    super.key,
    required this.currentAddress,
    required this.onLocationSelected,
    this.title,
    this.showBackButton = true,
  });

  @override
  State<AddressSearchWidget> createState() => _AddressSearchWidgetState();
}

class _AddressSearchWidgetState extends State<AddressSearchWidget> {
  final TextEditingController _controller = TextEditingController();
  List<PlacePrediction> _predictions = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _controller.text = widget.currentAddress;
    _controller.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _controller.removeListener(_onSearchChanged);
    _controller.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    if (_controller.text.isNotEmpty) {
      _searchPlaces(_controller.text);
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
    }
  }

  Future<void> _onPredictionTapped(PlacePrediction prediction) async {
    setState(() {
      _isLoading = true;
    });

    final LatLng? location = await GooglePlacesService.getPlaceDetails(prediction.placeId);

    setState(() {
      _isLoading = false;
    });

    if (location != null) {
      widget.onLocationSelected(location, prediction.description);
      if (mounted) {
        Navigator.pop(context);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.9,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      child: Column(
        children: [
          // Handle bar
          Container(
            margin: const EdgeInsets.symmetric(vertical: 12),
            width: 50,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: Row(
              children: [
                if (widget.showBackButton)
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.arrow_back),
                  ),
                const SizedBox(width: 10),
                Text(
                  widget.title ?? 'Search for Address',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),

          // Search field
          Padding(
            padding: const EdgeInsets.all(20),
            child: TextField(
              controller: _controller,
              decoration: InputDecoration(
                hintText: 'Search for location...',
                prefixIcon: const Icon(Icons.search, color: Color(0xFF22AAAE)),
                suffixIcon: _isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: Padding(
                          padding: EdgeInsets.all(12),
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Color(0xFF22AAAE),
                          ),
                        ),
                      )
                    : _controller.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              _controller.clear();
                              setState(() {
                                _predictions.clear();
                              });
                            },
                          )
                        : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFF22AAAE), width: 2),
                ),
                filled: true,
                fillColor: Colors.grey.shade50,
              ),
              onSubmitted: (value) {
                if (value.isNotEmpty) {
                  _searchPlaces(value);
                }
              },
            ),
          ),

          // Results
          Expanded(
            child: _predictions.isEmpty && !_isLoading
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.search,
                          size: 64,
                          color: Colors.grey.shade400,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Start typing to search for locations',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    itemCount: _predictions.length,
                    itemBuilder: (context, index) {
                      final prediction = _predictions[index];
                      return InkWell(
                        onTap: () => _onPredictionTapped(prediction),
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          child: Row(
                            children: [
                              const Icon(Icons.location_on, color: Colors.grey),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      prediction.structuredFormat ?? prediction.description.split(',').first,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w600,
                                        fontSize: 16,
                                      ),
                                    ),
                                    if (prediction.structuredFormat != null)
                                      const SizedBox(height: 2),
                                    Text(
                                      prediction.description,
                                      style: TextStyle(
                                        color: Colors.grey.shade600,
                                        fontSize: 14,
                                      ),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
                              ),
                              const Icon(Icons.north_west, color: Colors.grey, size: 16),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}