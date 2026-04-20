import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/notification_item.dart';
import '../repositories/notification_repository.dart';

class GetOrderNotificationsUseCase
    extends UseCase<List<NotificationItem>, GetOrderNotificationsParams> {
  final NotificationRepository repository;

  GetOrderNotificationsUseCase(this.repository);

  @override
  Future<Either<Failure, List<NotificationItem>>> call(
    GetOrderNotificationsParams params,
  ) {
    return repository.getOrderNotifications(params.orderId);
  }
}

class GetOrderNotificationsParams extends Equatable {
  final String orderId;

  const GetOrderNotificationsParams({required this.orderId});

  @override
  List<Object?> get props => [orderId];
}
