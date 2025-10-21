// Model for Google Places prediction
class PlacePrediction {
  final String description;
  final String placeId;
  final String? structuredFormat;

  PlacePrediction({
    required this.description,
    required this.placeId,
    this.structuredFormat,
  });

  factory PlacePrediction.fromJson(Map<String, dynamic> json) {
    // Handle both old and new API response formats
    if (json.containsKey('placePrediction')) {
      // New API format
      final placePrediction = json['placePrediction'];
      return PlacePrediction(
        description: placePrediction['text']?['text'] ?? '',
        placeId: placePrediction['placeId'] ?? '',
        structuredFormat: placePrediction['structuredFormat']?['mainText']?['text'],
      );
    } else {
      // Legacy API format
      return PlacePrediction(
        description: json['description'] ?? '',
        placeId: json['place_id'] ?? '',
        structuredFormat: json['structured_formatting']?['main_text'],
      );
    }
  }
}