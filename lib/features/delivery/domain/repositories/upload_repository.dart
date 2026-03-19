import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';

/// Upload Repository Interface - Domain Layer
///
/// Defines contract for uploading proof images/files.
abstract class UploadRepository {
  /// Upload a local file path and return public URL
  Future<Either<Failure, String>> uploadFilePath(String filePath);
}

