import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hello_truck_app/models/customer.dart';
import 'package:hello_truck_app/models/gst_details.dart';
import 'package:hello_truck_app/providers/auth_providers.dart';
import 'package:hello_truck_app/api/customer_api.dart' as customer_api;
import 'package:hello_truck_app/api/gst_details_api.dart' as gst_api;

final customerProvider = FutureProvider<Customer>((ref) async {
  final api = await ref.watch(apiProvider.future);
  return customer_api.getCustomerProfile(api);
});

final gstDetailsProvider = FutureProvider<List<GstDetails>>((ref) async {
  final api = await ref.watch(apiProvider.future);
  return gst_api.getGstDetails(api);
});
