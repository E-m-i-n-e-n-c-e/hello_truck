import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:hello_truck_app/models/enums/booking_enums.dart';
import 'package:hello_truck_app/models/navigation_update.dart';

/// Decode an encoded polyline string using flutter_polyline_points
/// into a list of Google Maps `LatLng`.
List<LatLng> decodePolyline(String? encoded) {
  if (encoded == null || encoded.isEmpty) return [];
  final points = PolylinePoints().decodePolyline(encoded);
  return points.map((p) => LatLng(p.latitude, p.longitude)).toList();
}

const statusOrder = [
  BookingStatus.pending,
  BookingStatus.driverAssigned,
  BookingStatus.confirmed,
  BookingStatus.pickupArrived,
  BookingStatus.pickupVerified,
  BookingStatus.inTransit,
  BookingStatus.dropArrived,
  BookingStatus.dropVerified,
  BookingStatus.completed,
];

bool isBeforeDropArrived(BookingStatus s) {
  return statusOrder.indexOf(s) < statusOrder.indexOf(BookingStatus.dropVerified);
}

bool isBeforePickupVerified(BookingStatus s) {
  return statusOrder.indexOf(s) < statusOrder.indexOf(BookingStatus.pickupVerified);
}

String getBookingTitle(BookingStatus status) {
  switch (status) {
    case BookingStatus.completed:
      return 'Booking completed';
    case BookingStatus.cancelled:
    case BookingStatus.expired:
      return 'Booking cancelled';
    case BookingStatus.pending:
    case BookingStatus.driverAssigned:
      return 'Looking for a driver';
    case BookingStatus.confirmed:
      return 'Driver is on the way to pickup';
    case BookingStatus.pickupArrived:
      return 'Driver has arrived at pickup';
    case BookingStatus.pickupVerified:
      return 'Parcel has been picked up';
    case BookingStatus.inTransit:
      return 'Driver is on the way to drop';
    case BookingStatus.dropArrived:
      return 'Driver has arrived at drop';
    case BookingStatus.dropVerified:
      return 'Parcel has been delivered';
  }
}

String arrivalLabel(BookingStatus status, DriverNavigationUpdate? u) {
  if(status == BookingStatus.completed) return 'Completed';
  if(status == BookingStatus.cancelled) return 'Cancelled';
  if(status == BookingStatus.expired) return 'Expired';

  if(status == BookingStatus.pickupArrived || status == BookingStatus.pickupVerified) return 'Reached';
  if(status == BookingStatus.dropArrived || status == BookingStatus.dropVerified) return 'Reached';

  if(u == null) return 'Getting your driver ready';
  if(u.isStale) return 'Getting your driver ready';

  final t = isBeforePickupVerified(status) ? u.timeToPickup : u.timeToDrop; // in seconds
  final formattedTime = formatTime(t);
  if (t >= 3600) {
    return 'Arriving in $formattedTime';
  }
  if (t < 60) return 'Almost there';
  return 'Reaching in $formattedTime';
}

// Here we include both pickup/drop and time labels
String tileLabel(BookingStatus status, DriverNavigationUpdate? u) {
  if(status == BookingStatus.completed) return 'Booking completed';
  if(status == BookingStatus.cancelled) return 'Booking cancelled';
  if(status == BookingStatus.expired) return 'Booking expired';

  if(status == BookingStatus.pending || status == BookingStatus.driverAssigned) return 'Looking for a driver';

  if(status == BookingStatus.pickupArrived || status == BookingStatus.pickupVerified) return 'Reached pickup';
  if(status == BookingStatus.dropArrived || status == BookingStatus.dropVerified) return 'Reached drop';

  if(u == null) return 'Getting your driver ready';
  if(u.isStale) return 'Getting your driver ready';

  final isPickup = isBeforePickupVerified(status);
  final t = isPickup ? u.timeToPickup : u.timeToDrop;
  final formattedTime = formatTime(t);
  return t >= 3600
      ? 'Arriving at ${isPickup ? 'pickup' : 'drop'} in $formattedTime'
      : 'Reaching ${isPickup ? 'pickup' : 'drop'} in $formattedTime';
}

// in seconds
String formatTime(int t) {
  if(t >= 3600) {
    final hours = t ~/ 3600;
    final mins = (t % 3600) ~/ 60;
    if(mins == 0) {
      return '$hours hour${hours == 1 ? '' : 's'}';
    } else {
      return '$hours hour${hours == 1 ? '' : 's'} $mins min${mins == 1 ? '' : 's'}';
    }
  }
  if(t < 120) return '1 min';
  return '${t ~/ 60} mins';
}

// in meters
String formatDistance(int d) {
  if(d >= 1000) {
    double km = d / 1000;
    return '${km == km.toInt() ? km.toInt() : km.toStringAsFixed(1)} km';
  }
  return '$d m';
}