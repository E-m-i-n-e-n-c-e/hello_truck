
class DriverNavigationUpdate {
  final String bookingId;
  final int timeToPickup;
  final int timeToDrop;
  final int distanceToPickup;
  final int distanceToDrop;
  final int initialDistanceToPickup;
  final int kmTravelled;
  final Location? location;
  final String? routePolyline;
  bool isStale;
  final DateTime sentAt;

  DriverNavigationUpdate({
    required this.bookingId,
    required this.timeToPickup,
    required this.timeToDrop,
    required this.distanceToPickup,
    required this.distanceToDrop,
    required this.initialDistanceToPickup,
    required this.kmTravelled,
    required this.location,
    required this.routePolyline,
    this.isStale = false,
    required this.sentAt,
  });

  factory DriverNavigationUpdate.fromJson(Map<String, dynamic> json, {required String bookingId}) {
    return DriverNavigationUpdate(
      bookingId: json['bookingId'],
      timeToPickup: json['timeToPickup'].toInt(),
      timeToDrop: json['timeToDrop'].toInt(),
      distanceToPickup: json['distanceToPickup'].toInt(),
      distanceToDrop: json['distanceToDrop'].toInt(),
      initialDistanceToPickup: json['initialDistanceToPickup']?.toInt() ?? json['distanceToPickup']?.toInt() ?? 0,
      kmTravelled: json['kmTravelled']?.toInt() ?? 0,
      location: json['location'] != null ? Location.fromJson(json['location']) : null,
      routePolyline: json['routePolyline'],
      sentAt: json['sentAt'] != null ? DateTime.parse(json['sentAt']) : DateTime.now(),

      // data is stale if the booking id is different from the current booking id
      isStale: bookingId != json['bookingId'],
    );
  }
}

class Location {
  final double latitude;
  final double longitude;

  Location({
    required this.latitude,
    required this.longitude,
  });

  factory Location.fromJson(Map<String, dynamic> json) {
    return Location(
      latitude: json['latitude']?.toDouble(),
      longitude: json['longitude']?.toDouble(),
    );
  }
}