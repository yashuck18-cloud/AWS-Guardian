import 'package:dio/dio.dart';
import '../constants/api_constants.dart';
import '../storage/secure_storage_service.dart';
import '../storage/local_preferences.dart';
import 'network_exceptions.dart';

class ApiClient {
  final Dio _dio;
  final SecureStorageService _secureStorage;
  final LocalPreferences _localPreferences;
  bool _isFailingOver = false;

  ApiClient({
    required SecureStorageService secureStorage,
    required LocalPreferences localPreferences,
    Dio? dio,
  })  : _secureStorage = secureStorage,
        _localPreferences = localPreferences,
        _dio = dio ?? Dio() {
    _initDio();
  }

  void _initDio() {
    _dio.options = BaseOptions(
      baseUrl: _localPreferences.apiBaseUrl,
      connectTimeout: const Duration(seconds: 25),
      receiveTimeout: const Duration(seconds: 45),
      sendTimeout: const Duration(seconds: 20),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        'ngrok-skip-browser-warning': 'true',
      },
    );

    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          // Dynamic base url check
          options.baseUrl = _localPreferences.apiBaseUrl;
          final token = await _secureStorage.getAuthToken();
          if (token != null && token.isNotEmpty) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          return handler.next(options);
        },
        onError: (DioException e, handler) {
          return handler.next(e);
        },
      ),
    );
  }

  bool _isConnectionIssue(DioException e) {
    return e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.connectionError ||
        e.type == DioExceptionType.sendTimeout;
  }

  Future<bool> _tryAutoFailover() async {
    if (_isFailingOver) return false;
    _isFailingOver = true;

    try {
      final currentUrl = _localPreferences.apiBaseUrl;
      for (final candidate in ApiConstants.fallbackUrls) {
        if (candidate == currentUrl) continue;
        try {
          final probeDio = Dio(
            BaseOptions(
              baseUrl: candidate,
              connectTimeout: const Duration(milliseconds: 1500),
              receiveTimeout: const Duration(milliseconds: 1500),
            ),
          );
          final res = await probeDio.get('/health/');
          if (res.statusCode == 200) {
            await _localPreferences.setApiBaseUrl(candidate);
            _dio.options.baseUrl = candidate;
            return true;
          }
        } catch (_) {
          // Probe failed for this candidate, try next
        }
      }
      return false;
    } finally {
      _isFailingOver = false;
    }
  }

  Future<dynamic> _executeWithFallback(
    Future<Response<dynamic>> Function() makeRequest,
  ) async {
    try {
      final response = await makeRequest();
      return response.data;
    } on DioException catch (e) {
      if (_isConnectionIssue(e)) {
        final switched = await _tryAutoFailover();
        if (switched) {
          try {
            final retryResponse = await makeRequest();
            return retryResponse.data;
          } on DioException catch (retryError) {
            throw ApiException.fromDioError(retryError);
          }
        }
      }
      throw ApiException.fromDioError(e);
    } catch (e) {
      throw ApiException(message: e.toString());
    }
  }

  Future<dynamic> get(
    String path, {
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    return _executeWithFallback(
      () => _dio.get(
        path,
        queryParameters: queryParameters,
        options: options,
      ),
    );
  }

  Future<dynamic> post(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    return _executeWithFallback(
      () => _dio.post(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
      ),
    );
  }

  Future<dynamic> patch(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    return _executeWithFallback(
      () => _dio.patch(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
      ),
    );
  }

  Future<dynamic> delete(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    return _executeWithFallback(
      () => _dio.delete(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
      ),
    );
  }
}
