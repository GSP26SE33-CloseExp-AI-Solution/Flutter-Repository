import '../../features/notifications/domain/entities/notification_item.dart';
import 'local_notification_service.dart';

/// Shows system alerts for new unread rows after API poll / refresh.
class NotificationIncomingTracker {
  NotificationIncomingTracker(this._localNotificationService);

  final LocalNotificationService _localNotificationService;
  final Set<String> _knownIds = {};
  bool _seeded = false;

  void reset() {
    _knownIds.clear();
    _seeded = false;
  }

  Future<void> onListLoaded(List<NotificationItem> items) async {
    final currentIds = items.map((e) => e.notificationId).toSet();

    if (!_seeded) {
      _knownIds
        ..clear()
        ..addAll(currentIds);
      _seeded = true;
      return;
    }

    for (final item in items) {
      if (item.isRead || _knownIds.contains(item.notificationId)) {
        continue;
      }

      _knownIds.add(item.notificationId);
      await _localNotificationService.showFromRealtime(
        notificationId: item.notificationId,
        title: item.title,
        body: item.content,
      );
    }

    _knownIds.addAll(currentIds);
  }
}
