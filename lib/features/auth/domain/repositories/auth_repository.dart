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

  /// Logout the current user
  Future<Either<Failure, void>> logout();

  /// Get cached user from local storage
  Future<Either<Failure, User>> getCachedUser();

  /// Check if user is currently logged in (has valid token)
  Future<Either<Failure, bool>> isLoggedIn();

  /// Get the current access token
  Future<Either<Failure, String>> getAccessToken();
}
