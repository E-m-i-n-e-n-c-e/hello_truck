import 'dart:async';
import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:dio/dio.dart';
import '../models/auth_state.dart';
import 'package:flutter/widgets.dart';
import 'package:hello_truck_app/utils/constants.dart';

import '../utils/logger.dart';

class AuthClient with WidgetsBindingObserver {
  static final AuthClient _instance = AuthClient._();
  factory AuthClient() => _instance;
  AuthClient._() {
    WidgetsBinding.instance.addObserver(this);
  }

  final _controller = StreamController<AuthState>.broadcast();
  final _appLifecycleController = StreamController<AppLifecycleState>.broadcast();
  Stream<AuthState> get authStateStream => _controller.stream;
  Stream<AppLifecycleState> get appLifecycleStream => _appLifecycleController.stream;

  final _storage = const FlutterSecureStorage();
  final _dio = Dio();
  Timer? _refreshTimer;
  Timer? _retryTimer;
  int _retryDelay = 0;
  bool _isRefreshing = false;

  DateTime? _lastPausedAt;

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _appLifecycleController.add(state);

    if (state == AppLifecycleState.paused) {
      _lastPausedAt = DateTime.now();
      // Don't cancel the timer - let it keep refreshing in background
    }

    if (state == AppLifecycleState.resumed) {
      // Only do immediate refresh if app was paused for more than 15 seconds
      final wasPausedLongEnough = _lastPausedAt != null &&
          DateTime.now().difference(_lastPausedAt!).inSeconds > 15;

      if (wasPausedLongEnough) {
        AppLogger.log('App resumed after long pause, Reinitializing');
        initialize();
      }
      _lastPausedAt = null;
    }
  }

  Future<void> initialize() async {
    await refreshTokens();
    _startRefreshLoop();
  }

  Future<void> refreshTokens() async {
    if (_isRefreshing) return;
    _isRefreshing = true;
    try {
      final refreshToken = await _storage.read(key: 'refreshToken');
      // if (refreshToken == null) {
      //   _controller.add(AuthState.unauthenticated());
      //   return;
      // }

      final response = await _dio.post(
        '$baseUrl/auth/customer/refresh-token',
        data: {'refreshToken': refreshToken},
      );
      final data = response.data;
      final newAccessToken = data['accessToken'];
      final newRefreshToken = data['refreshToken'];

      await Future.wait([
        _storage.write(key: 'accessToken', value: newAccessToken),
        _storage.write(key: 'refreshToken', value: newRefreshToken),
      ]);

      _controller.add(AuthState.fromToken(newAccessToken));
      _retryDelay = 0;
    } on Exception catch (e) {
      final logoutCodes = [400, 401, 403];
      final shouldLogout = (e is DioException && logoutCodes.contains(e.response?.statusCode)) || (e is PlatformException);
      if (!shouldLogout) {
        AppLogger.log('🔄 Token refresh error: $e');
        final accessToken = await _storage.read(key: 'accessToken');
        _controller.add(AuthState.fromToken(accessToken, isOffline: true));
        _retryDelay++;
        _retryTimer?.cancel();
        _retryTimer = Timer(Duration(seconds: _retryDelay.clamp(1, 8)), () {
          refreshTokens();
        });
      } else if (shouldLogout) {
        // If token is missing or invalid or if corrupted secure storage
        AppLogger.log('🔄 Token refresh error: $e');
        await _storage.deleteAll();
        _controller.add(AuthState.unauthenticated());
      }
    } finally {
      _isRefreshing = false;
    }
  }

  void _startRefreshLoop() {
    _refreshTimer?.cancel();

    // Refresh tokens every 5 minutes
    _refreshTimer = Timer.periodic(const Duration(minutes: 5), (_) {
      refreshTokens();
    });
  }

  Future<void> emitSignIn({required String accessToken, required String refreshToken}) async {
    await Future.wait([
      _storage.write(key: 'accessToken', value: accessToken),
      _storage.write(key: 'refreshToken', value: refreshToken),
    ]);
    _controller.add(AuthState.fromToken(accessToken));
    _startRefreshLoop();
  }

  Future<void> emitSignOut() async {
    await _storage.deleteAll();
    _retryDelay = 0;
    _retryTimer?.cancel();
    _retryTimer = null;
    _refreshTimer?.cancel();
    _refreshTimer = null;
    _controller.add(AuthState.unauthenticated());
  }

  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _retryDelay = 0;
    _retryTimer?.cancel();
    _retryTimer = null;
    _refreshTimer?.cancel();
    _refreshTimer = null;
    _controller.close();
    _appLifecycleController.close();
  }
}