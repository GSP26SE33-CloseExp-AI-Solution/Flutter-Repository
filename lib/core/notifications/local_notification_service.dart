import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

/// Shows system banners when SignalR or poll detects a new notification.
class LocalNotificationService {
  static const _androidChannelId = 'closeexp_delivery_updates';
  static const _androidChannelName = 'Thông báo giao hàng';
  static const _androidChannelDescription =
      'Cập nhật đơn hàng và trạng thái giao hàng';

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  void Function(String? notificationId)? onNotificationTap;

  Future<void> initialize() async {
    if (kIsWeb) {
      return;
    }

    const androidInit = AndroidInitializationSettings('@mipmap/launcher_icon');
    const iosInit = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    await _plugin.initialize(
      settings: const InitializationSettings(android: androidInit, iOS: iosInit),
      onDidReceiveNotificationResponse: (response) {
        onNotificationTap?.call(response.payload);
      },
    );

    await _createAndroidChannel();
    await _requestPermissions();
  }

  Future<void> ensurePermissions() => _requestPermissions();

  Future<void> showFromRealtime({
    required String notificationId,
    required String title,
    required String body,
  }) async {
    if (kIsWeb) {
      return;
    }

    if (!await _canPostNotifications()) {
      if (kDebugMode) {
        debugPrint(
          'LocalNotification: skipped (permission off) id=$notificationId',
        );
      }
      return;
    }

    final displayId = notificationId.hashCode & 0x7FFFFFFF;
    final trimmedBody =
        body.length > 180 ? '${body.substring(0, 177)}...' : body;

    try {
      await _plugin.show(
        id: displayId,
        title: title,
        body: trimmedBody,
        notificationDetails: const NotificationDetails(
          android: AndroidNotificationDetails(
            _androidChannelId,
            _androidChannelName,
            channelDescription: _androidChannelDescription,
            importance: Importance.max,
            priority: Priority.high,
            playSound: true,
            enableVibration: true,
            icon: '@mipmap/launcher_icon',
            visibility: NotificationVisibility.public,
          ),
          iOS: DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
          ),
        ),
        payload: notificationId,
      );
      if (kDebugMode) {
        debugPrint('LocalNotification: shown id=$notificationId title=$title');
      }
    } catch (e, st) {
      if (kDebugMode) {
        debugPrint('LocalNotification: show failed $e\n$st');
      }
    }
  }

  Future<bool> _canPostNotifications() async {
    final android = _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    if (android != null) {
      final enabled = await android.areNotificationsEnabled();
      return enabled ?? true;
    }
    return true;
  }

  Future<void> _createAndroidChannel() async {
    final android = _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    if (android == null) {
      return;
    }

    const channel = AndroidNotificationChannel(
      _androidChannelId,
      _androidChannelName,
      description: _androidChannelDescription,
      importance: Importance.max,
      playSound: true,
      enableVibration: true,
    );
    await android.createNotificationChannel(channel);
  }

  Future<void> _requestPermissions() async {
    final android = _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    final granted = await android?.requestNotificationsPermission();
    if (kDebugMode) {
      debugPrint('LocalNotification: POST_NOTIFICATIONS granted=$granted');
    }

    final ios = _plugin
        .resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin
        >();
    await ios?.requestPermissions(alert: true, badge: true, sound: true);
  }
}
