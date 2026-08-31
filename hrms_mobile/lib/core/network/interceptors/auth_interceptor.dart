import 'package:dio/dio.dart';
import '../../storage/secure_storage_service.dart';
import '../api_endpoints.dart';

class AuthInterceptor extends QueuedInterceptor {
  final SecureStorageService _storage;
  final Dio _dio;
  bool _isRefreshing = false;
  final List<void Function(String token)> _retryQueue = [];

  AuthInterceptor({
    required SecureStorageService storage,
    required Dio dio,
  })  : _storage = storage,
        _dio = dio;

  @override
  void onRequest(
      RequestOptions options, RequestInterceptorHandler handler) async {
    // Skip token for login
    if (options.path.contains('/login')) {
      return handler.next(options);
    }

    final token = await _storage.getAccessToken();
    if (token != null && token.isNotEmpty) {
      options.headers['Authorization'] = 'Bearer $token';
    }

    handler.next(options);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    if (err.response?.statusCode == 401 &&
        !err.requestOptions.path.contains('/login') &&
        !err.requestOptions.path.contains('/refresh-token')) {
      final refreshToken = await _storage.getRefreshToken();

      if (refreshToken != null && refreshToken.isNotEmpty) {
        if (!_isRefreshing) {
          _isRefreshing = true;

          try {
            final tenant = await _storage.getTenant();
            final refreshResponse = await _dio.post(
              ApiEndpoints.refreshToken,
              data: {'refreshToken': refreshToken},
              options: Options(
                headers: {
                  if (tenant != null) 'x-tenant': tenant,
                },
              ),
            );

            final newAccessToken =
                refreshResponse.data?['data']?['accessToken'] ??
                    refreshResponse.data?['accessToken'];
            final newRefreshToken =
                refreshResponse.data?['data']?['refreshToken'] ??
                    refreshResponse.data?['refreshToken'];

            if (newAccessToken != null) {
              await _storage.saveTokens(
                accessToken: newAccessToken,
                refreshToken: newRefreshToken,
              );

              _isRefreshing = false;

              // Process queued requests
              for (final callback in _retryQueue) {
                callback(newAccessToken);
              }
              _retryQueue.clear();

              // Retry original request
              final requestOptions = err.requestOptions;
              requestOptions.headers['Authorization'] = 'Bearer $newAccessToken';

              final retryResponse = await _dio.fetch(requestOptions);
              return handler.resolve(retryResponse);
            }
          } catch (e) {
            _isRefreshing = false;
            _retryQueue.clear();
            await _storage.clearSession();
          }
        } else {
          // Add to pending retry queue
          _retryQueue.add((newToken) async {
            final requestOptions = err.requestOptions;
            requestOptions.headers['Authorization'] = 'Bearer $newToken';
            try {
              final response = await _dio.fetch(requestOptions);
              handler.resolve(response);
            } catch (e) {
              handler.reject(err);
            }
          });
          return;
        }
      } else {
        await _storage.clearSession();
      }
    }

    handler.next(err);
  }
}
