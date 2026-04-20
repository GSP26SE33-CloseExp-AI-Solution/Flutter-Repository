import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../repositories/auth_repository.dart';

class DeleteCurrentUserImageUseCase
    extends UseCase<void, DeleteCurrentUserImageParams> {
  final AuthRepository repository;

  DeleteCurrentUserImageUseCase(this.repository);

  @override
  Future<Either<Failure, void>> call(DeleteCurrentUserImageParams params) {
    return repository.deleteCurrentUserImage(params.imageId);
  }
}

class DeleteCurrentUserImageParams extends Equatable {
  final String imageId;

  const DeleteCurrentUserImageParams({required this.imageId});

  @override
  List<Object?> get props => [imageId];
}
