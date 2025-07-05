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
      'autoConnect': false,
      'reconnection': true,
    });

    _socket.auth = {'token': await _storage.read(key: 'refreshToken')};
    _socket.connect();

    _socket.onConnect((_) {
      print('🔌 Socket connected');
      _hasEmittedOfflineState = false;
      _startRefreshLoop();
    });

    _socket.on('unauthenticated', (_) {
      print('🔒 Socket unauthenticated');
      _controller.add(AuthState.unauthenticated());
    });

    _socket.onDisconnect((_) {
      print('🔌 Socket disconnected');
      _refreshTimer?.cancel();
      _refreshTimer = null;
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
        final [accessToken, refreshToken] = await Future.wait([
          _storage.read(key: 'accessToken'),
          _storage.read(key: 'refreshToken'),
        ]);
        _socket.auth = {'token': refreshToken};
        _controller.add(AuthState.fromToken(accessToken, isOffline: true));
      }
    });

    _socket.on('access-token', (data) async {
      final newAccessToken = data['accessToken'];
      final newRefreshToken = data['refreshToken'];
      await Future.wait([
        _storage.write(key: 'accessToken', value: newAccessToken),
        _storage.write(key: 'refreshToken', value: newRefreshToken),
      ]);
      _socket.auth = {'token': newRefreshToken};
      _controller.add(AuthState.fromToken(newAccessToken));
    });

    _socket.on('force-logout', (_) async {
      print('🔒 Force logout received');
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

    // 🕒 Periodic refresh every 5 minutes
    _refreshTimer = Timer.periodic(const Duration(minutes: 5), (_) async {
      final refreshToken = await _storage.read(key: 'refreshToken');
      if (refreshToken != null) {
        _socket.emit('refresh-token', {'refreshToken': refreshToken});
      } else {
        // No token available — user is unauthenticated
        _controller.add(AuthState.unauthenticated());
      }
    });
  }

  void emitSignOut() {
    _socket.disconnect();
    _socket.auth = {};
    print("Socket auth: ${_socket.auth}");
    _controller.add(AuthState.unauthenticated());
  }

  void emitSignIn({required String accessToken, required String refreshToken}) {
    _socket.auth = {'token': refreshToken};
    _socket.connect();
  }

  void dispose() {
    _refreshTimer?.cancel();
    _refreshTimer = null;
    _socket.destroy();
    _controller.close();
  }
}
