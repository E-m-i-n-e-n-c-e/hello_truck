import 'dart:async';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:socket_io_client/socket_io_client.dart' as io;
import '../models/auth_state.dart';

class AuthSocket {
  static final AuthSocket _instance = AuthSocket._();
  factory AuthSocket() => _instance;
  AuthSocket._();

  final _controller = StreamController<AuthState>.broadcast();
  Stream<AuthState> get authStateStream => _controller.stream;

  final _storage = const FlutterSecureStorage();
  late io.Socket _socket;
  Timer? _refreshTimer;
  bool _hasEmittedOfflineState = false;

  Future<void> connect() async {
    _socket = io.io('http://10.0.2.2:3000', {
      'transports': ['websocket'],
      'autoConnect': true,
    });

    _socket.onConnect((_) {
      print('🔌 Socket connected');
      _hasEmittedOfflineState = false;
      _startRefreshLoop(); // no need to pass refresh token anymore
    });

    _socket.onReconnect((_) {
      print('🔌 Socket reconnected');
      _hasEmittedOfflineState = false;
    });

    _socket.onReconnectAttempt((_) async {
      print('🔌 Socket reconnecting');
      if (!_hasEmittedOfflineState) {
        _hasEmittedOfflineState = true;
        // We are offline, so we read from storage and emit the auth state
        final accessToken = await _storage.read(key: 'accessToken');
        _controller.add(AuthState.fromToken(accessToken));
      }
    });

    _socket.on('access-token', (data) async {
      final newAccessToken = data['accessToken'];
      final newRefreshToken = data['refreshToken'];

      await _storage.write(key: 'accessToken', value: newAccessToken);
      if (newRefreshToken != null) {
        await _storage.write(key: 'refreshToken', value: newRefreshToken);
      }
      _controller.add(AuthState.fromToken(newAccessToken));
    });

    _socket.on('force-logout', (_) async {
      await _storage.deleteAll();
      _controller.add(AuthState.unauthenticated());
    });
  }

  void _startRefreshLoop() async {
    _refreshTimer?.cancel(); // cancel existing timer if reconnecting

    // 🔁 Immediate first refresh
    final token = await _storage.read(key: 'refreshToken');
    if (token != null) {
      _socket.emit('refresh-token', {'refreshToken': token});
    } else {
      // No token available — user is unauthenticated
      _controller.add(AuthState.unauthenticated());
    }

    // 🕒 Periodic refresh every 1 minute
    _refreshTimer = Timer.periodic(const Duration(minutes: 1), (_) async {
      final refreshToken = await _storage.read(key: 'refreshToken');
      if (refreshToken != null) {
        _socket.emit('refresh-token', {'refreshToken': refreshToken});
      } else {
        // No token available — user is unauthenticated
        _controller.add(AuthState.unauthenticated());
      }
    });
  }

  void emitUnauthenticated() {
    _refreshTimer?.cancel();
    _controller.add(AuthState.unauthenticated());
  }

  void emitAuthState(String token) {
    _controller.add(AuthState.fromToken(token));
  }

  void disconnect() {
    _refreshTimer?.cancel();
    _refreshTimer = null;
    _socket.disconnect();
    _controller.close();
  }
}
