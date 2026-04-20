import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/notification_item.dart';
import '../repositories/notification_repository.dart';

class MarkNotificationReadUseCase
    extends UseCase<NotificationItem, MarkNotificationReadParams> {
  final NotificationRepository repository;

  MarkNotificationReadUseCase(this.repository);

  @override
  Future<Either<Failure, NotificationItem>> call(
    MarkNotificationReadParams params,
  ) {
    return repository.markAsRead(params.notificationId);
  }
}

class MarkNotificationReadParams extends Equatable {
  final String notificationId;

  const MarkNotificationReadParams({required this.notificationId});

  @override
  List<Object?> get props => [notificationId];
}
