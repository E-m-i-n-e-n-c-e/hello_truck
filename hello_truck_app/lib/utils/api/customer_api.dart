import 'package:hello_truck_app/auth/api.dart';
import 'package:hello_truck_app/models/customer.dart';
import 'package:hello_truck_app/models/gst_details.dart';

/// Get customer profile
Future<Customer> getCustomerProfile(API api) async {
  final response = await api.get('/customer/profile');
  return Customer.fromJson(response.data);
}

Future<void> createCustomerProfile(API api, {
  required String firstName,
  String? lastName,
  String? googleIdToken,
  String? referralCode,
  GstDetails? gstDetails,
}) async {
  await api.post('/customer/profile', data: {
    'firstName': firstName,
    if (lastName?.isNotEmpty ?? false) 'lastName': lastName,
    if (googleIdToken?.isNotEmpty ?? false) 'googleIdToken': googleIdToken,
    if (referralCode?.isNotEmpty ?? false) 'referralCode': referralCode,
    if (gstDetails != null) 'gstDetails': {
      'gstNumber': gstDetails.gstNumber,
      'businessName': gstDetails.businessName,
      'businessAddress': gstDetails.businessAddress,
    },
  });
}

/// Update customer profile
Future<void> updateCustomerProfile(
  API api, {
  String? firstName,
  String? lastName,
  String? googleIdToken,
}) async {
  await api.put('/customer/profile', data: {
    if (firstName?.isNotEmpty ?? false) 'firstName': firstName,
    if (lastName != null) 'lastName': lastName,
    if (googleIdToken?.isNotEmpty ?? false) 'googleIdToken': googleIdToken,
  });
}