import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import '../error/failures.dart';

/// Base UseCase class following Clean Architecture principles
///
/// Every UseCase should extend this class and implement the call method.
/// This ensures consistent error handling using Either Failure, T.
///
/// T - The return type of the use case
/// Params - The parameters required by the use case
abstract class UseCase<T, Params> {
  Future<Either<Failure, T>> call(Params params);
}

/// NoParams class for use cases that don't require any parameters
class NoParams extends Equatable {
  const NoParams();

  @override
  List<Object?> get props => [];
}
