import 'package:hello_truck_app/auth/api.dart';
import 'package:hello_truck_app/models/customer.dart';
import 'package:hello_truck_app/models/gst_details.dart';
import 'package:hello_truck_app/models/pending_refund.dart';
import 'package:hello_truck_app/models/saved_address.dart';
import 'package:hello_truck_app/models/transaction_log.dart';
import 'package:hello_truck_app/models/wallet_log.dart';

/// Get customer profile
Future<Customer> getCustomerProfile(API api) async {
  final response = await api.get('/customer/profile');
  return Customer.fromJson(response.data);
}

/// Get customer wallet logs
Future<List<WalletLog>> getWalletLogs(API api) async {
  final response = await api.get('/customer/profile/wallet-logs');
  final List<dynamic> data = response.data;
  return data.map((json) => WalletLog.fromJson(json)).toList();
}

/// Get customer transaction logs
Future<List<TransactionLog>> getTransactionLogs(API api) async {
  final response = await api.get('/customer/profile/transaction-logs');
  final List<dynamic> data = response.data;
  return data.map((json) => TransactionLog.fromJson(json)).toList();
}

/// Get customer pending refunds
Future<List<PendingRefund>> getPendingRefunds(API api) async {
  final response = await api.get('/customer/profile/pending-refunds');
  final List<dynamic> data = response.data;
  return data.map((json) => PendingRefund.fromJson(json)).toList();
}

Future<void> createCustomerProfile(API api, {
  required String firstName,
  String? lastName,
  String? googleIdToken,
  String? appliedReferralCode,
  GstDetails? gstDetails,
  SavedAddress? savedAddress,
}) async {
  await api.post('/customer/profile', data: {
    'firstName': firstName,
    if (lastName?.isNotEmpty ?? false) 'lastName': lastName,
    if (googleIdToken?.isNotEmpty ?? false) 'googleIdToken': googleIdToken,
    if (appliedReferralCode?.isNotEmpty ?? false) 'appliedReferralCode': appliedReferralCode,
    if (gstDetails != null) 'gstDetails': {
      'gstNumber': gstDetails.gstNumber,
      'businessName': gstDetails.businessName,
      'businessAddress': gstDetails.businessAddress,
    },
    if (savedAddress != null) 'savedAddress':  savedAddress.toJson(),
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

/// Apply a referral code
Future<void> applyReferralCode(API api, String referralCode) async {
  await api.post('/customer/referral/apply', data: {
    'referralCode': referralCode,
  });
}

/// Get referral stats
Future<Map<String, dynamic>> getReferralStats(API api) async {
  final response = await api.get('/customer/referral/stats');
  return response.data;
}

/// Validate a referral code
Future<bool> validateReferralCode(API api, String code) async {
  try {
    final response = await api.get('/customer/referral/validate', queryParameters: {
      'code': code,
    });
    return response.data['isValid'] == true;
  } catch (e) {
    return false;
  }
}
