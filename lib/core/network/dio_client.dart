import 'dart:async';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:pretty_dio_logger/pretty_dio_logger.dart';
import '../constants/api_constants.dart';
import '../constants/app_constants.dart';
import '../error/exceptions.dart';

class DioClient {
  // Incremented when refresh flow fails and local auth data is cleared.
  // UI layer can listen and force auth state to unauthenticated.
  static final ValueNotifier<int> authSessionInvalidated = ValueNotifier<int>(
    0,
  );

  late final Dio _dio;
  final FlutterSecureStorage _secureStorage;
  bool _isRefreshing = false;
  final _refreshCompleter = <Completer<String>>[];

  DioClient({required FlutterSecureStorage secureStorage})
    : _secureStorage = secureStorage {
    _dio = Dio(
      BaseOptions(
        baseUrl: ApiConstants.baseUrl,
        connectTimeout: ApiConstants.connectionTimeout,
        receiveTimeout: ApiConstants.receiveTimeout,
        sendTimeout: ApiConstants.sendTimeout,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ),
    );

    _dio.interceptors.add(
      _AuthInterceptor(
        secureStorage: _secureStorage,
        onRefreshToken: _refreshToken,
      ),
    );

    if (kDebugMode) {
      _dio.interceptors.add(
        PrettyDioLogger(
          // Avoid leaking sensitive headers/tokens and reduce log overhead.
          requestHeader: false,
          requestBody: false,
          responseHeader: false,
          responseBody: false,
          error: true,
          compact: true,
        ),
      );
    }
  }

  Dio get dio => _dio;

  /// Refresh token logic with queue support for concurrent requests
  Future<String?> _refreshToken() async {
    if (_isRefreshing) {
      // Another refresh is in progress, wait for it
      final completer = Completer<String>();
      _refreshCompleter.add(completer);
      return completer.future;
    }

    _isRefreshing = true;

    try {
      final refreshToken = await _secureStorage.read(
        key: AppConstants.refreshTokenKey,
      );

      if (refreshToken == null) {
        throw const UnauthorizedException(message: 'Không có refresh token');
      }

      // Use a separate Dio instance for refresh to avoid interceptor loop
      final refreshDio = Dio(
        BaseOptions(
          baseUrl: ApiConstants.baseUrl,
          headers: {
            'Content-Type': 'application/json',
            'Accept': 'application/json',
          },
        ),
      );

      final response = await refreshDio.post(
        ApiConstants.refreshToken,
        data: {'refreshToken': refreshToken},
      );

      if (response.statusCode == 200 && response.data['success'] == true) {
        final data = response.data['data'];
        final newAccessToken = data['accessToken'] as String;
        final newRefreshToken = data['refreshToken'] as String;
        final expiresAt = data['expiresAt'] as String;

        // Save new tokens
        await Future.wait([
          _secureStorage.write(
            key: AppConstants.accessTokenKey,
            value: newAccessToken,
          ),
          _secureStorage.write(
            key: AppConstants.refreshTokenKey,
            value: newRefreshToken,
          ),
          _secureStorage.write(
            key: AppConstants.tokenExpiryKey,
            value: expiresAt,
          ),
        ]);

        // Notify waiting requests
        for (final completer in _refreshCompleter) {
          completer.complete(newAccessToken);
        }
        _refreshCompleter.clear();

        return newAccessToken;
      } else {
        throw const UnauthorizedException(
          message: 'Không thể làm mới phiên đăng nhập',
        );
      }
    } catch (e) {
      // Notify waiting requests of failure
      for (final completer in _refreshCompleter) {
        completer.completeError(e);
      }
      _refreshCompleter.clear();

      // Clear tokens on refresh failure
      await _secureStorage.deleteAll();
      authSessionInvalidated.value++;
      rethrow;
    } finally {
      _isRefreshing = false;
    }
  }
}

/// Auth Interceptor for adding JWT token to requests and handling refresh
class _AuthInterceptor extends QueuedInterceptor {
  final FlutterSecureStorage _secureStorage;
  final Future<String?> Function() onRefreshToken;

  _AuthInterceptor({
    required FlutterSecureStorage secureStorage,
    required this.onRefreshToken,
  }) : _secureStorage = secureStorage;

  /// Endpoints that don't require authentication
  static const _publicEndpoints = [
    '/auth/login',
    '/auth/register',
    '/auth/refresh-token',
    '/auth/forgot-password',
    '/auth/resend-otp',
    '/auth/verify-otp',
    '/auth/reset-password',
    '/auth/google-login',
  ];

  bool _isPublicEndpoint(String path) {
    return _publicEndpoints.any((endpoint) => path == endpoint);
  }

  @override
  void onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    // Skip adding token for public endpoints
    if (_isPublicEndpoint(options.path)) {
      return handler.next(options);
    }

    final token = await _secureStorage.read(key: AppConstants.accessTokenKey);
    if (token != null) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    handler.next(options);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    // Handle 401 Unauthorized - try to refresh token
    if (err.response?.statusCode == 401 &&
        !_isPublicEndpoint(err.requestOptions.path)) {
      try {
        final newToken = await onRefreshToken();
        if (newToken != null) {
          // Retry the original request with new token
          err.requestOptions.headers['Authorization'] = 'Bearer $newToken';

          final retryDio = Dio(
            BaseOptions(
              baseUrl: ApiConstants.baseUrl,
              headers: err.requestOptions.headers,
            ),
          );

          final response = await retryDio.fetch(err.requestOptions);
          return handler.resolve(response);
        }
      } catch (e) {
        // Refresh failed, propagate the error
        return handler.reject(
          DioException(
            requestOptions: err.requestOptions,
            error: const UnauthorizedException(
              message: 'Phiên đăng nhập đã hết hạn. Vui lòng đăng nhập lại.',
            ),
            type: DioExceptionType.badResponse,
          ),
        );
      }
    }

    // Convert DioException to custom exceptions
    // NOTE: Must use handler.reject(), NOT throw. Throwing inside an async
    // interceptor does NOT propagate through Dio pipeline correctly.
    switch (err.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return handler.reject(
          DioException(
            requestOptions: err.requestOptions,
            error: const NetworkException(message: 'Kết nối quá thời gian chờ'),
            type: err.type,
          ),
        );
      case DioExceptionType.connectionError:
        return handler.reject(
          DioException(
            requestOptions: err.requestOptions,
            error: const NetworkException(
              message: 'Không thể kết nối đến máy chủ',
            ),
            type: DioExceptionType.connectionError,
          ),
        );
      case DioExceptionType.badResponse:
        try {
          _handleBadResponse(err.response);
        } catch (e) {
          return handler.reject(
            DioException(
              requestOptions: err.requestOptions,
              error: e,
              type: DioExceptionType.badResponse,
              response: err.response,
            ),
          );
        }
        break;
      default:
        return handler.reject(
          DioException(
            requestOptions: err.requestOptions,
            error: ServerException(
              message: err.message ?? 'Đã xảy ra lỗi không xác định',
            ),
            type: err.type,
          ),
        );
    }
    handler.next(err);
  }

  void _handleBadResponse(Response? response) {
    if (response == null) {
      throw const ServerException(
        message: 'Không nhận được phản hồi từ server',
      );
    }

    final statusCode = response.statusCode;
    final data = response.data;
    String message = 'Đã xảy ra lỗi';

    if (data is Map<String, dynamic>) {
      message = data['message'] ?? message;
    }

    switch (statusCode) {
      case 400:
        throw ServerException(message: message, statusCode: 400);
      case 401:
        throw UnauthorizedException(message: message);
      case 403:
        throw ForbiddenException(message: message);
      case 404:
        throw ServerException(message: message, statusCode: 404);
      case 409:
        throw ServerException(message: message, statusCode: 409);
      case 500:
        throw const ServerException(
          message: 'Lỗi server. Vui lòng thử lại sau.',
          statusCode: 500,
        );
      default:
        throw ServerException(message: message, statusCode: statusCode);
    }
  }
}
