enum FcmEventType {
  driverAssignmentOffered('DRIVER_ASSIGNMENT_OFFERED'),
  driverAssignmentTimeout('DRIVER_ASSIGNMENT_TIMEOUT'),
  assignmentEscalated('ASSIGNMENT_ESCALATED'),
  noDriverAvailable('NO_DRIVER_AVAILABLE');

  const FcmEventType(this.value);
  final String value;

  static FcmEventType fromString(String value) {
    return FcmEventType.values.firstWhere(
      (type) => type.value == value,
    );
  }
}

