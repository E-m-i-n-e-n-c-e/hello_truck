import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hello_truck_app/auth/api.dart';
import 'package:hello_truck_app/auth/auth_socket.dart';
import 'package:hello_truck_app/models/auth_state.dart';

final authSocketProvider = Provider<AuthSocket>((ref) {
  final socket = AuthSocket();
  socket.connect(); // auto-connect
  ref.onDispose(() => socket.disconnect());
  return socket;
});

final authStateProvider = StreamProvider<AuthState>((ref) {
  final socket = ref.watch(authSocketProvider);
  return socket.authStateStream.distinct();
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
