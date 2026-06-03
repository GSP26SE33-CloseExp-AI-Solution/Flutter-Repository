import 'dart:convert';

/// Payload from BE SignalR event `notification.received`.
class RealtimeNotificationPayload {
  final String notificationId;
  final String title;
  final String content;
  final String? orderId;

  const RealtimeNotificationPayload({
    required this.notificationId,
    required this.title,
    required this.content,
    this.orderId,
  });

  factory RealtimeNotificationPayload.fromDynamic(Object? raw) {
    if (raw is String && raw.trim().isNotEmpty) {
      try {
        final decoded = jsonDecode(raw);
        if (decoded is Map) {
          return RealtimeNotificationPayload.fromMap(
            Map<String, dynamic>.from(decoded),
          );
        }
      } catch (_) {
        // Fall through.
      }
    }

    if (raw is Map) {
      return RealtimeNotificationPayload.fromMap(
        Map<String, dynamic>.from(raw),
      );
    }

    return const RealtimeNotificationPayload(
      notificationId: '',
      title: 'Thông báo mới',
      content: 'Bạn có cập nhật mới',
    );
  }

  factory RealtimeNotificationPayload.fromMap(Map<String, dynamic> json) {
    return RealtimeNotificationPayload(
      notificationId: _readString(json, 'notificationId', 'NotificationId'),
      title: _readString(json, 'title', 'Title', fallback: 'Thông báo mới'),
      content: _readString(
        json,
        'content',
        'Content',
        fallback: 'Bạn có cập nhật mới',
      ),
      orderId: _nullableString(
        json['orderId'] ?? json['OrderId'],
      ),
    );
  }

  bool get isValid => notificationId.isNotEmpty;

  static String _readString(
    Map<String, dynamic> json,
    String camelKey,
    String pascalKey, {
    String fallback = '',
  }) {
    final value = json[camelKey] ?? json[pascalKey];
    if (value == null) {
      return fallback;
    }
    final text = value.toString().trim();
    return text.isEmpty ? fallback : text;
  }

  static String? _nullableString(dynamic value) {
    if (value == null) {
      return null;
    }
    final output = value.toString().trim();
    return output.isEmpty ? null : output;
  }
}
