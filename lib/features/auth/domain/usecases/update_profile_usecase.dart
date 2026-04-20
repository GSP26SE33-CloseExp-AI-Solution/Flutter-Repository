import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/user.dart';
import '../repositories/auth_repository.dart';

class UpdateProfileUseCase extends UseCase<User, UpdateProfileParams> {
  final AuthRepository repository;

  UpdateProfileUseCase(this.repository);

  @override
  Future<Either<Failure, User>> call(UpdateProfileParams params) {
    return repository.updateProfile(
      fullName: params.fullName,
      phone: params.phone,
    );
  }
}

class UpdateProfileParams extends Equatable {
  final String? fullName;
  final String? phone;

  const UpdateProfileParams({this.fullName, this.phone});

  @override
  List<Object?> get props => [fullName, phone];
}
