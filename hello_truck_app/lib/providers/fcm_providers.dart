import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/auth_providers.dart';
import '../services/fcm_service.dart';

final fcmServiceProvider = FutureProvider<FCMService>((ref) async {
  final api = await ref.watch(apiProvider.future);
  final service = FCMService(api);
  service.initialize();
  print('FCM service provider initialized');

  // Initialize FCM when auth state changes
  ref.listen(authStateProvider, (prev, next) {
    if (next.value?.isAuthenticated == true) {
      service.initialize();
    } else if (next.value?.isAuthenticated != true) {
      service.stop();
    }
  });

  return service;
});
