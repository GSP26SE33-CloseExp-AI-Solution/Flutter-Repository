import 'package:dartz/dartz.dart';
import '../../../../core/error/exceptions.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/network/network_info.dart';
import '../../domain/entities/auth_result.dart';
import '../../domain/entities/user.dart';
import '../../domain/entities/user_image.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/auth_local_datasource.dart';
import '../datasources/auth_remote_datasource.dart';
import '../models/auth_response_model.dart';
import '../models/user_model.dart';

/// Auth Repository Implementation - Data Layer
///
/// Implements the AuthRepository interface from domain layer.
/// Coordinates between remote and local data sources.
class AuthRepositoryImpl implements AuthRepository {
  final AuthRemoteDataSource _remoteDataSource;
  final AuthLocalDataSource _localDataSource;
  final NetworkInfo _networkInfo;

  AuthRepositoryImpl({
    required AuthRemoteDataSource remoteDataSource,
    required AuthLocalDataSource localDataSource,
    required NetworkInfo networkInfo,
  }) : _remoteDataSource = remoteDataSource,
       _localDataSource = localDataSource,
       _networkInfo = networkInfo;

  @override
  Future<Either<Failure, AuthResult>> login({
    required String email,
    required String password,
  }) async {
    if (!await _networkInfo.isConnected) {
      return const Left(NetworkFailure());
    }

    try {
      final authResponse = await _remoteDataSource.login(
        email: email,
        password: password,
      );

      await _cacheAuthResponse(authResponse);
      return Right(authResponse);
    } on AuthenticationException catch (e) {
      return Left(
        AuthenticationFailure(message: e.message, statusCode: e.statusCode),
      );
    } on NetworkException catch (e) {
      return Left(NetworkFailure(message: e.message));
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message, statusCode: e.statusCode));
    } catch (e) {
      return Left(UnknownFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, AuthResult>> refreshToken() async {
    if (!await _networkInfo.isConnected) {
      return const Left(NetworkFailure());
    }

    try {
      final currentRefreshToken = await _localDataSource.getRefreshToken();
      if (currentRefreshToken == null) {
        return const Left(
          AuthenticationFailure(message: 'Không tìm thấy refresh token'),
        );
      }

      final authResponse = await _remoteDataSource.refreshToken(
        refreshToken: currentRefreshToken,
      );

      await _cacheAuthResponse(authResponse);
      return Right(authResponse);
    } on AuthenticationException catch (e) {
      // Token invalid/expired - clear local data
      await _localDataSource.clearAuthData();
      return Left(
        AuthenticationFailure(message: e.message, statusCode: e.statusCode),
      );
    } on NetworkException catch (e) {
      return Left(NetworkFailure(message: e.message));
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message, statusCode: e.statusCode));
    } catch (e) {
      return Left(UnknownFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> logout() async {
    try {
      await _localDataSource.clearAuthData();
      return const Right(null);
    } on CacheException catch (e) {
      return Left(CacheFailure(message: e.message));
    } catch (e) {
      return Left(UnknownFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> logoutWithToken() async {
    try {
      final refreshToken = await _localDataSource.getRefreshToken();

      if (refreshToken != null && await _networkInfo.isConnected) {
        try {
          await _remoteDataSource.logout(refreshToken: refreshToken);
        } catch (_) {
          // Ignore remote logout errors, still clear local data
        }
      }

      await _localDataSource.clearAuthData();
      return const Right(null);
    } on CacheException catch (e) {
      return Left(CacheFailure(message: e.message));
    } catch (e) {
      return Left(UnknownFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> logoutAll() async {
    if (!await _networkInfo.isConnected) {
      return const Left(NetworkFailure());
    }

    try {
      final accessToken = await _localDataSource.getAccessToken();
      if (accessToken == null) {
        return const Left(
          AuthenticationFailure(message: 'Không tìm thấy access token'),
        );
      }

      await _remoteDataSource.logoutAll(accessToken: accessToken);
      await _localDataSource.clearAuthData();
      return const Right(null);
    } on AuthenticationException catch (e) {
      return Left(
        AuthenticationFailure(message: e.message, statusCode: e.statusCode),
      );
    } on NetworkException catch (e) {
      return Left(NetworkFailure(message: e.message));
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message, statusCode: e.statusCode));
    } on CacheException catch (e) {
      return Left(CacheFailure(message: e.message));
    } catch (e) {
      return Left(UnknownFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, User>> getCachedUser() async {
    try {
      final user = await _localDataSource.getCachedUser();
      if (user == null) {
        return const Left(
          CacheFailure(message: 'Không tìm thấy thông tin người dùng'),
        );
      }
      return Right(user);
    } on CacheException catch (e) {
      return Left(CacheFailure(message: e.message));
    } catch (e) {
      return Left(UnknownFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, bool>> isLoggedIn() async {
    try {
      final isLoggedIn = await _localDataSource.isLoggedIn();
      return Right(isLoggedIn);
    } on CacheException catch (e) {
      return Left(CacheFailure(message: e.message));
    } catch (e) {
      return Left(UnknownFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, String>> getAccessToken() async {
    try {
      final token = await _localDataSource.getAccessToken();
      if (token == null) {
        return const Left(CacheFailure(message: 'Không tìm thấy token'));
      }
      return Right(token);
    } on CacheException catch (e) {
      return Left(CacheFailure(message: e.message));
    } catch (e) {
      return Left(UnknownFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, String>> getRefreshToken() async {
    try {
      final token = await _localDataSource.getRefreshToken();
      if (token == null) {
        return const Left(
          CacheFailure(message: 'Không tìm thấy refresh token'),
        );
      }
      return Right(token);
    } on CacheException catch (e) {
      return Left(CacheFailure(message: e.message));
    } catch (e) {
      return Left(UnknownFailure(message: e.toString()));
    }
  }

  // ============== USER PROFILE ==============

  @override
  Future<Either<Failure, User>> getCurrentUser() async {
    if (!await _networkInfo.isConnected) {
      return const Left(NetworkFailure());
    }

    try {
      final user = await _remoteDataSource.getCurrentUser();
      // Update local cache with fresh data
      final cachedUser = await _localDataSource.getCachedUser();
      if (cachedUser != null) {
        final accessToken = await _localDataSource.getAccessToken();
        final refreshToken = await _localDataSource.getRefreshToken();
        final tokenExpiry = await _localDataSource.getTokenExpiry();
        if (accessToken != null &&
            refreshToken != null &&
            tokenExpiry != null) {
          await _localDataSource.cacheAuthData(
            accessToken: accessToken,
            refreshToken: refreshToken,
            expiresAt: tokenExpiry,
            user: user,
          );
        }
      }
      return Right(user);
    } on AuthenticationException catch (e) {
      return Left(
        AuthenticationFailure(message: e.message, statusCode: e.statusCode),
      );
    } on NetworkException catch (e) {
      return Left(NetworkFailure(message: e.message));
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message, statusCode: e.statusCode));
    } catch (e) {
      return Left(UnknownFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, User>> updateProfile({
    String? fullName,
    String? phone,
  }) async {
    if (!await _networkInfo.isConnected) {
      return const Left(NetworkFailure());
    }

    try {
      final user = await _remoteDataSource.updateProfile(
        fullName: fullName,
        phone: phone,
      );
      // Update local cache with fresh data
      final accessToken = await _localDataSource.getAccessToken();
      final refreshToken = await _localDataSource.getRefreshToken();
      final tokenExpiry = await _localDataSource.getTokenExpiry();
      if (accessToken != null && refreshToken != null && tokenExpiry != null) {
        await _localDataSource.cacheAuthData(
          accessToken: accessToken,
          refreshToken: refreshToken,
          expiresAt: tokenExpiry,
          user: user,
        );
      }
      return Right(user);
    } on AuthenticationException catch (e) {
      return Left(
        AuthenticationFailure(message: e.message, statusCode: e.statusCode),
      );
    } on NetworkException catch (e) {
      return Left(NetworkFailure(message: e.message));
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message, statusCode: e.statusCode));
    } catch (e) {
      return Left(UnknownFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, UserImage?>> getPrimaryImage() async {
    if (!await _networkInfo.isConnected) {
      return const Left(NetworkFailure());
    }

    try {
      final image = await _remoteDataSource.getPrimaryImage();
      return Right(image);
    } on AuthenticationException catch (e) {
      return Left(
        AuthenticationFailure(message: e.message, statusCode: e.statusCode),
      );
    } on NetworkException catch (e) {
      return Left(NetworkFailure(message: e.message));
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message, statusCode: e.statusCode));
    } catch (e) {
      return Left(UnknownFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, UserImage>> uploadCurrentUserImage({
    required String filePath,
    String imageType = 'avatar',
    bool setAsPrimary = true,
  }) async {
    if (!await _networkInfo.isConnected) {
      return const Left(NetworkFailure());
    }

    try {
      final image = await _remoteDataSource.uploadCurrentUserImage(
        filePath: filePath,
        imageType: imageType,
        setAsPrimary: setAsPrimary,
      );
      return Right(image);
    } on AuthenticationException catch (e) {
      return Left(
        AuthenticationFailure(message: e.message, statusCode: e.statusCode),
      );
    } on NetworkException catch (e) {
      return Left(NetworkFailure(message: e.message));
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message, statusCode: e.statusCode));
    } catch (e) {
      return Left(UnknownFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> deleteCurrentUserImage(String imageId) async {
    if (!await _networkInfo.isConnected) {
      return const Left(NetworkFailure());
    }

    try {
      await _remoteDataSource.deleteCurrentUserImage(imageId);
      return const Right(null);
    } on AuthenticationException catch (e) {
      return Left(
        AuthenticationFailure(message: e.message, statusCode: e.statusCode),
      );
    } on NetworkException catch (e) {
      return Left(NetworkFailure(message: e.message));
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message, statusCode: e.statusCode));
    } catch (e) {
      return Left(UnknownFailure(message: e.toString()));
    }
  }

  // ============== Private Helpers ==============

  Future<void> _cacheAuthResponse(AuthResponseModel authResponse) async {
    await _localDataSource.cacheAuthData(
      accessToken: authResponse.accessToken,
      refreshToken: authResponse.refreshToken,
      expiresAt: authResponse.expiresAt,
      user: authResponse.user as UserModel,
    );
  }
}
