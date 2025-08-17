import 'dart:io';
import 'package:dio/dio.dart';
import 'package:dio_cache_interceptor/dio_cache_interceptor.dart';
import 'package:http_cache_hive_store/http_cache_hive_store.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hello_truck_app/providers/auth_providers.dart';
import 'package:hello_truck_app/auth/api_exception.dart';

class API {
  final Dio _dio = Dio();
  String? accessToken;
  late CacheStore _cacheStore;
  late CacheOptions _cacheOptions;
  // static const String baseUrl = 'http://10.0.2.2:3000';
  static const String baseUrl = 'https://hello-truck-server.fly.dev';
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
      hitCacheOnNetworkFailure: true,
      policy: CachePolicy.request,
      hitCacheOnErrorCodes: [
        429,  // Too many requests
        408, 499,  // Client timeouts
        500, 501, 502, 503, 504, 505, 506, 507, 509,  // Server errors
        521, 522, 523, 524,  // Cloudflare specific network errors
      ],
      maxStale: const Duration(days: 7),
      priority: CachePriority.normal,
      keyBuilder: CacheOptions.defaultCacheKeyBuilder,
      allowPostMethod: false,
    );

    _dio.interceptors.addAll([
      _authInterceptor,
      DioCacheInterceptor(options: _cacheOptions),
      _errorInterceptor,
    ]);
  }

  InterceptorsWrapper get _authInterceptor => InterceptorsWrapper(
    onRequest: (options, handler) {
      if (accessToken != null) {
        options.headers['Authorization'] = 'Bearer $accessToken';
      }
      return handler.next(options);
    },
  );

  InterceptorsWrapper get _errorInterceptor => InterceptorsWrapper(
    onError: (error, handler) {
      if (error.response?.statusCode == 401) {
        // Schedule sign out after 2 seconds if the error is an unauthorized error
        Future.delayed(const Duration(seconds: 2), () {
          signOut();
        });
      }

      // Convert DioException to APIException and continue with error handling
      handler.reject(APIException.fromDioException(error));
    },
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

  Future<String> uploadFile(File file, String filePath, String type) async {
    final prefix = ['png', 'jpg', 'jpeg'].contains(type.split('/').last) ? 'image' : 'application';
    final fileType = '$prefix/${type.split('/').last}';
    try {
      final signedUrlResponse = await _dio.get(
        '$baseUrl/bookings/customer/upload-url?filePath=$filePath&type=$fileType',
      );

      final signedUrl = signedUrlResponse.data['signedUrl'];
      final publicUrl = signedUrlResponse.data['publicUrl'];
      final token = signedUrlResponse.data['token'];

      await _dio.put(
        signedUrl,
        data: file.readAsBytesSync(),
        options: Options(
          contentType: fileType,
          headers: {
            'x-goog-meta-firebasestoragedownloadtokens': token,
          },
        ),
      );

      return publicUrl;
    } catch (e) {
      print('Error uploading file: $e');
      rethrow;
    }
  }

  Future<void> clearCache() async {
    await _cacheStore.clean();
  }

  Future<void> dispose() async {
    await _cacheStore.close();
  }

  // Auth Methods
  Future<void> sendOtp(String phoneNumber) async {
    final response = await post(
      '/auth/customer/send-otp',
      data: {'phoneNumber': phoneNumber},
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to send OTP');
    }
  }

  Future<void> verifyOtp(String phoneNumber, String otp) async {
    final staleRefreshToken = await storage.read(key: 'staleRefreshToken');

    final response = await post(
      '/auth/customer/verify-otp',
      data: {
        'phoneNumber': phoneNumber,
        'otp': otp,
        'staleRefreshToken': staleRefreshToken,
      },
    );
    await Future.wait([
      storage.write(
        key: 'refreshToken',
        value: response.data['refreshToken'],
      ),
      storage.write(key: 'accessToken', value: response.data['accessToken']),
    ]);

    ref.read(authClientProvider).emitSignIn(
      accessToken: response.data['accessToken'],
      refreshToken: response.data['refreshToken'],
    );
  }

  Future<void> signOut() async {
    final refreshToken = await storage.read(key: 'refreshToken');

    if (refreshToken != null) {
      try {
        await post('/auth/customer/logout', data: {'refreshToken': refreshToken});
      } catch (e) {
        // If logout failed, save the refresh token to the storage
        await storage.write(key: 'staleRefreshToken', value: refreshToken);
      } finally {
        // Clear both tokens regardless of success or failure
        await Future.wait([
          storage.delete(key: 'refreshToken'),
          storage.delete(key: 'accessToken'),
        ]);
        ref.read(authClientProvider).emitSignOut();
      }
    }
  }
}
