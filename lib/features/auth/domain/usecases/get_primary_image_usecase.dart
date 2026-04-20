import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/user_image.dart';
import '../repositories/auth_repository.dart';

class GetPrimaryImageUseCase extends UseCase<UserImage?, NoParams> {
  final AuthRepository repository;

  GetPrimaryImageUseCase(this.repository);

  @override
  Future<Either<Failure, UserImage?>> call(NoParams params) {
    return repository.getPrimaryImage();
  }
}
