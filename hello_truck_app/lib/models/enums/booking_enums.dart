enum VehicleType {
  twoWheeler('TWO_WHEELER'),
  threeWheeler('THREE_WHEELER'),
  fourWheeler('FOUR_WHEELER');

  const VehicleType(this.value);
  final String value;

  static VehicleType fromString(String value) {
    return VehicleType.values.firstWhere(
      (type) => type.value == value,
    );
  }
}

enum BookingStatus {
  pending('PENDING'),
  driverAssigned('DRIVER_ASSIGNED'),
  confirmed('CONFIRMED'),
  pickupArrived('PICKUP_ARRIVED'),
  pickupVerified('PICKUP_VERIFIED'),
  inTransit('IN_TRANSIT'),
  dropArrived('DROP_ARRIVED'),
  dropVerified('DROP_VERIFIED'),
  completed('COMPLETED'),
  cancelled('CANCELLED'),
  expired('EXPIRED');

  const BookingStatus(this.value);
  final String value;

  static BookingStatus fromString(String value) {
    return BookingStatus.values.firstWhere(
      (status) => status.value == value,
    );
  }
}

enum AssignmentStatus {
  offered('OFFERED'),
  accepted('ACCEPTED'),
  rejected('REJECTED'),
  autoRejected('AUTO_REJECTED');

  const AssignmentStatus(this.value);
  final String value;

  static AssignmentStatus fromString(String value) {
    return AssignmentStatus.values.firstWhere(
      (status) => status.value == value,
    );
  }
}
