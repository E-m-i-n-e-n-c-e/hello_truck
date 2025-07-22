import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hello_truck_app/auth/api.dart';
import 'package:hello_truck_app/auth/auth_client.dart';
import 'package:hello_truck_app/models/auth_state.dart';
import 'package:hello_truck_app/providers/connectivity_providers.dart';

final authClientProvider = Provider<AuthClient>((ref) {
  final client = AuthClient();

  // Listen to connectivity changes
  ref.listen<AsyncValue<bool>>(connectivityProvider, (_, next) {
    next.whenData((isOnline) {
        client.refreshTokens();
    });
  });

  client.initialize(); // auto-initialize
  ref.onDispose(() => client.dispose());
  return client;
});

final authStateProvider = StreamProvider<AuthState>((ref) {
  final client = ref.watch(authClientProvider);
  return client.authStateStream.distinct();
});

// Single API instance that updates its token
final apiProvider = FutureProvider<API>((ref) async {
  final api = API(
    accessToken: ref.read(authStateProvider).value?.token,
    ref: ref,
  );
  print("API initialized with token: ${api.accessToken}");

  // Listen to auth state changes and update token
  ref.listen(authStateProvider, (_, next) {
    api.updateToken(next.value?.token);
    print("Token updated: ${next.value?.token}");
  });

  // Initialize the API
  await api.init();

  ref.onDispose(() async {
    await api.dispose();
  });

  return api;
});
