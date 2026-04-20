import 'package:equatable/equatable.dart';

import '../../domain/entities/notification_item.dart';

abstract class NotificationsState extends Equatable {
  const NotificationsState();

  @override
  List<Object?> get props => [];
}

class NotificationsInitial extends NotificationsState {
  const NotificationsInitial();
}

class NotificationsLoading extends NotificationsState {
  final String? message;

  const NotificationsLoading({this.message});

  @override
  List<Object?> get props => [message];
}

class NotificationsError extends NotificationsState {
  final String message;

  const NotificationsError({required this.message});

  @override
  List<Object?> get props => [message];
}

class NotificationsSessionExpired extends NotificationsState {
  const NotificationsSessionExpired();
}

class NotificationsListLoaded extends NotificationsState {
  final List<NotificationItem> allItems;
  final bool unreadOnly;

  const NotificationsListLoaded({
    required this.allItems,
    this.unreadOnly = false,
  });

  int get unreadCount => allItems.where((element) => !element.isRead).length;

  List<NotificationItem> get visibleItems {
    final source = unreadOnly
        ? allItems.where((element) => !element.isRead).toList()
        : List<NotificationItem>.from(allItems);

    source.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return source;
  }

  bool get isEmpty => visibleItems.isEmpty;

  NotificationsListLoaded copyWith({
    List<NotificationItem>? allItems,
    bool? unreadOnly,
  }) {
    return NotificationsListLoaded(
      allItems: allItems ?? this.allItems,
      unreadOnly: unreadOnly ?? this.unreadOnly,
    );
  }

  @override
  List<Object?> get props => [allItems, unreadOnly];
}

class NotificationsThreadLoaded extends NotificationsState {
  final String orderId;
  final List<NotificationItem> items;

  const NotificationsThreadLoaded({required this.orderId, required this.items});

  int get unreadCount => items.where((element) => !element.isRead).length;

  @override
  List<Object?> get props => [orderId, items];
}
