import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/user_image.dart';
import '../repositories/auth_repository.dart';

class UploadCurrentUserImageUseCase
    extends UseCase<UserImage, UploadCurrentUserImageParams> {
  final AuthRepository repository;

  UploadCurrentUserImageUseCase(this.repository);

  @override
  Future<Either<Failure, UserImage>> call(UploadCurrentUserImageParams params) {
    return repository.uploadCurrentUserImage(
      filePath: params.filePath,
      imageType: params.imageType,
      setAsPrimary: params.setAsPrimary,
    );
  }
}

class UploadCurrentUserImageParams extends Equatable {
  final String filePath;
  final String imageType;
  final bool setAsPrimary;

  const UploadCurrentUserImageParams({
    required this.filePath,
    this.imageType = 'avatar',
    this.setAsPrimary = true,
  });

  @override
  List<Object?> get props => [filePath, imageType, setAsPrimary];
}
