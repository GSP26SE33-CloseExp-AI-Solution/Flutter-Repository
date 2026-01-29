// Custom Exceptions for CloseExp Delivery Staff App
//
// These exceptions are thrown in the data layer and caught in repositories
// to be converted to Failures.

/// Base Exception class
class AppException implements Exception {
  final String message;
  final int? statusCode;

  const AppException({required this.message, this.statusCode});

  @override
  String toString() => 'AppException: $message (Status: $statusCode)';
}

/// Server Exception - API errors
class ServerException extends AppException {
  const ServerException({required super.message, super.statusCode});
}

/// Cache Exception - Local storage errors
class CacheException extends AppException {
  const CacheException({required super.message});
}

/// Network Exception - No internet
class NetworkException extends AppException {
  const NetworkException({super.message = 'Không có kết nối mạng'});
}

/// Authentication Exception - Login failures
class AuthenticationException extends AppException {
  const AuthenticationException({required super.message, super.statusCode});
}

/// Unauthorized Exception - 401 errors
class UnauthorizedException extends AppException {
  const UnauthorizedException({
    super.message = 'Phiên đăng nhập đã hết hạn',
    super.statusCode = 401,
  });
}

/// Forbidden Exception - 403 errors
class ForbiddenException extends AppException {
  const ForbiddenException({
    super.message = 'Không có quyền truy cập',
    super.statusCode = 403,
  });
}
