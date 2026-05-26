import 'package:equatable/equatable.dart';

/// Auth events kích hoạt thay đổi trạng thái trong AuthBloc.
abstract class AuthEvent extends Equatable {
  const AuthEvent();

  @override
  List<Object?> get props => [];
}

/// Check if user is already logged in (app startup)
class CheckAuthStatusEvent extends AuthEvent {
  const CheckAuthStatusEvent();
}

/// Login with email and password
class LoginEvent extends AuthEvent {
  final String email;
  final String password;

  const LoginEvent({required this.email, required this.password});

  @override
  List<Object?> get props => [email, password];
}

/// Logout the current user
class LogoutEvent extends AuthEvent {
  const LogoutEvent();
}

/// Triggered when interceptor detects unrecoverable auth session expiration.
class SessionExpiredEvent extends AuthEvent {
  const SessionExpiredEvent();
}

/// Update profile details for current shipper
class UpdateProfileEvent extends AuthEvent {
  final String fullName;
  final String? phone;

  const UpdateProfileEvent({required this.fullName, this.phone});

  @override
  List<Object?> get props => [fullName, phone];
}
