import 'package:dartz/dartz.dart';
import '../../../../core/error/exceptions.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/network/network_info.dart';
import '../../domain/entities/delivery_group.dart';
import '../../domain/entities/delivery_order.dart';
import '../../domain/entities/delivery_route_plan.dart';
import '../../domain/entities/delivery_stats.dart';
import '../../domain/repositories/delivery_repository.dart';
import '../datasources/delivery_remote_datasource.dart';

/// Delivery Repository Implementation - Data Layer
///
/// Implements the DeliveryRepository interface from domain layer.
/// Handles error conversion and network checks.
class DeliveryRepositoryImpl implements DeliveryRepository {
  final DeliveryRemoteDataSource remoteDataSource;
  final NetworkInfo networkInfo;

  DeliveryRepositoryImpl({
    required this.remoteDataSource,
    required this.networkInfo,
  });

  @override
  Future<Either<Failure, List<DeliveryGroupSummary>>> getAvailableGroups({
    DateTime? deliveryDate,
  }) async {
    if (!await networkInfo.isConnected) {
      return const Left(NetworkFailure());
    }

    try {
      final groups = await remoteDataSource.getAvailableGroups(
        deliveryDate: deliveryDate,
      );
      return Right(groups);
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

  @override
  Future<Either<Failure, PaginatedDeliveryGroups>> getMyGroups({
    int page = 1,
    int pageSize = 10,
    String? status,
    DateTime? deliveryDate,
  }) async {
    if (!await networkInfo.isConnected) {
      return const Left(NetworkFailure());
    }

    try {
      final response = await remoteDataSource.getMyGroups(
        page: page,
        pageSize: pageSize,
        status: status,
        deliveryDate: deliveryDate,
      );
      return Right(
        PaginatedDeliveryGroups(
          groups: response.groups,
          currentPage: response.currentPage,
          totalPages: response.totalPages,
          totalCount: response.totalCount,
          hasNextPage: response.hasNextPage,
        ),
      );
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

  @override
  Future<Either<Failure, DeliveryGroup>> getDeliveryGroupById(
    String groupId,
  ) async {
    if (!await networkInfo.isConnected) {
      return const Left(NetworkFailure());
    }

    try {
      final group = await remoteDataSource.getDeliveryGroupById(groupId);
      return Right(group);
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

  @override
  Future<Either<Failure, DeliveryGroup>> acceptDeliveryGroup(
    String groupId, {
    String? notes,
  }) async {
    if (!await networkInfo.isConnected) {
      return const Left(NetworkFailure());
    }

    try {
      final group = await remoteDataSource.acceptDeliveryGroup(
        groupId,
        notes: notes,
      );
      return Right(group);
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

  @override
  Future<Either<Failure, DeliveryGroup>> startDelivery(
    String groupId, {
    String? notes,
  }) async {
    if (!await networkInfo.isConnected) {
      return const Left(NetworkFailure());
    }

    try {
      final group = await remoteDataSource.startDelivery(groupId, notes: notes);
      return Right(group);
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

  @override
  Future<Either<Failure, DeliveryGroup>> completeDeliveryGroup(
    String groupId,
  ) async {
    if (!await networkInfo.isConnected) {
      return const Left(NetworkFailure());
    }

    try {
      final group = await remoteDataSource.completeDeliveryGroup(groupId);
      return Right(group);
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

  @override
  Future<Either<Failure, DeliveryRoutePlan>> computeDeliveryRoutePlan(
    String groupId, {
    double? startLatitude,
    double? startLongitude,
    String metric = 'distance',
  }) async {
    if (!await networkInfo.isConnected) {
      return const Left(NetworkFailure());
    }

    try {
      final plan = await remoteDataSource.computeDeliveryRoutePlan(
        groupId,
        startLatitude: startLatitude,
        startLongitude: startLongitude,
        metric: metric,
      );
      return Right(plan);
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

  @override
  Future<Either<Failure, DeliveryOrder>> getOrderDetails(String orderId) async {
    if (!await networkInfo.isConnected) {
      return const Left(NetworkFailure());
    }

    try {
      final order = await remoteDataSource.getOrderDetails(orderId);
      return Right(order);
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

  @override
  Future<Either<Failure, String>> uploadDeliveryProofImage(
    String orderId,
    String localFilePath,
  ) async {
    if (!await networkInfo.isConnected) {
      return const Left(NetworkFailure());
    }

    try {
      final url = await remoteDataSource.uploadDeliveryProofImage(
        orderId,
        localFilePath,
      );
      return Right(url);
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

  @override
  Future<Either<Failure, DeliveryOrder>> confirmDelivery(
    String orderId, {
    required String proofImageUrl,
    required String verificationCode,
    String? notes,
  }) async {
    if (!await networkInfo.isConnected) {
      return const Left(NetworkFailure());
    }

    try {
      final order = await remoteDataSource.confirmDelivery(
        orderId,
        proofImageUrl: proofImageUrl,
        verificationCode: verificationCode,
        notes: notes,
      );
      return Right(order);
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

  @override
  Future<Either<Failure, DeliveryOrder>> reportDeliveryFailure(
    String orderId, {
    required String failureReason,
    String? notes,
  }) async {
    if (!await networkInfo.isConnected) {
      return const Left(NetworkFailure());
    }

    try {
      final order = await remoteDataSource.reportDeliveryFailure(
        orderId,
        failureReason: failureReason,
        notes: notes,
      );
      return Right(order);
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

  @override
  Future<Either<Failure, PaginatedDeliveryHistory>> getDeliveryHistory({
    int page = 1,
    int pageSize = 20,
    DateTime? fromDate,
    DateTime? toDate,
    String? status,
  }) async {
    if (!await networkInfo.isConnected) {
      return const Left(NetworkFailure());
    }

    try {
      final response = await remoteDataSource.getDeliveryHistory(
        page: page,
        pageSize: pageSize,
        fromDate: fromDate,
        toDate: toDate,
        status: status,
      );
      return Right(
        PaginatedDeliveryHistory(
          records: response.records,
          currentPage: response.currentPage,
          totalPages: response.totalPages,
          totalCount: response.totalCount,
          hasNextPage: response.hasNextPage,
        ),
      );
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

  @override
  Future<Either<Failure, DeliveryStats>> getDeliveryStats() async {
    if (!await networkInfo.isConnected) {
      return const Left(NetworkFailure());
    }

    try {
      final stats = await remoteDataSource.getDeliveryStats();
      return Right(stats);
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
