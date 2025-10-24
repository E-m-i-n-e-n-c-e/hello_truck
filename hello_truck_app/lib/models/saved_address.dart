class SavedAddress {
  final String id;
  final String name;
  final Address address;
  final String contactName;
  final String contactPhone;
  final String? noteToDriver;
  final bool isDefault;
  final bool isLocalRecent;
  final DateTime createdAt;
  final DateTime updatedAt;

  SavedAddress({
    required this.id,
    required this.name,
    required this.address,
    required this.contactName,
    required this.contactPhone,
    this.noteToDriver,
    required this.isDefault,
    this.isLocalRecent = true,
    required this.createdAt,
    required this.updatedAt,
  });

  factory SavedAddress.fromJson(Map<String, dynamic> json, {bool isLocalRecent = false}) {
    return SavedAddress(
      id: json['id'] ,
      name: json['name'],
      address: Address.fromJson(json['address']),
      contactName: json['contactName'],
      contactPhone: json['contactPhone'],
      noteToDriver: json['noteToDriver'],
      isDefault: json['isDefault'],
      isLocalRecent: isLocalRecent,  // When fetching from server set to false, if from local cache set to true
      createdAt: json['createdAt'] != null ? DateTime.parse(json['createdAt']) : DateTime.now(),
      updatedAt: json['updatedAt'] != null ? DateTime.parse(json['updatedAt']) : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'address': address.toJson(),
      'contactName': contactName,
      'contactPhone': contactPhone,
      'noteToDriver': noteToDriver,
      'isDefault': isDefault,
    };
  }
}

class Address {
  final String formattedAddress;
  final String? addressDetails;
  final double latitude;
  final double longitude;

  Address({
    required this.formattedAddress,
    this.addressDetails,
    required this.latitude,
    required this.longitude,
  });

  // Get full address details along with metadata
  factory Address.fromJson(Map<String, dynamic> json) {
    return Address(
      formattedAddress: json['formattedAddress'],
      addressDetails: json['addressDetails'],
      latitude: json['latitude'].toDouble(),
      longitude: json['longitude'].toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'formattedAddress': formattedAddress,
      'addressDetails': addressDetails,
      'latitude': latitude,
      'longitude': longitude,
    };
  }
}