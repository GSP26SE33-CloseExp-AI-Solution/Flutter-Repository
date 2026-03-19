import 'dart:io';

import 'package:dartz/dartz.dart';
import '../../../../core/error/exceptions.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/network/network_info.dart';
import '../../domain/repositories/upload_repository.dart';
import '../datasources/upload_datasource.dart';

class UploadRepositoryImpl implements UploadRepository {
  final UploadDataSource dataSource;
  final NetworkInfo networkInfo;

  UploadRepositoryImpl({required this.dataSource, required this.networkInfo});

  @override
  Future<Either<Failure, String>> uploadFilePath(String filePath) async {
    if (!await networkInfo.isConnected) {
      return const Left(NetworkFailure());
    }

    try {
      final result = await dataSource.uploadFile(File(filePath));
      if (result.url.trim().isEmpty) {
        return const Left(ServerFailure(message: 'Upload thành công nhưng thiếu URL'));
      }
      return Right(result.url);
    } on UnauthorizedException {
      return const Left(UnauthorizedFailure());
    } on ForbiddenException {
      return const Left(ForbiddenFailure());
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message, statusCode: e.statusCode));
    } on NetworkException {
      return const Left(NetworkFailure());
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }
}

