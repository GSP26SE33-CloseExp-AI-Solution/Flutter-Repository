import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../repositories/auth_repository.dart';

/// Logout Use Case - Domain Layer
///
/// Handles the business logic for user logout.
class LogoutUseCase implements UseCase<void, NoParams> {
  final AuthRepository repository;

  LogoutUseCase(this.repository);

  @override
  Future<Either<Failure, void>> call(NoParams params) async {
    // Revoke refresh token on server when possible, then clear local auth data.
    return await repository.logoutWithToken();
  }
}
