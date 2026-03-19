import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:get_it/get_it.dart';
import '../core/network/dio_client.dart';
import '../core/network/network_info.dart';
import '../features/auth/data/datasources/auth_local_datasource.dart';
import '../features/auth/data/datasources/auth_remote_datasource.dart';
import '../features/auth/data/repositories/auth_repository_impl.dart';
import '../features/auth/domain/repositories/auth_repository.dart';
import '../features/auth/domain/usecases/check_auth_status_usecase.dart';
import '../features/auth/domain/usecases/get_cached_user_usecase.dart';
import '../features/auth/domain/usecases/login_usecase.dart';
import '../features/auth/domain/usecases/logout_usecase.dart';
import '../features/auth/presentation/bloc/auth_bloc.dart';
import '../features/delivery/data/datasources/delivery_remote_datasource.dart';
import '../features/delivery/data/datasources/upload_datasource.dart';
import '../features/delivery/data/repositories/delivery_repository_impl.dart';
import '../features/delivery/data/repositories/upload_repository_impl.dart';
import '../features/delivery/domain/repositories/delivery_repository.dart';
import '../features/delivery/domain/repositories/upload_repository.dart';
import '../features/delivery/domain/usecases/upload_proof_image_usecase.dart';
import '../features/delivery/presentation/bloc/delivery_bloc.dart';

// Service Locator using GetIt
//
// This is the dependency injection container for the entire app.
// All dependencies are registered here and can be accessed via sl Type.
final sl = GetIt.instance;

/// Initialize all dependencies
Future<void> initializeDependencies() async {
  // ============== CORE ==============

  // Secure Storage
  sl.registerLazySingleton<FlutterSecureStorage>(
    () => const FlutterSecureStorage(
      aOptions: AndroidOptions(encryptedSharedPreferences: true),
      iOptions: IOSOptions(
        accessibility: KeychainAccessibility.first_unlock_this_device,
      ),
    ),
  );

  // Network Info
  sl.registerLazySingleton<NetworkInfo>(() => NetworkInfoImpl());

  // Dio Client
  sl.registerLazySingleton<DioClient>(() => DioClient(secureStorage: sl()));

  // ============== AUTH FEATURE ==============

  // Data Sources
  sl.registerLazySingleton<AuthRemoteDataSource>(
    () => AuthRemoteDataSourceImpl(dio: sl<DioClient>().dio),
  );

  sl.registerLazySingleton<AuthLocalDataSource>(
    () => AuthLocalDataSourceImpl(secureStorage: sl()),
  );

  // Repository
  sl.registerLazySingleton<AuthRepository>(
    () => AuthRepositoryImpl(
      remoteDataSource: sl(),
      localDataSource: sl(),
      networkInfo: sl(),
    ),
  );

  // Use Cases
  sl.registerLazySingleton(() => LoginUseCase(sl()));
  sl.registerLazySingleton(() => LogoutUseCase(sl()));
  sl.registerLazySingleton(() => CheckAuthStatusUseCase(sl()));
  sl.registerLazySingleton(() => GetCachedUserUseCase(sl()));

  // BLoC - Factory (new instance each time)
  sl.registerFactory<AuthBloc>(
    () => AuthBloc(
      loginUseCase: sl(),
      logoutUseCase: sl(),
      checkAuthStatusUseCase: sl(),
      getCachedUserUseCase: sl(),
    ),
  );

  // ============== DELIVERY FEATURE ==============

  // Data Sources
  sl.registerLazySingleton<DeliveryRemoteDataSource>(
    () => DeliveryRemoteDataSourceImpl(dio: sl<DioClient>().dio),
  );

  sl.registerLazySingleton<UploadDataSource>(
    () => UploadDataSourceImpl(dio: sl<DioClient>().dio),
  );

  // Repository
  sl.registerLazySingleton<DeliveryRepository>(
    () => DeliveryRepositoryImpl(remoteDataSource: sl(), networkInfo: sl()),
  );

  sl.registerLazySingleton<UploadRepository>(
    () => UploadRepositoryImpl(dataSource: sl(), networkInfo: sl()),
  );

  // Use Cases
  sl.registerLazySingleton(() => UploadProofImageUseCase(sl()));

  // BLoC - Factory (new instance each time)
  sl.registerFactory<DeliveryBloc>(() => DeliveryBloc(repository: sl()));
}
