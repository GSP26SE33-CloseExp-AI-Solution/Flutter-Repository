import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import '../error/failures.dart';

/// Base UseCase dùng `Either<Failure, T>` theo Clean Architecture.
abstract class UseCase<T, Params> {
  Future<Either<Failure, T>> call(Params params);
}

/// NoParams cho use case không cần tham số.
class NoParams extends Equatable {
  const NoParams();

  @override
  List<Object?> get props => [];
}
