import 'package:dio/dio.dart';
import 'package:dio_cache_interceptor/dio_cache_interceptor.dart';
import 'package:dio_cache_interceptor_hive_store/dio_cache_interceptor_hive_store.dart';
import 'package:path_provider/path_provider.dart';

class API {
  final Dio _dio = Dio();
  String? accessToken;
  late CacheStore _cacheStore;
  late CacheOptions _cacheOptions;

  API({this.accessToken});

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
    path,
    options: _cacheOptions
        .copyWith(policy: policy ?? _cacheOptions.policy)
        .toOptions(),
  );

  Future<Response> post(String path, {dynamic data}) =>
      _dio.post(path, data: data);

  Future<Response> put(String path, {dynamic data}) =>
      _dio.put(path, data: data);

  Future<Response> patch(String path, {dynamic data}) =>
      _dio.patch(path, data: data);

  Future<Response> delete(String path) => _dio.delete(path);

  Future<void> clearCache() async {
    await _cacheStore.clean();
  }

  Future<void> dispose() async {
    await _cacheStore.close();
  }
}
