import 'package:equatable/equatable.dart';

class NotificationItem extends Equatable {
  final String notificationId;
  final String userId;
  final String? userFullName;
  final String? orderId;
  final String? parentNotificationId;
  final String? orderCode;
  final String title;
  final String content;
  final NotificationType type;
  final bool isRead;
  final DateTime createdAt;

  const NotificationItem({
    required this.notificationId,
    required this.userId,
    this.userFullName,
    this.orderId,
    this.parentNotificationId,
    this.orderCode,
    required this.title,
    required this.content,
    required this.type,
    required this.isRead,
    required this.createdAt,
  });

  NotificationItem copyWith({
    String? notificationId,
    String? userId,
    String? userFullName,
    String? orderId,
    String? parentNotificationId,
    String? orderCode,
    String? title,
    String? content,
    NotificationType? type,
    bool? isRead,
    DateTime? createdAt,
  }) {
    return NotificationItem(
      notificationId: notificationId ?? this.notificationId,
      userId: userId ?? this.userId,
      userFullName: userFullName ?? this.userFullName,
      orderId: orderId ?? this.orderId,
      parentNotificationId: parentNotificationId ?? this.parentNotificationId,
      orderCode: orderCode ?? this.orderCode,
      title: title ?? this.title,
      content: content ?? this.content,
      type: type ?? this.type,
      isRead: isRead ?? this.isRead,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  List<Object?> get props => [
    notificationId,
    userId,
    userFullName,
    orderId,
    parentNotificationId,
    orderCode,
    title,
    content,
    type,
    isRead,
    createdAt,
  ];
}

enum NotificationType {
  orderUpdate,
  promotion,
  systemAlert,
  deliveryUpdate,
  priceAlert;

  static NotificationType fromApi(dynamic raw) {
    if (raw is int) {
      switch (raw) {
        case 0:
          return NotificationType.orderUpdate;
        case 1:
          return NotificationType.promotion;
        case 2:
          return NotificationType.systemAlert;
        case 3:
          return NotificationType.deliveryUpdate;
        case 4:
          return NotificationType.priceAlert;
        default:
          return NotificationType.systemAlert;
      }
    }

    final value = raw?.toString().trim().toLowerCase() ?? '';
    switch (value) {
      case 'orderupdate':
      case 'order_update':
        return NotificationType.orderUpdate;
      case 'promotion':
        return NotificationType.promotion;
      case 'systemalert':
      case 'system_alert':
        return NotificationType.systemAlert;
      case 'deliveryupdate':
      case 'delivery_update':
        return NotificationType.deliveryUpdate;
      case 'pricealert':
      case 'price_alert':
        return NotificationType.priceAlert;
      default:
        return NotificationType.systemAlert;
    }
  }

  String get displayName {
    switch (this) {
      case NotificationType.orderUpdate:
        return 'Cập nhật đơn hàng';
      case NotificationType.promotion:
        return 'Khuyến mãi';
      case NotificationType.systemAlert:
        return 'Hệ thống';
      case NotificationType.deliveryUpdate:
        return 'Cập nhật giao hàng';
      case NotificationType.priceAlert:
        return 'Cảnh báo giá';
    }
  }
}
