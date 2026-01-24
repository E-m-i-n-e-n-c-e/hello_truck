class Customer {
  final String firstName;
  final String phoneNumber;
  final String lastName;
  final String email;
  final String referralCode;
  final bool isBusiness;
  final double walletBalance;
  final bool hasAppliedReferral;
  final DateTime? profileCreatedAt;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Customer({
    required this.firstName,
    required this.lastName,
    required this.email,
    required this.phoneNumber,
    required this.referralCode,
    required this.isBusiness,
    required this.walletBalance,
    required this.hasAppliedReferral,
    this.profileCreatedAt,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Customer.fromJson(Map<String, dynamic> json) {
    return Customer(
      firstName: json['firstName'] ?? '',
      lastName: json['lastName'] ?? '',
      email: json['email'] ?? '',
      phoneNumber: json['phoneNumber'] ?? '',
      referralCode: json['referralCode'] ?? '',
      isBusiness: json['isBusiness'] ?? false,
      walletBalance: json['walletBalance'] != null
          ? double.parse(json['walletBalance'].toString())
          : 0.0,
      hasAppliedReferral: json['hasAppliedReferral'] ?? false,
      profileCreatedAt: json['profileCreatedAt'] != null ? DateTime.parse(json['profileCreatedAt']) : null,
      createdAt: json['createdAt'] != null ? DateTime.parse(json['createdAt']) : DateTime.now(),
      updatedAt: json['updatedAt'] != null ? DateTime.parse(json['updatedAt']) : DateTime.now(),
    );
  }

  String get fullName => '$firstName $lastName'.trim();
  String get initials => '${firstName.isNotEmpty ? firstName[0] : ''}${lastName.isNotEmpty ? lastName[0] : ''}'.toUpperCase();
  DateTime get memberSince => profileCreatedAt ?? createdAt;
}
