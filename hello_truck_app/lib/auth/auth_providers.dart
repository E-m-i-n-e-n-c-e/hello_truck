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
  return socket.authStateStream;
});

final apiProvider = FutureProvider<API>((ref) async {
  final authState = ref.watch(authStateProvider);
  final api = API(accessToken: authState.value?.token);
  await api.init();
  return api;
});
