import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/auth_result.dart';
import '../repositories/auth_repository.dart';

/// Đăng nhập; chỉ cho phép role DeliveryStaff.
class LoginUseCase implements UseCase<AuthResult, LoginParams> {
  final AuthRepository repository;

  LoginUseCase(this.repository);

  @override
  Future<Either<Failure, AuthResult>> call(LoginParams params) async {
    final result = await repository.login(
      email: params.email,
      password: params.password,
    );

    return await result.fold((failure) async => Left(failure), (
      authResult,
    ) async {
      // Check if user is a delivery staff
      if (!authResult.user.isDeliveryStaff) {
        await repository.logout();
        return const Left(
          ForbiddenFailure(
            message:
                'Ứng dụng này chỉ dành cho nhân viên giao hàng. '
                'Vui lòng sử dụng ứng dụng phù hợp với vai trò của bạn.',
          ),
        );
      }

      // Check if user account is active
      if (!authResult.user.isActive) {
        await repository.logout();
        return const Left(
          AuthenticationFailure(
            message:
                'Tài khoản của bạn đã bị vô hiệu hóa. '
                'Vui lòng liên hệ quản trị viên.',
          ),
        );
      }

      return Right(authResult);
    });
  }
}

/// Login Parameters
class LoginParams extends Equatable {
  final String email;
  final String password;

  const LoginParams({required this.email, required this.password});

  @override
  List<Object?> get props => [email, password];
}
