class Customer {
  final String firstName;
  final String phoneNumber;
  final String lastName;
  final String email;
  final String referralCode;
  final bool isBusiness;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Customer({
    required this.firstName,
    required this.lastName,
    required this.email,
    required this.phoneNumber,
    required this.referralCode,
    required this.isBusiness,
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
      createdAt: json['createdAt'] != null ? DateTime.parse(json['createdAt']) : DateTime.now(),
      updatedAt: json['updatedAt'] != null ? DateTime.parse(json['updatedAt']) : DateTime.now(),
    );
  }
}
