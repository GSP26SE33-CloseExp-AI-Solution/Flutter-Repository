# Kiến Trúc Ứng Dụng Mobile CloseExp

> Tài liệu dành cho các developer trong team để hiểu cấu trúc và cách phát triển ứng dụng.

---

## Tổng Quan

Ứng dụng được xây dựng theo **Clean Architecture** kết hợp **BLoC Pattern** để quản lý state.

```
┌────────────────────────────────────────────────────────┐
│                    PRESENTATION                         │
│              (UI, BLoC, Widgets)                        │
├────────────────────────────────────────────────────────┤
│                      DOMAIN                             │
│         (Entities, UseCases, Repository Interface)      │
├────────────────────────────────────────────────────────┤
│                       DATA                              │
│      (Models, DataSources, Repository Implementation)   │
└────────────────────────────────────────────────────────┘
```

**Nguyên tắc:** Layer trong chỉ phụ thuộc layer ngoài. Domain không phụ thuộc bất kỳ layer nào.

---

## Cấu Trúc Thư Mục

```
lib/
├── core/                           # Shared components
│   ├── constants/
│   │   ├── api_constants.dart      # Base URL, endpoints
│   │   └── app_constants.dart      # Storage keys, app info
│   ├── error/
│   │   ├── exceptions.dart         # Exception classes
│   │   └── failures.dart           # Failure classes
│   ├── network/
│   │   ├── dio_client.dart         # HTTP client + interceptors
│   │   └── network_info.dart       # Network connectivity
│   ├── router/
│   │   └── app_router.dart         # GoRouter configuration
│   └── usecases/
│       └── usecase.dart            # Base UseCase class
│
├── features/                       # Feature modules
│   ├── auth/
│   │   ├── data/
│   │   │   ├── datasources/
│   │   │   │   ├── auth_local_datasource.dart
│   │   │   │   └── auth_remote_datasource.dart
│   │   │   ├── models/
│   │   │   │   ├── api_response_model.dart
│   │   │   │   ├── auth_response_model.dart
│   │   │   │   └── user_model.dart
│   │   │   └── repositories/
│   │   │       └── auth_repository_impl.dart
│   │   ├── domain/
│   │   │   ├── entities/
│   │   │   │   ├── auth_result.dart
│   │   │   │   └── user.dart
│   │   │   ├── repositories/
│   │   │   │   └── auth_repository.dart
│   │   │   └── usecases/
│   │   │       ├── check_auth_status_usecase.dart
│   │   │       ├── get_cached_user_usecase.dart
│   │   │       ├── login_usecase.dart
│   │   │       └── logout_usecase.dart
│   │   └── presentation/
│   │       ├── bloc/
│   │       │   ├── auth_bloc.dart
│   │       │   ├── auth_event.dart
│   │       │   └── auth_state.dart
│   │       └── pages/
│   │           ├── login_page.dart
│   │           └── splash_page.dart
│   │
│   └── home/
│       └── presentation/
│           └── pages/
│               └── home_page.dart
│
├── injection_container.dart        # Dependency Injection setup
└── main.dart                       # Entry point
```

---

## Luồng Dữ Liệu

### Login Flow

```
User nhập email/password
        │
        ▼
┌─────────────────┐
│   LoginPage     │  ── gửi LoginEvent ──▶  AuthBloc
└─────────────────┘                              │
                                                 ▼
                                        ┌─────────────────┐
                                        │  LoginUseCase   │
                                        └────────┬────────┘
                                                 │
                                                 ▼
                                        ┌─────────────────┐
                                        │ AuthRepository  │ (interface)
                                        └────────┬────────┘
                                                 │
                                                 ▼
                                        ┌─────────────────┐
                                        │ AuthRepoImpl    │
                                        └────────┬────────┘
                                                 │
                          ┌──────────────────────┴──────────────────────┐
                          ▼                                             ▼
                ┌─────────────────┐                           ┌─────────────────┐
                │ RemoteDataSource│ ── call API ──▶           │ LocalDataSource │
                └─────────────────┘                           │ (cache token)   │
                          │                                   └─────────────────┘
                          ▼
                    BE-CloseExp
                   /api/auth/login
```

---

## Các Layer Chi Tiết

### 1. Domain Layer (Business Logic)

**Không phụ thuộc** bất kỳ framework hay package nào.

| Thành phần | Mô tả |
|------------|-------|
| **Entities** | Object thuần túy, đại diện dữ liệu business |
| **Repositories** | Interface định nghĩa contract |
| **UseCases** | Chứa một business logic duy nhất |

```dart
// UseCase pattern
abstract class UseCase<Type, Params> {
  Future<Either<Failure, Type>> call(Params params);
}

// Ví dụ
class LoginUseCase implements UseCase<AuthResult, LoginParams> {
  final AuthRepository repository;
  
  Future<Either<Failure, AuthResult>> call(LoginParams params) {
    return repository.login(params.email, params.password);
  }
}
```

### 2. Data Layer (Implementation)

Triển khai các interface từ Domain layer.

| Thành phần | Mô tả |
|------------|-------|
| **Models** | Extends Entity, có `fromJson`/`toJson` |
| **DataSources** | Remote (API), Local (Cache) |
| **Repository Impl** | Xử lý logic chọn nguồn dữ liệu |

```dart
// Model extends Entity
class UserModel extends User {
  factory UserModel.fromJson(Map<String, dynamic> json) => UserModel(
    userId: json['userId'],
    fullName: json['fullName'],
    roleName: json['roleName'],
  );
}
```

### 3. Presentation Layer (UI)

Sử dụng BLoC pattern để quản lý state.

| Thành phần | Mô tả |
|------------|-------|
| **Events** | Input từ UI (button click, form submit) |
| **States** | Trạng thái UI (loading, success, error) |
| **BLoC** | Xử lý Event → State |
| **Pages/Widgets** | UI components |

```dart
// BLoC nhận Event, emit State
class AuthBloc extends Bloc<AuthEvent, AuthState> {
  on<LoginEvent>((event, emit) async {
    emit(AuthLoading());
    final result = await loginUseCase(params);
    result.fold(
      (failure) => emit(AuthError(failure.message)),
      (authResult) => emit(Authenticated(authResult.user)),
    );
  });
}
```

---

## Dependency Injection

Sử dụng **GetIt** làm Service Locator.

```dart
// injection_container.dart
final sl = GetIt.instance;

Future<void> init() async {
  // BLoC
  sl.registerFactory(() => AuthBloc(
    loginUseCase: sl(),
    logoutUseCase: sl(),
  ));
  
  // UseCases
  sl.registerLazySingleton(() => LoginUseCase(sl()));
  
  // Repository
  sl.registerLazySingleton<AuthRepository>(
    () => AuthRepositoryImpl(remote: sl(), local: sl()),
  );
  
  // DataSources
  sl.registerLazySingleton<AuthRemoteDataSource>(
    () => AuthRemoteDataSourceImpl(client: sl()),
  );
}
```

**Thứ tự đăng ký:** External → DataSources → Repositories → UseCases → BLoCs

---

## Error Handling

### Exception vs Failure

| Loại | Sử dụng ở | Mục đích |
|------|-----------|----------|
| **Exception** | Data Layer | Throw khi có lỗi cụ thể |
| **Failure** | Domain/Presentation | Trả về qua Either |

```dart
// Data layer throw Exception
if (response.statusCode != 200) {
  throw ServerException(message: 'Login failed');
}

// Repository catch và return Failure
try {
  final result = await remoteDataSource.login(email, password);
  return Right(result);
} on ServerException catch (e) {
  return Left(ServerFailure(e.message));
}
```

### Either Pattern

Sử dụng `dartz` package cho Functional Error Handling.

```dart
// Thay vì throw exception
Future<Either<Failure, User>> login(String email, String password);

// Xử lý kết quả
result.fold(
  (failure) => showError(failure.message),
  (user) => navigateToHome(user),
);
```

---

## Routing

Sử dụng **GoRouter** với redirect logic cho authentication.

```dart
GoRouter(
  redirect: (context, state) {
    final isLoggedIn = authBloc.state is Authenticated;
    final isOnLogin = state.matchedLocation == '/login';
    
    if (!isLoggedIn && !isOnLogin) return '/login';
    if (isLoggedIn && isOnLogin) return '/home';
    return null;
  },
  routes: [
    GoRoute(path: '/', builder: (_, __) => SplashPage()),
    GoRoute(path: '/login', builder: (_, __) => LoginPage()),
    GoRoute(path: '/home', builder: (_, __) => HomePage()),
  ],
);
```

---

## Thêm Feature Mới

### Bước 1: Domain Layer

```
lib/features/orders/domain/
├── entities/
│   └── order.dart
├── repositories/
│   └── order_repository.dart
└── usecases/
    ├── get_orders_usecase.dart
    └── update_order_status_usecase.dart
```

### Bước 2: Data Layer

```
lib/features/orders/data/
├── models/
│   └── order_model.dart
├── datasources/
│   └── order_remote_datasource.dart
└── repositories/
    └── order_repository_impl.dart
```

### Bước 3: Presentation Layer

```
lib/features/orders/presentation/
├── bloc/
│   ├── order_bloc.dart
│   ├── order_event.dart
│   └── order_state.dart
└── pages/
    ├── order_list_page.dart
    └── order_detail_page.dart
```

### Bước 4: Đăng ký DI

```dart
// injection_container.dart
sl.registerFactory(() => OrderBloc(getOrders: sl(), updateStatus: sl()));
sl.registerLazySingleton(() => GetOrdersUseCase(sl()));
sl.registerLazySingleton<OrderRepository>(() => OrderRepositoryImpl(sl()));
```

### Bước 5: Thêm Route

```dart
// app_router.dart
GoRoute(
  path: '/orders',
  builder: (_, __) => BlocProvider(
    create: (_) => sl<OrderBloc>(),
    child: OrderListPage(),
  ),
),
```

---

## Packages Chính

| Package | Version | Mục đích |
|---------|---------|----------|
| `flutter_bloc` | ^8.1.6 | State management |
| `get_it` | ^8.0.3 | Dependency injection |
| `dio` | ^5.7.0 | HTTP client |
| `dartz` | ^0.10.1 | Functional programming |
| `go_router` | ^14.6.2 | Navigation |
| `flutter_secure_storage` | ^9.2.2 | Secure token storage |
| `equatable` | ^2.0.5 | Value equality |

---

## Quy Tắc Code

### Naming Convention

| Loại | Convention | Ví dụ |
|------|------------|-------|
| File | snake_case | `auth_bloc.dart` |
| Class | PascalCase | `AuthBloc` |
| Variable | camelCase | `isLoggedIn` |
| Constant | camelCase | `baseUrl` |

### File Organization

- Mỗi class một file
- Export qua barrel file nếu cần
- Feature folder chứa đầy đủ 3 layer

### BLoC Rules

- Một BLoC cho một feature
- State phải immutable (dùng Equatable)
- Không gọi trực tiếp repository trong BLoC, qua UseCase

---

## Testing

```
test/
├── features/
│   └── auth/
│       ├── data/
│       │   └── repositories/
│       │       └── auth_repository_impl_test.dart
│       ├── domain/
│       │   └── usecases/
│       │       └── login_usecase_test.dart
│       └── presentation/
│           └── bloc/
│               └── auth_bloc_test.dart
└── core/
    └── network/
        └── dio_client_test.dart
```

**Test theo layer:**
- **Domain:** Test UseCase với mock Repository
- **Data:** Test Repository với mock DataSource
- **Presentation:** Test BLoC với mock UseCase

---

## Tài Liệu Tham Khảo

- [Flutter BLoC Documentation](https://bloclibrary.dev/)
- [Clean Architecture by Uncle Bob](https://blog.cleancoder.com/uncle-bob/2012/08/13/the-clean-architecture.html)
- [ResoCoder Clean Architecture](https://resocoder.com/flutter-clean-architecture-tdd/)
- [GetIt Package](https://pub.dev/packages/get_it)
- [GoRouter Documentation](https://pub.dev/packages/go_router)

---

## Liên Hệ

Nếu có thắc mắc về kiến trúc, liên hệ Mobile Dev Lead hoặc tạo issue trên repository.
