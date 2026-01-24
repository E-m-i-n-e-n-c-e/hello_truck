class ReferralStats {
  final String? referralCode;
  final int totalReferrals;
  final List<ReferralRecord> referrals;

  ReferralStats({
    required this.referralCode,
    required this.totalReferrals,
    required this.referrals,
  });

  factory ReferralStats.fromJson(Map<String, dynamic> json) {
    return ReferralStats(
      referralCode: json['referralCode'],
      totalReferrals: json['totalReferrals'] ?? 0,
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
  final bool referrerRewardApplied;
  final DateTime createdAt;

  ReferralRecord({
    required this.id,
    required this.referredCustomer,
    required this.referrerRewardApplied,
    required this.createdAt,
  });

  factory ReferralRecord.fromJson(Map<String, dynamic> json) {
    return ReferralRecord(
      id: json['id'],
      referredCustomer: ReferredCustomer.fromJson(json['referredCustomer']),
      referrerRewardApplied: json['referrerRewardApplied'] ?? false,
      createdAt: DateTime.parse(json['createdAt']),
    );
  }
}

class ReferredCustomer {
  final String id;
  final String? firstName;
  final String? lastName;
  final String phoneNumber;
  final int bookingCount;
  final DateTime? profileCreatedAt;
  final DateTime createdAt;

  ReferredCustomer({
    required this.id,
    this.firstName,
    this.lastName,
    required this.phoneNumber,
    required this.bookingCount,
    this.profileCreatedAt,
    required this.createdAt,
  });

  String get fullName {
    if (firstName == null && lastName == null) return 'Customer';
    return '${firstName ?? ''} ${lastName ?? ''}'.trim();
  }

  String get maskedPhone {
    if (phoneNumber.length < 4) return phoneNumber;
    return 'XXXXXX${phoneNumber.substring(phoneNumber.length - 4)}';
  }

  DateTime get joinedDate => profileCreatedAt ?? createdAt;

  factory ReferredCustomer.fromJson(Map<String, dynamic> json) {
    return ReferredCustomer(
      id: json['id'],
      firstName: json['firstName'],
      lastName: json['lastName'],
      phoneNumber: json['phoneNumber'],
      bookingCount: json['bookingCount'] ?? 0,
      profileCreatedAt: json['profileCreatedAt'] != null ? DateTime.parse(json['profileCreatedAt']) : null,
      createdAt: DateTime.parse(json['createdAt']),
    );
  }
}
