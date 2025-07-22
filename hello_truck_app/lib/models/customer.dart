class Customer {
  final String id;
  final String firstName;
  final String phoneNumber;
  final String lastName;
  final String email;
  final String referralCode;
  final bool isBusiness;

  const Customer({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.email,
    required this.phoneNumber,
    required this.referralCode,
    required this.isBusiness,
  });

  factory Customer.fromJson(Map<String, dynamic> json) {
    return Customer(
      id: json['id'] ?? '',
      firstName: json['firstName'] ?? '',
      lastName: json['lastName'] ?? '',
      email: json['email'] ?? '',
      phoneNumber: json['phoneNumber'] ?? '',
      referralCode: json['referralCode'] ?? '',
      isBusiness: json['isBusiness'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'firstName': firstName,
      'lastName': lastName,
      'email': email,
      'phoneNumber': phoneNumber,
      'referralCode': referralCode,
      'isBusiness': isBusiness,
    };
  }
}
