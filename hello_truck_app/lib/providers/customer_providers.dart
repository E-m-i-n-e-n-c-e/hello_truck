import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hello_truck_app/models/customer.dart';
import 'package:hello_truck_app/models/gst_details.dart';
import 'package:hello_truck_app/models/pending_refund.dart';
import 'package:hello_truck_app/models/transaction_log.dart';
import 'package:hello_truck_app/models/wallet_log.dart';
import 'package:hello_truck_app/providers/auth_providers.dart';
import 'package:hello_truck_app/api/customer_api.dart' as customer_api;
import 'package:hello_truck_app/api/gst_details_api.dart' as gst_api;

final customerProvider = FutureProvider.autoDispose<Customer>((ref) async {
  final api = await ref.watch(apiProvider.future);
  return customer_api.getCustomerProfile(api);
});

final gstDetailsProvider = FutureProvider<List<GstDetails>>((ref) async {
  final api = await ref.watch(apiProvider.future);
  return gst_api.getGstDetails(api);
});

final walletLogsProvider = FutureProvider<List<WalletLog>>((ref) async {
  final api = await ref.watch(apiProvider.future);
  return customer_api.getWalletLogs(api);
});

final transactionLogsProvider = FutureProvider<List<TransactionLog>>((ref) async {
  final api = await ref.watch(apiProvider.future);
  return customer_api.getTransactionLogs(api);
});

final pendingRefundsProvider = FutureProvider<List<PendingRefund>>((ref) async {
  final api = await ref.watch(apiProvider.future);
  return customer_api.getPendingRefunds(api);
});
