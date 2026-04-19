import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/auth_result.dart';
import '../repositories/auth_repository.dart';

/// Refresh token use case.
class RefreshTokenUseCase implements UseCase<AuthResult, NoParams> {
  final AuthRepository repository;

  RefreshTokenUseCase(this.repository);

  @override
  Future<Either<Failure, AuthResult>> call(NoParams params) async {
    return repository.refreshToken();
  }
}
