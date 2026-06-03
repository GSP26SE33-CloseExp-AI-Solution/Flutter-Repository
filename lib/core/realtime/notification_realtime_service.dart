import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:signalr_netcore/signalr_client.dart';

import '../constants/api_constants.dart';
import '../constants/app_constants.dart';
import 'realtime_notification_payload.dart';

typedef RealtimeNotificationHandler = void Function(
  RealtimeNotificationPayload? payload,
);

/// Connects to BE NotificationHub; push triggers [onNotificationReceived].
class NotificationRealtimeService {
  NotificationRealtimeService({required FlutterSecureStorage secureStorage})
    : _secureStorage = secureStorage;

  final FlutterSecureStorage _secureStorage;
  HubConnection? _connection;
  RealtimeNotificationHandler? onNotificationReceived;

  bool get isConnected =>
      _connection?.state == HubConnectionState.Connected;

  Future<void> connect() async {
    final token = await _secureStorage.read(key: AppConstants.accessTokenKey);
    if (token == null || token.trim().isEmpty) {
      return;
    }

    await disconnect();

    final hubUrl = ApiConstants.notificationsHubUrl;
    _connection = HubConnectionBuilder()
        .withUrl(
          hubUrl,
          options: HttpConnectionOptions(
            accessTokenFactory: () async => token,
          ),
        )
        .withAutomaticReconnect()
        .build();

    _connection!.on('notification.received', (arguments) {
      if (kDebugMode) {
        debugPrint('SignalR notification.received args=$arguments');
      }
      onNotificationReceived?.call(_parsePayload(arguments));
    });

    try {
      await _connection!.start();
      if (kDebugMode) {
        debugPrint('SignalR connected: $hubUrl');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('SignalR connect failed: $e');
      }
      await disconnect();
    }
  }

  Future<void> disconnect() async {
    final connection = _connection;
    _connection = null;
    if (connection == null) {
      return;
    }

    try {
      await connection.stop();
    } catch (_) {
      // Ignore teardown errors.
    }
  }

  RealtimeNotificationPayload? _parsePayload(List<Object?>? arguments) {
    if (arguments == null || arguments.isEmpty) {
      return null;
    }

    final payload = RealtimeNotificationPayload.fromDynamic(arguments.first);
    return payload.isValid ? payload : null;
  }
}
