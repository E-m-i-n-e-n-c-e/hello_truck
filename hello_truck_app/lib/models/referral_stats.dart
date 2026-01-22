class ReferralStats {
  final String? referralCode;
  final int totalReferrals;
  final int remainingReferrals;
  final int maxReferrals;
  final List<ReferralRecord> referrals;

  ReferralStats({
    required this.referralCode,
    required this.totalReferrals,
    required this.remainingReferrals,
    required this.maxReferrals,
    required this.referrals,
  });

  factory ReferralStats.fromJson(Map<String, dynamic> json) {
    return ReferralStats(
      referralCode: json['referralCode'],
      totalReferrals: json['totalReferrals'] ?? 0,
      remainingReferrals: json['remainingReferrals'] ?? 0,
      maxReferrals: json['maxReferrals'] ?? 5,
      referrals: (json['referrals'] as List<dynamic>?)
              ?.map((r) => ReferralRecord.fromJson(r))
              .toList() ??
          [],
    );
  }
}

class ReferralRecord {
  final String id;
  final ReferredCustomer referredCustomer;
  final DateTime createdAt;

  ReferralRecord({
    required this.id,
    required this.referredCustomer,
    required this.createdAt,
  });

  factory ReferralRecord.fromJson(Map<String, dynamic> json) {
    return ReferralRecord(
      id: json['id'],
      referredCustomer: ReferredCustomer.fromJson(json['referredCustomer']),
      createdAt: DateTime.parse(json['createdAt']),
    );
  }
}

class ReferredCustomer {
  final String id;
  final String? firstName;
  final String? lastName;
  final String phoneNumber;
  final DateTime createdAt;

  ReferredCustomer({
    required this.id,
    this.firstName,
    this.lastName,
    required this.phoneNumber,
    required this.createdAt,
  });

  String get fullName {
    if (firstName == null && lastName == null) return 'Customer';
    return '${firstName ?? ''} ${lastName ?? ''}'.trim();
  }

  factory ReferredCustomer.fromJson(Map<String, dynamic> json) {
    return ReferredCustomer(
      id: json['id'],
      firstName: json['firstName'],
      lastName: json['lastName'],
      phoneNumber: json['phoneNumber'],
      createdAt: DateTime.parse(json['createdAt']),
    );
  }
}
