import '../../domain/entities/notification_item.dart';

class NotificationItemModel extends NotificationItem {
  const NotificationItemModel({
    required super.notificationId,
    required super.userId,
    super.userFullName,
    super.orderId,
    super.parentNotificationId,
    super.orderCode,
    required super.title,
    required super.content,
    required super.type,
    required super.isRead,
    required super.createdAt,
  });

  factory NotificationItemModel.fromJson(Map<String, dynamic> json) {
    return NotificationItemModel(
      notificationId: json['notificationId']?.toString() ?? '',
      userId: json['userId']?.toString() ?? '',
      userFullName: _nullableString(json['userFullName']),
      orderId: _nullableString(json['orderId']),
      parentNotificationId: _nullableString(json['parentNotificationId']),
      orderCode: _nullableString(json['orderCode']),
      title: json['title']?.toString() ?? '',
      content: json['content']?.toString() ?? '',
      type: NotificationType.fromApi(json['type']),
      isRead: json['isRead'] as bool? ?? false,
      createdAt: _parseDateTime(json['createdAt']),
    );
  }

  static String? _nullableString(dynamic value) {
    if (value == null) {
      return null;
    }

    final output = value.toString().trim();
    return output.isEmpty ? null : output;
  }

  static DateTime _parseDateTime(dynamic value) {
    if (value is String && value.trim().isNotEmpty) {
      return DateTime.tryParse(value)?.toLocal() ?? DateTime.now();
    }
    return DateTime.now();
  }
}
