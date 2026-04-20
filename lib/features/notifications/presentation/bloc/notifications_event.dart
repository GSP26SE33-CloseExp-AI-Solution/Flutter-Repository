import 'package:equatable/equatable.dart';

abstract class NotificationsEvent extends Equatable {
  const NotificationsEvent();

  @override
  List<Object?> get props => [];
}

class LoadMyNotifications extends NotificationsEvent {
  final bool forceRefresh;

  const LoadMyNotifications({this.forceRefresh = false});

  @override
  List<Object?> get props => [forceRefresh];
}

class LoadOrderNotificationThread extends NotificationsEvent {
  final String orderId;

  const LoadOrderNotificationThread({required this.orderId});

  @override
  List<Object?> get props => [orderId];
}

class ToggleUnreadFilter extends NotificationsEvent {
  final bool unreadOnly;

  const ToggleUnreadFilter({required this.unreadOnly});

  @override
  List<Object?> get props => [unreadOnly];
}

class MarkNotificationAsRead extends NotificationsEvent {
  final String notificationId;

  const MarkNotificationAsRead({required this.notificationId});

  @override
  List<Object?> get props => [notificationId];
}
