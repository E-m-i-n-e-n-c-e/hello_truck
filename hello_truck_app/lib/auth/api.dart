import 'package:dio/dio.dart';
import 'package:dio_cache_interceptor/dio_cache_interceptor.dart';
import 'package:dio_cache_interceptor_hive_store/dio_cache_interceptor_hive_store.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hello_truck_app/auth/auth_providers.dart';

class API {
  final Dio _dio = Dio();
  String? accessToken;
  late CacheStore _cacheStore;
  late CacheOptions _cacheOptions;
  static const String baseUrl = 'http://10.0.2.2:3000';
  final storage = const FlutterSecureStorage();
  final Ref ref;

  API({this.accessToken, required this.ref});

  void updateToken(String? newToken) {
    accessToken = newToken;
  }

  Future<void> init() async {
    final dir = await getTemporaryDirectory();

    _cacheStore = HiveCacheStore(dir.path, hiveBoxName: 'hello_truck_cache');

    _cacheOptions = CacheOptions(
      store: _cacheStore,
      policy: CachePolicy.request,
      hitCacheOnErrorExcept: [401, 403],
      maxStale: const Duration(days: 7),
      priority: CachePriority.normal,
      keyBuilder: CacheOptions.defaultCacheKeyBuilder,
      allowPostMethod: false,
    );

    _dio.interceptors.addAll([
      _authInterceptor,
      DioCacheInterceptor(options: _cacheOptions),
    ]);
  }

  InterceptorsWrapper get _authInterceptor => InterceptorsWrapper(
    onRequest: (options, handler) {
      if (accessToken != null) {
        options.headers['Authorization'] = 'Bearer $accessToken';
      }
      return handler.next(options);
    },
    onError: (e, handler) => handler.next(e),
  );

  Future<Response> get(String path, {CachePolicy? policy}) => _dio.get(
    '$baseUrl$path',
    options: _cacheOptions
        .copyWith(policy: policy ?? _cacheOptions.policy)
        .toOptions(),
  );

  Future<Response> post(String path, {dynamic data}) =>
      _dio.post('$baseUrl$path', data: data);

  Future<Response> put(String path, {dynamic data}) =>
      _dio.put('$baseUrl$path', data: data);

  Future<Response> patch(String path, {dynamic data}) =>
      _dio.patch('$baseUrl$path', data: data);

  Future<Response> delete(String path) => _dio.delete('$baseUrl$path');

  Future<void> clearCache() async {
    await _cacheStore.clean();
  }

  Future<void> dispose() async {
    await _cacheStore.close();
  }

  // Auth Methods
  Future<void> sendOtp(String phoneNumber) async {
    final response = await post(
      '/auth/send-otp',
      data: {'phoneNumber': phoneNumber},
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to send OTP');
    }
  }

  Future<void> verifyOtp(String phoneNumber, String otp) async {
    final staleRefreshToken = await storage.read(key: 'staleRefreshToken');

    final response = await post(
      '/auth/verify-otp',
      data: {
        'phoneNumber': phoneNumber,
        'otp': otp,
        'staleRefreshToken': staleRefreshToken,
      },
    );
    if (response.statusCode == 200) {
      await Future.wait([
        storage.write(
          key: 'refreshToken',
          value: response.data['refreshToken'],
        ),
        storage.write(key: 'accessToken', value: response.data['accessToken']),
      ]);

      final socket = ref.read(authSocketProvider);
      socket.emitSignIn(response.data['accessToken']);
      socket.connect();
    } else {
      throw Exception('Failed to verify OTP');
    }
  }

  Future<void> signOut() async {
    final refreshToken = await storage.read(key: 'refreshToken');

    if (refreshToken != null) {
      try {
        await post('/auth/logout', data: {'refreshToken': refreshToken});
      } catch (e) {
        // If logout failed, save the refresh token to the storage
        await storage.write(key: 'staleRefreshToken', value: refreshToken);
      } finally {
        // Clear both tokens regardless of success or failure
        await Future.wait([
          storage.delete(key: 'refreshToken'),
          storage.delete(key: 'accessToken'),
        ]);
        final socket = ref.read(authSocketProvider);
        socket.emitSignOut();
      }
    }
  }
}
