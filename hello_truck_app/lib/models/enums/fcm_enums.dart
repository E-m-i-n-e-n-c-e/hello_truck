enum FcmEventType {
  driverAssignmentOffered('DRIVER_ASSIGNMENT_OFFERED'),
  driverAssignmentTimeout('DRIVER_ASSIGNMENT_TIMEOUT'),
  assignmentEscalated('ASSIGNMENT_ESCALATED'),
  noDriverAvailable('NO_DRIVER_AVAILABLE'),
  bookingStatusChange('BOOKING_STATUS_CHANGE');

  const FcmEventType(this.value);
  final String value;

  static FcmEventType fromString(String value) {
    return FcmEventType.values.firstWhere(
      (type) => type.value == value,
    );
  }

  static const localNotificationEnabledEvents = [bookingStatusChange];

  static bool isLocalNotificationEnabled(FcmEventType eventType) {
    return localNotificationEnabledEvents.contains(eventType) || eventType == bookingStatusChange;
  }
}

