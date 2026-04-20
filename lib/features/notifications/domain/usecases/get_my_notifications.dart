import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/notification_item.dart';
import '../repositories/notification_repository.dart';

class GetMyNotificationsUseCase
    extends UseCase<List<NotificationItem>, NoParams> {
  final NotificationRepository repository;

  GetMyNotificationsUseCase(this.repository);

  @override
  Future<Either<Failure, List<NotificationItem>>> call(NoParams params) {
    return repository.getMyNotifications();
  }
}
