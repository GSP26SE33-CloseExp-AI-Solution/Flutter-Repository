import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../entities/notification_item.dart';

abstract class NotificationRepository {
  Future<Either<Failure, List<NotificationItem>>> getMyNotifications();

  Future<Either<Failure, List<NotificationItem>>> getOrderNotifications(
    String orderId,
  );

  Future<Either<Failure, NotificationItem>> markAsRead(String notificationId);
}
