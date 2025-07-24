import 'package:hello_truck_app/auth/api.dart';
import 'package:hello_truck_app/models/gst_details.dart';

/// Get all GST details for the current user
Future<List<GstDetails>> getGstDetails(API api) async {
  final response = await api.get('/customer/gst');
  return (response.data as List).map((json) => GstDetails.fromJson(json)).toList();
}

/// Add new GST details
Future<void> addGstDetails(
  API api, {
  required String gstNumber,
  required String businessName,
  required String businessAddress,
}) async {
  await api.post('/customer/gst', data: {
    'gstNumber': gstNumber,
    'businessName': businessName,
    'businessAddress': businessAddress,
  });
}

/// Update existing GST details
Future<void> updateGstDetails(
  API api, {
  required String id,
  String? gstNumber,
  String? businessName,
  String? businessAddress,
}) async {
  await api.put('/customer/gst/$id', data: {
    if (gstNumber?.isNotEmpty ?? false) 'gstNumber': gstNumber,
    if (businessName?.isNotEmpty ?? false) 'businessName': businessName,
    if (businessAddress?.isNotEmpty ?? false) 'businessAddress': businessAddress,
  });
}

/// Deactivate GST details
Future<void> deactivateGstDetails(API api, String id) async {
  await api.post('/customer/gst/deactivate', data: {'id': id});
}