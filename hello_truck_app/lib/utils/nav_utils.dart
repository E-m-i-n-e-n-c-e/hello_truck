import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:hello_truck_app/models/enums/booking_enums.dart';
import 'package:hello_truck_app/models/navigation_update.dart';
import 'package:hello_truck_app/utils/format_utils.dart';

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

const inactiveStatuses = [
  BookingStatus.completed,
  BookingStatus.cancelled,
  BookingStatus.expired,
];

bool isActive(BookingStatus s) {
  return !inactiveStatuses.contains(s);
}

bool isBeforeDropArrived(BookingStatus s) {
  return isActive(s) && statusOrder.indexOf(s) < statusOrder.indexOf(BookingStatus.dropArrived);
}

bool isBeforePickupVerified(BookingStatus s) {
  return isActive(s) && statusOrder.indexOf(s) < statusOrder.indexOf(BookingStatus.pickupVerified);
}

bool isBeforePickupArrived(BookingStatus s) {
  return isActive(s) && statusOrder.indexOf(s) < statusOrder.indexOf(BookingStatus.pickupArrived);
}

/// Check if booking can be cancelled (before pickup verified)
bool canCancelBooking(BookingStatus s) {
  return isActive(s) && statusOrder.indexOf(s) < statusOrder.indexOf(BookingStatus.pickupVerified);
}

/// Check if cancel button should show on booking card (before driver confirms)
bool showCancelOnCard(BookingStatus s) {
  return s == BookingStatus.pending || s == BookingStatus.driverAssigned;
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
  return (d / 1000.0).toDistance();
}

enum EditButtonType {
  pickup,
  drop,
  package,
}

bool showEditButton(BookingStatus status, EditButtonType type) {
  if(!isActive(status)) return false;
  if(type == EditButtonType.pickup) return isBeforePickupArrived(status);
  if(type == EditButtonType.drop) return isBeforeDropArrived(status);
  if(type == EditButtonType.package) return isBeforePickupArrived(status);

  return false;
}

bool showPolyline(BookingStatus status) {
  return status == BookingStatus.confirmed || status == BookingStatus.inTransit;
}