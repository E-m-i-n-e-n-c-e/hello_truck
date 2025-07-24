class Address {
  final String id;
  final String addressLine1;
  final String? landmark;
  final String pincode;
  final String city;
  final String district;
  final String state;
  final double latitude;
  final double longitude;
  final String? phoneNumber;
  final String? label;
  final bool isDefault;
  final DateTime createdAt;
  final DateTime updatedAt;

  Address({
    required this.id,
    required this.addressLine1,
    this.landmark,
    required this.pincode,
    required this.city,
    required this.district,
    required this.state,
    required this.latitude,
    required this.longitude,
    this.phoneNumber,
    this.label,
    required this.isDefault,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Address.fromJson(Map<String, dynamic> json) {
    return Address(
      id: json['id'] ,
      addressLine1: json['addressLine1'],
      landmark: json['landmark'],
      pincode: json['pincode'],
      city: json['city'],
      district: json['district'],
      state: json['state'],
      latitude: double.parse(json['latitude'].toString()),
      longitude: double.parse(json['longitude'].toString()),
      phoneNumber: json['phoneNumber'],
      label: json['label'],
      isDefault: json['isDefault'],
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: DateTime.parse(json['updatedAt']),
    );
  }
}