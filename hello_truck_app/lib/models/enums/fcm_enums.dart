enum FcmEventType {
  bookingStatusChange('BOOKING_STATUS_CHANGE'),
  // driverAssignmentOffered('DRIVER_ASSIGNMENT_OFFERED'),
  // driverAssignmentTimeout('DRIVER_ASSIGNMENT_TIMEOUT'), // Data only
  // driverVerificationUpdate('DRIVER_VERIFICATION_UPDATE'), // Data only
  paymentSuccess('PAYMENT_SUCCESS'),
  // payoutProcessed('PAYOUT_PROCESSED'),
  refundProcessed('REFUND_PROCESSED'),
  // rideCancelled('RIDE_CANCELLED'),
  walletChange('WALLET_CHANGE');

  const FcmEventType(this.value);
  final String value;

  static FcmEventType fromString(String value) {
    return FcmEventType.values.firstWhere(
      (type) => type.value == value,
    );
  }

  static const localNotificationEnabledEvents = [
    bookingStatusChange,
    paymentSuccess,
    refundProcessed,
    walletChange,
  ];

  static bool isLocalNotificationEnabled(FcmEventType eventType) {
    return localNotificationEnabledEvents.contains(eventType);
  }
}
