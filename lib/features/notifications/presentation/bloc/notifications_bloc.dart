import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../../domain/entities/notification_item.dart';
import '../../domain/usecases/get_my_notifications.dart';
import '../../domain/usecases/get_order_notifications.dart';
import '../../domain/usecases/mark_notification_read.dart';
import 'notifications_event.dart';
import 'notifications_state.dart';

class NotificationsBloc extends Bloc<NotificationsEvent, NotificationsState> {
  final GetMyNotificationsUseCase getMyNotificationsUseCase;
  final GetOrderNotificationsUseCase getOrderNotificationsUseCase;
  final MarkNotificationReadUseCase markNotificationReadUseCase;

  bool _isLoadingMyNotifications = false;

  NotificationsBloc({
    required this.getMyNotificationsUseCase,
    required this.getOrderNotificationsUseCase,
    required this.markNotificationReadUseCase,
  }) : super(const NotificationsInitial()) {
    on<LoadMyNotifications>(_onLoadMyNotifications);
    on<LoadOrderNotificationThread>(_onLoadOrderNotificationThread);
    on<ToggleUnreadFilter>(_onToggleUnreadFilter);
    on<MarkNotificationAsRead>(_onMarkNotificationAsRead);
  }

  void _emitFailure(Failure failure, Emitter<NotificationsState> emit) {
    if (failure is UnauthorizedFailure) {
      emit(const NotificationsSessionExpired());
      return;
    }

    emit(NotificationsError(message: failure.message));
  }

  Future<void> _onLoadMyNotifications(
    LoadMyNotifications event,
    Emitter<NotificationsState> emit,
  ) async {
    if (_isLoadingMyNotifications) {
      return;
    }

    _isLoadingMyNotifications = true;
    final previousState = state;

    if (previousState is! NotificationsListLoaded || event.forceRefresh) {
      emit(const NotificationsLoading(message: 'Đang tải thông báo...'));
    }

    try {
      final result = await getMyNotificationsUseCase(const NoParams());
      result.fold((failure) => _emitFailure(failure, emit), (items) {
        final unreadOnly = previousState is NotificationsListLoaded
            ? previousState.unreadOnly
            : false;
        emit(NotificationsListLoaded(allItems: items, unreadOnly: unreadOnly));
      });
    } finally {
      _isLoadingMyNotifications = false;
    }
  }

  Future<void> _onLoadOrderNotificationThread(
    LoadOrderNotificationThread event,
    Emitter<NotificationsState> emit,
  ) async {
    emit(const NotificationsLoading(message: 'Đang tải luồng thông báo...'));

    final result = await getOrderNotificationsUseCase(
      GetOrderNotificationsParams(orderId: event.orderId),
    );

    result.fold((failure) => _emitFailure(failure, emit), (items) {
      final sortedItems = List<NotificationItem>.from(items)
        ..sort((a, b) => a.createdAt.compareTo(b.createdAt));

      emit(
        NotificationsThreadLoaded(orderId: event.orderId, items: sortedItems),
      );
    });
  }

  void _onToggleUnreadFilter(
    ToggleUnreadFilter event,
    Emitter<NotificationsState> emit,
  ) {
    final currentState = state;
    if (currentState is NotificationsListLoaded) {
      emit(currentState.copyWith(unreadOnly: event.unreadOnly));
    }
  }

  Future<void> _onMarkNotificationAsRead(
    MarkNotificationAsRead event,
    Emitter<NotificationsState> emit,
  ) async {
    final currentState = state;

    if (currentState is NotificationsListLoaded) {
      final index = currentState.allItems.indexWhere(
        (element) => element.notificationId == event.notificationId,
      );

      if (index < 0 || currentState.allItems[index].isRead) {
        return;
      }

      final optimisticItems = List<NotificationItem>.from(
        currentState.allItems,
      );
      optimisticItems[index] = optimisticItems[index].copyWith(isRead: true);
      emit(currentState.copyWith(allItems: optimisticItems));

      final result = await markNotificationReadUseCase(
        MarkNotificationReadParams(notificationId: event.notificationId),
      );

      result.fold((failure) => _emitFailure(failure, emit), (updatedItem) {
        final latestState = state;
        if (latestState is NotificationsListLoaded) {
          final syncedItems = latestState.allItems.map((element) {
            if (element.notificationId == updatedItem.notificationId) {
              return updatedItem;
            }
            return element;
          }).toList();
          emit(latestState.copyWith(allItems: syncedItems));
        }
      });
      return;
    }

    if (currentState is NotificationsThreadLoaded) {
      final index = currentState.items.indexWhere(
        (element) => element.notificationId == event.notificationId,
      );

      if (index < 0 || currentState.items[index].isRead) {
        return;
      }

      final optimisticItems = List<NotificationItem>.from(currentState.items);
      optimisticItems[index] = optimisticItems[index].copyWith(isRead: true);

      emit(
        NotificationsThreadLoaded(
          orderId: currentState.orderId,
          items: optimisticItems,
        ),
      );

      final result = await markNotificationReadUseCase(
        MarkNotificationReadParams(notificationId: event.notificationId),
      );

      result.fold((failure) => _emitFailure(failure, emit), (updatedItem) {
        final latestState = state;
        if (latestState is NotificationsThreadLoaded) {
          final syncedItems = latestState.items.map((element) {
            if (element.notificationId == updatedItem.notificationId) {
              return updatedItem;
            }
            return element;
          }).toList();

          emit(
            NotificationsThreadLoaded(
              orderId: latestState.orderId,
              items: syncedItems,
            ),
          );
        }
      });
    }
  }
}
