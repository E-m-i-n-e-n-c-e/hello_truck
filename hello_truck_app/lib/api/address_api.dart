import 'package:hello_truck_app/auth/api.dart';
import 'package:hello_truck_app/models/saved_address.dart';

/// Get all addresses for the current user
Future<List<SavedAddress>> getSavedAddresses(API api) async {
  final response = await api.get('/customer/addresses');
  return (response.data as List).map((json) => SavedAddress.fromJson(json)).toList();
}

/// Get a specific address by ID
Future<SavedAddress> getSavedAddressById(API api, String id) async {
  final response = await api.get('/customer/addresses/$id');
  return SavedAddress.fromJson(response.data);
}

/// Create a new address
Future<SavedAddress> createSavedAddress(
  API api, {
  required String name,
  required Address address,
  String? contactName,
  String? contactPhone,
  String? noteToDriver,
  bool? isDefault,
}) async {
  final response = await api.post('/customer/addresses', data: {
    'name': name,
    'address': address.toJson(),
    if (contactName?.isNotEmpty ?? false) 'contactName': contactName,
    if (contactPhone?.isNotEmpty ?? false) 'contactPhone': contactPhone,
    if (noteToDriver?.isNotEmpty ?? false) 'noteToDriver': noteToDriver,
    if (isDefault != null) 'isDefault': isDefault,
  });
  return SavedAddress.fromJson(response.data);
}

/// Update an existing address
  Future<SavedAddress> updateSavedAddress(
  API api,
  String id, {
  String? name,
  Address? address,
  String? contactName,
  String? contactPhone,
  String? noteToDriver,
  bool? isDefault,
}) async {
  final response = await api.put('/customer/addresses/$id', data: {
    if (name?.isNotEmpty ?? false) 'name': name,
    if (address != null) 'address': address.toJson(),
    if (contactName?.isNotEmpty ?? false) 'contactName': contactName,
    if (contactPhone?.isNotEmpty ?? false) 'contactPhone': contactPhone,
    if (noteToDriver?.isNotEmpty ?? false) 'noteToDriver': noteToDriver,
    if (isDefault != null) 'isDefault': isDefault,
  });
  return SavedAddress.fromJson(response.data);
}

/// Delete an address
Future<void> deleteSavedAddress(API api, String id) async {
  await api.delete('/customer/addresses/$id');
}

/// Set an address as default
Future<SavedAddress> setDefaultSavedAddress(API api, String id) async {
  final response = await api.post('/customer/addresses/$id/default');
  return SavedAddress.fromJson(response.data);
}