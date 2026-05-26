import 'package:equatable/equatable.dart';

/// Base Failure chung cho lỗi Clean Architecture, dùng Equatable để so sánh giá trị.
abstract class Failure extends Equatable {
  final String message;
  final int? statusCode;

  const Failure({required this.message, this.statusCode});

  @override
  List<Object?> get props => [message, statusCode];
}

/// Server Failure - API/Network related errors
class ServerFailure extends Failure {
  const ServerFailure({required super.message, super.statusCode});
}

/// Cache Failure - Local storage related errors
class CacheFailure extends Failure {
  const CacheFailure({required super.message});
}

/// Network Failure - No internet connection
class NetworkFailure extends Failure {
  const NetworkFailure({
    super.message = 'Không có kết nối mạng. Vui lòng kiểm tra lại.',
  });
}

/// Authentication Failure - Login/Auth related errors
class AuthenticationFailure extends Failure {
  const AuthenticationFailure({required super.message, super.statusCode});
}

/// Unauthorized Failure - Token expired or invalid
class UnauthorizedFailure extends Failure {
  const UnauthorizedFailure({
    super.message = 'Phiên đăng nhập đã hết hạn. Vui lòng đăng nhập lại.',
  });
}

/// Forbidden Failure - Access denied (wrong role)
class ForbiddenFailure extends Failure {
  const ForbiddenFailure({
    super.message = 'Bạn không có quyền truy cập tính năng này.',
  });
}

/// Validation Failure - Input validation errors
class ValidationFailure extends Failure {
  final List<String>? errors;

  const ValidationFailure({required super.message, this.errors});

  @override
  List<Object?> get props => [message, statusCode, errors];
}

/// Unknown Failure - Unexpected errors
class UnknownFailure extends Failure {
  const UnknownFailure({
    super.message = 'Đã xảy ra lỗi không xác định. Vui lòng thử lại.',
  });
}
