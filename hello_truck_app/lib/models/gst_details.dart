class GstDetails {
  final String? id;
  final String gstNumber;
  final String businessName;
  final String businessAddress;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const GstDetails({
    this.id,
    required this.gstNumber,
    required this.businessName,
    required this.businessAddress,
    this.createdAt,
    this.updatedAt,
  });

  factory GstDetails.fromJson(Map<String, dynamic> json) {
    return GstDetails(
      id: json['id'] ?? '',
      gstNumber: json['gstNumber'] ?? '',
      businessName: json['businessName'] ?? '',
      businessAddress: json['businessAddress'] ?? '',
      createdAt: json['createdAt'] != null ? DateTime.parse(json['createdAt']) : DateTime.now(),
      updatedAt: json['updatedAt'] != null ? DateTime.parse(json['updatedAt']) : DateTime.now(),
    );
  }
}