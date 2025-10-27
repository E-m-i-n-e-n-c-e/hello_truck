# Hello Truck - Booking Flow Documentation

## Overview
This document describes the complete booking flow, UI states, and technical implementation details for the Hello Truck application. It covers all possible booking statuses, what gets displayed at each stage, and how the system handles edge cases like stale updates and driver assignment states.

## Booking Status Flow

### Status Progression
```
PENDING → DRIVER_ASSIGNED → CONFIRMED → PICKUP_ARRIVED → PICKUP_VERIFIED → IN_TRANSIT → DROP_ARRIVED → DROP_VERIFIED → COMPLETED
```

### Terminal Statuses
- `CANCELLED` - Booking was cancelled
- `EXPIRED` - Booking expired (timeout)
- `COMPLETED` - Booking successfully completed

## Bookings List Screen Behavior

**Important Note**: The bookings list screen NEVER shows driver details (name, photo, score). Instead, for active rides with available navigation data, it shows:
- **Distance to drop**: "Distance to drop: X.X km" or "Distance to drop: X m"
- **Time to drop**: "Time to drop: X hours Y mins" or "Time to drop: X mins"

This information is only displayed when:
- Booking status is active (not completed/cancelled/expired)
- Navigation update data is available and not stale
- Booking is before drop arrival

## Detailed Status Scenarios

### 1. PENDING
**Description**: Booking created, waiting for driver assignment

**UI Elements Shown**:
- ✅ Pickup marker (green)
- ✅ Drop marker (red)
- ❌ Driver marker
- ❌ Route polyline
- ❌ Driver card
- ✅ Edit buttons (pickup, drop, package)

**Booking Details Screen**:
- Title: "Looking for a driver"
- ETA Label: "Getting your driver ready"
- Payment banner visible
- Driver card hidden

**Bookings List Screen**:
- Status: "Looking for a driver"
- No ETA information
- No driver details

**Technical Notes**:
- No navigation stream active
- No driver information available
- All edit operations allowed

---

### 2. DRIVER_ASSIGNED
**Description**: Driver assigned but not yet confirmed (driver hasn't accepted)

**UI Elements Shown**:
- ✅ Pickup marker (green)
- ✅ Drop marker (red)
- ❌ Driver marker
- ❌ Route polyline
- ❌ Driver card (hidden until confirmed)
- ✅ Edit buttons (pickup, drop, package)

**Booking Details Screen**:
- Title: "Looking for a driver"
- ETA Label: "Getting your driver ready"
- Payment banner visible
- Driver card hidden (driver not shown until confirmed)

**Bookings List Screen**:
- Status: "Looking for a driver"
- No ETA information
- No driver details

**Technical Notes**:
- Driver exists in backend but not shown to user
- `shouldShowDriver = bookingStatus != BookingStatus.driverAssigned && json['assignedDriver'] != null`
- No navigation stream active
- All edit operations still allowed

---

### 3. CONFIRMED
**Description**: Driver confirmed and is on the way to pickup

**UI Elements Shown**:
- ✅ Pickup marker (green)
- ✅ Drop marker (red)
- ✅ Driver marker (truck icon)
- ✅ Route polyline (if available)
- ✅ Driver card
- ✅ Edit buttons (pickup, drop, package)

**Booking Details Screen**:
- Title: "Driver is on the way to pickup"
- ETA Label: "Arriving at pickup in X mins" or "Reaching pickup in X mins"
- Payment banner visible
- Driver card visible with driver details

**Bookings List Screen**:
- Status: "Arriving at pickup in X mins" or "Reaching pickup in X mins"
- ETA information available
- Driver details shown

**Technical Notes**:
- Navigation stream active
- Driver location updates in real-time
- Route polyline shows path to pickup
- Edit operations still allowed

---

### 4. PICKUP_ARRIVED
**Description**: Driver has arrived at pickup location

**UI Elements Shown**:
- ✅ Pickup marker (green)
- ✅ Drop marker (red)
- ✅ Driver marker (truck icon)
- ❌ Route polyline
- ✅ Driver card
- ✅ Edit buttons (pickup, drop, package)

**Booking Details Screen**:
- Title: "Driver has arrived at pickup"
- ETA Label: "Reached"
- Payment banner visible
- Driver card visible

**Bookings List Screen**:
- Status: "Reached pickup"
- No ETA information
- Driver details shown

**Technical Notes**:
- Navigation stream still active
- Driver location at pickup point
- Pickup address is no longer editable

---

### 5. PICKUP_VERIFIED
**Description**: Parcel has been picked up and verified

**UI Elements Shown**:
- ❌ Pickup marker (removed)
- ✅ Drop marker (red)
- ✅ Driver marker (truck icon)
- ❌ Route polyline
- ✅ Driver card
- ❌ Edit buttons (pickup, package)
- ✅ Edit button (drop only)

**Booking Details Screen**:
- Title: "Parcel has been picked up"
- ETA Label: "Reached"
- Payment banner visible
- Driver card visible

**Bookings List Screen**:
- Status: "Reached pickup"
- No ETA information
- Driver details shown

**Technical Notes**:
- Pickup marker removed from map
- Map focuses on drop location
- Only drop address can be edited
- Navigation stream still active

---

### 6. IN_TRANSIT
**Description**: Driver is on the way to drop location

**UI Elements Shown**:
- ❌ Pickup marker (removed)
- ✅ Drop marker (red)
- ✅ Driver marker (truck icon)
- ✅ Route polyline
- ✅ Driver card
- ❌ Edit buttons (pickup, package)
- ✅ Edit button (drop only)

**Booking Details Screen**:
- Title: "Driver is on the way to drop"
- ETA Label: "Arriving at drop in X mins" or "Reaching drop in X mins"
- Payment banner visible
- Driver card visible

**Bookings List Screen**:
- Status: "Arriving at drop in X mins" or "Reaching drop in X mins"
- ETA information available
- Driver details shown

**Technical Notes**:
- Navigation stream active
- Route polyline shows path to drop
- Only drop address can be edited

---

### 7. DROP_ARRIVED
**Description**: Driver has arrived at drop location

**UI Elements Shown**:
- ❌ Pickup marker (removed)
- ✅ Drop marker (red)
- ✅ Driver marker (truck icon)
- ❌ Route polyline
- ✅ Driver card
- ❌ Edit buttons (pickup, package)
- ❌ Edit button (drop)

**Booking Details Screen**:
- Title: "Driver has arrived at drop"
- ETA Label: "Reached"
- Payment banner visible
- Driver card visible

**Bookings List Screen**:
- Status: "Reached drop"
- No ETA information
- Driver details shown

**Technical Notes**:
- Navigation stream still active
- Driver location at drop point
- No edit operations allowed

---

### 8. DROP_VERIFIED
**Description**: Parcel has been delivered and verified

**UI Elements Shown**:
- ❌ Pickup marker (removed)
- ✅ Drop marker (red)
- ✅ Driver marker (truck icon)
- ❌ Route polyline
- ✅ Driver card
- ❌ Edit buttons (all)

**Booking Details Screen**:
- Title: "Parcel has been delivered"
- ETA Label: "Reached"
- Payment banner visible
- Driver card visible

**Bookings List Screen**:
- Status: "Reached drop"
- No ETA information
- Driver details shown

**Technical Notes**:
- Navigation stream still active
- Route polyline removed
- No edit operations allowed

---

### 9. COMPLETED
**Description**: Booking successfully completed

**UI Elements Shown**:
- ❌ Pickup marker (removed)
- ✅ Drop marker (red)
- ❌ Driver marker (removed)
- ❌ Route polyline
- ✅ Driver card
- ❌ Edit buttons (all)

**Booking Details Screen**:
- Title: "Booking completed"
- ETA Label: "Completed"
- Payment banner visible
- Driver card visible

**Bookings List Screen**:
- Status: "Booking completed"
- No ETA information
- Driver details shown

**Technical Notes**:
- Navigation stream inactive
- All markers and polylines removed
- No edit operations allowed
- Booking moves to history

---

### 10. CANCELLED
**Description**: Booking was cancelled

**UI Elements Shown**:
- ✅ Pickup marker (green)
- ✅ Drop marker (red)
- ❌ Driver marker
- ❌ Route polyline
- ❌ Driver card
- ❌ Edit buttons (all)

**Booking Details Screen**:
- Title: "Booking cancelled"
- ETA Label: "Cancelled"
- Payment banner visible
- Driver card hidden

**Bookings List Screen**:
- Status: "Booking cancelled"
- No ETA information
- No driver details

**Technical Notes**:
- Navigation stream inactive
- No edit operations allowed
- Booking moves to history

---

### 11. EXPIRED
**Description**: Booking expired (timeout)

**UI Elements Shown**:
- ✅ Pickup marker (green)
- ✅ Drop marker (red)
- ❌ Driver marker
- ❌ Route polyline
- ❌ Driver card
- ❌ Edit buttons (all)

**Booking Details Screen**:
- Title: "Booking cancelled"
- ETA Label: "Expired"
- Payment banner visible
- Driver card hidden

**Bookings List Screen**:
- Status: "Booking expired"
- No ETA information
- No driver details

**Technical Notes**:
- Navigation stream inactive
- No edit operations allowed
- Booking moves to history

---

## Technical Implementation Details

### Stale Update Handling

**Problem**: Old navigation updates from previous bookings can interfere with current booking display.

**Solution**:
```dart
// In DriverNavigationUpdate.fromJson()
isStale: bookingId != json['bookingId']
```

**How it works**:
1. Each navigation update includes a `bookingId`
2. If the update's `bookingId` doesn't match the current booking's ID, it's marked as stale
3. Stale updates are ignored in UI rendering
4. This prevents showing old driver locations or routes for completed bookings

**UI Impact**:
- Stale updates show "Getting your driver ready" instead of real ETA
- Driver marker doesn't update with stale location data
- Route polyline doesn't update with stale route data

### Driver Assignment States

**Two-Phase Driver Assignment**:

1. **DRIVER_ASSIGNED**: Driver assigned but not confirmed
   - Driver exists in backend
   - Driver NOT shown to user
   - No navigation stream active
   - All edit operations allowed

2. **CONFIRMED**: Driver confirmed and active
   - Driver shown to user
   - Navigation stream active
   - Real-time updates begin
   - Edit operations still allowed

**Implementation**:
```dart
// In Booking.fromJson()
final shouldShowDriver = bookingStatus != BookingStatus.driverAssigned && json['assignedDriver'] != null;
final assignedDriver = shouldShowDriver ? Driver.fromJson(json['assignedDriver']) : null;
```

### Navigation Stream Management

**Active Bookings**:
- Navigation stream is active
- Real-time driver location updates
- ETA calculations based on live data

**Inactive Bookings**:
- Navigation stream returns `AsyncValue.data(null)`
- No real-time updates
- Static display based on booking status

**Implementation**:
```dart
final navStream = isActive(_booking.status)
    ? ref.watch(driverNavigationStreamProvider(_booking.id))
    : const AsyncValue.data(null);
```

### Map Marker Logic

**Pickup Marker**:
- Shown when: `!isActive(booking.status) || isBeforePickupVerified(booking.status)`
- Hidden when: Pickup is verified and booking is active
- Always shown for completed/cancelled bookings

**Drop Marker**:
- Always shown regardless of status
- Never hidden

**Driver Marker**:
- Shown when: Driver assigned and confirmed
- Hidden when: No driver or booking inactive

**Route Polyline**:
- Shown when: `status == BookingStatus.confirmed || status == BookingStatus.inTransit`
- Hidden otherwise

### Edit Button Logic

**Pickup Address**:
- Editable when: `isBeforePickupArrived(status)`
- Not editable after driver arrives at pickup

**Drop Address**:
- Editable when: `isBeforeDropArrived(status)`
- Not editable after driver arrives at drop

**Package Details**:
- Editable when: `isBeforePickupArrived(status)`
- Not editable after driver arrives at pickup

### ETA Display Logic

**Time Formatting**:
- `>= 3600 seconds`: "X hours Y mins"
- `< 120 seconds`: "1 min"
- `>= 60 seconds`: "X mins"

**Distance Formatting**:
- `>= 1000 meters`: "X.X km"
- `< 1000 meters`: "X m"

**Status-Based ETA**:
- Before pickup verified: Shows time to pickup
- After pickup verified: Shows time to drop
- At arrival points: Shows "Reached"
- Inactive bookings: Shows "Getting your driver ready"

## Edge Cases and Error Handling

### Network Issues
- Stale updates handled gracefully
- Fallback to "Getting your driver ready" when no valid data
- Retry mechanisms for failed API calls

### Booking State Transitions
- Smooth transitions between statuses
- UI updates immediately on status change
- Proper cleanup of old markers and polylines

### Driver Assignment Failures
- Graceful handling when driver assignment fails
- Fallback to "Looking for a driver" state
- Retry mechanisms for driver assignment

### Navigation Data Issues
- Handling of missing or invalid location data
- Fallback to static map view when navigation data unavailable
- Proper error states in UI

This documentation provides a complete reference for understanding the booking flow, UI states, and technical implementation details of the Hello Truck application.