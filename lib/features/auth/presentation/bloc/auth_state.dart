import 'package:equatable/equatable.dart';
import '../../domain/entities/user.dart';

/// Auth State - Presentation Layer (BLoC)
///
/// Represents the different states of authentication.
abstract class AuthState extends Equatable {
  const AuthState();

  @override
  List<Object?> get props => [];
}

/// Initial state - checking auth status
class AuthInitial extends AuthState {
  const AuthInitial();
}

/// Checking authentication status (loading spinner on splash)
class AuthLoading extends AuthState {
  const AuthLoading();
}

/// User is authenticated and logged in
class AuthAuthenticated extends AuthState {
  final User user;

  const AuthAuthenticated({required this.user});

  @override
  List<Object?> get props => [user];
}

/// User is not authenticated (show login screen)
class AuthUnauthenticated extends AuthState {
  const AuthUnauthenticated();
}

/// Authentication failed with error message
class AuthError extends AuthState {
  final String message;

  const AuthError({required this.message});

  @override
  List<Object?> get props => [message];
}

/// Login in progress
class LoginLoading extends AuthState {
  const LoginLoading();
}

/// Logout in progress
class LogoutLoading extends AuthState {
  const LogoutLoading();
}
