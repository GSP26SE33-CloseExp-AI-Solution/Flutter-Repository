import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';

/// Upload repository contract cho ảnh chứng minh giao hàng.
abstract class UploadRepository {
  /// Upload a local file path and return public URL
  Future<Either<Failure, String>> uploadFilePath(String filePath);
}

