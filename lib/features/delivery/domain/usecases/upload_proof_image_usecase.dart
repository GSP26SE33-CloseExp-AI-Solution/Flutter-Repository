import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../repositories/upload_repository.dart';

class UploadProofImageParams {
  final String filePath;
  const UploadProofImageParams({required this.filePath});
}

class UploadProofImageUseCase
    implements UseCase<String, UploadProofImageParams> {
  final UploadRepository repository;

  UploadProofImageUseCase(this.repository);

  @override
  Future<Either<Failure, String>> call(UploadProofImageParams params) {
    return repository.uploadFilePath(params.filePath);
  }
}

