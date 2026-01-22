import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hello_truck_app/api/customer_api.dart' as customer_api;
import 'package:hello_truck_app/models/referral_stats.dart';
import 'package:hello_truck_app/providers/auth_providers.dart';

/// Provider for referral stats
final referralStatsProvider = FutureProvider<ReferralStats>((ref) async {
  final api = await ref.watch(apiProvider.future);
  final data = await customer_api.getReferralStats(api);
  return ReferralStats.fromJson(data);
});

/// Provider for applying a referral code
final applyReferralCodeProvider = FutureProvider.family<void, String>((ref, code) async {
  final api = await ref.watch(apiProvider.future);
  await customer_api.applyReferralCode(api, code);
});

/// Provider for validating a referral code
final validateReferralCodeProvider = FutureProvider.family<Map<String, dynamic>, String>((ref, code) async {
  final api = await ref.watch(apiProvider.future);
  return await customer_api.validateReferralCode(api, code);
});
