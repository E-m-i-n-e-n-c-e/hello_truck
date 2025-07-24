import 'package:hello_truck_app/auth/api.dart';
import 'package:hello_truck_app/models/address.dart';

/// Get all addresses for the current user
Future<List<Address>> getAddresses(API api) async {
  final response = await api.get('/customer/addresses');
  return (response.data as List).map((json) => Address.fromJson(json)).toList();
}

/// Get a specific address by ID
Future<Address> getAddressById(API api, String id) async {
  final response = await api.get('/customer/addresses/$id');
  return Address.fromJson(response.data);
}

/// Create a new address
Future<Address> createAddress(
  API api, {
  required String addressLine1,
  String? landmark,
  required String pincode,
  required String city,
  required String district,
  required String state,
  required double latitude,
  required double longitude,
  String? phoneNumber,
  String? label,
  bool? isDefault,
}) async {
  final response = await api.post('/customer/addresses', data: {
    'addressLine1': addressLine1,
    if (landmark?.isNotEmpty ?? false) 'landmark': landmark,
    'pincode': pincode,
    'city': city,
    'district': district,
    'state': state,
    'latitude': latitude,
    'longitude': longitude,
    if (phoneNumber?.isNotEmpty ?? false) 'phoneNumber': phoneNumber,
    if (label?.isNotEmpty ?? false) 'label': label,
    if (isDefault != null) 'isDefault': isDefault,
  });
  return Address.fromJson(response.data);
}

/// Update an existing address
Future<Address> updateAddress(
  API api,
  String id, {
  String? addressLine1,
  String? landmark,
  String? pincode,
  String? city,
  String? district,
  String? state,
  double? latitude,
  double? longitude,
  String? phoneNumber,
  String? label,
  bool? isDefault,
}) async {
  final response = await api.put('/customer/addresses/$id', data: {
    if (addressLine1?.isNotEmpty ?? false) 'addressLine1': addressLine1,
    if (landmark?.isNotEmpty ?? false) 'landmark': landmark,
    if (pincode?.isNotEmpty ?? false) 'pincode': pincode,
    if (city?.isNotEmpty ?? false) 'city': city,
    if (district?.isNotEmpty ?? false) 'district': district,
    if (state?.isNotEmpty ?? false) 'state': state,
    if (latitude != null) 'latitude': latitude,
    if (longitude != null) 'longitude': longitude,
    if (phoneNumber?.isNotEmpty ?? false) 'phoneNumber': phoneNumber,
    if (label?.isNotEmpty ?? false) 'label': label,
    if (isDefault != null) 'isDefault': isDefault,
  });
  return Address.fromJson(response.data);
}

/// Delete an address
Future<void> deleteAddress(API api, String id) async {
  await api.delete('/customer/addresses/$id');
}

/// Set an address as default
Future<Address> setDefaultAddress(API api, String id) async {
  final response = await api.post('/customer/addresses/$id/default');
  return Address.fromJson(response.data);
}