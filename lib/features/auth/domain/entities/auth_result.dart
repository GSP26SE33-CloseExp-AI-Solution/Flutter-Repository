import 'package:equatable/equatable.dart';
import 'user.dart';

/// Auth result entity: token và thông tin user sau đăng nhập.
class AuthResult extends Equatable {
  final String accessToken;
  final String refreshToken;
  final DateTime expiresAt;
  final User user;

  const AuthResult({
    required this.accessToken,
    required this.refreshToken,
    required this.expiresAt,
    required this.user,
  });

  /// Check if the token is expired
  bool get isExpired => DateTime.now().isAfter(expiresAt);

  /// Check if token will expire within given duration
  bool willExpireIn(Duration duration) {
    return DateTime.now().add(duration).isAfter(expiresAt);
  }

  @override
  List<Object?> get props => [accessToken, refreshToken, expiresAt, user];
}
