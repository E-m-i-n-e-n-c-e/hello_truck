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
    return PlacePrediction(
      description: json['description'] ?? '',
      placeId: json['place_id'] ?? '',
      structuredFormat: json['structured_formatting']?['main_text'],
    );
  }
}