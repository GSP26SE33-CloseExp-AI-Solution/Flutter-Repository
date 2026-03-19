import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/auth_result.dart';
import '../entities/user.dart';

/// Auth Repository Interface - Domain Layer
///
/// This is the contract for authentication operations.
/// The implementation is in the data layer.
abstract class AuthRepository {
  /// Login with email and password
  Future<Either<Failure, AuthResult>> login({
    required String email,
    required String password,
  });

  /// Refresh access token using refresh token
  Future<Either<Failure, AuthResult>> refreshToken();

  /// Logout the current user (local only)
  Future<Either<Failure, void>> logout();

  /// Logout with refresh token (remote + local)
  Future<Either<Failure, void>> logoutWithToken();

  /// Logout from all devices
  Future<Either<Failure, void>> logoutAll();

  /// Get cached user from local storage
  Future<Either<Failure, User>> getCachedUser();

  /// Check if user is currently logged in (has valid token)
  Future<Either<Failure, bool>> isLoggedIn();

  /// Get the current access token
  Future<Either<Failure, String>> getAccessToken();

  /// Get the current refresh token
  Future<Either<Failure, String>> getRefreshToken();

  // ============== USER PROFILE ==============

  /// Get current user profile from server
  Future<Either<Failure, User>> getCurrentUser();

  /// Update current user profile
  Future<Either<Failure, User>> updateProfile({
    String? fullName,
    String? phone,
  });
}
