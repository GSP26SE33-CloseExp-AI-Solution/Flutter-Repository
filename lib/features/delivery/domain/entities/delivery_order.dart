import 'package:equatable/equatable.dart';

/// Delivery Order Entity - Domain Layer
///
/// Represents an individual order within a delivery group.
class DeliveryOrder extends Equatable {
  final String orderId;

  /// Nhóm giao (BE `deliveryGroupId`) — dùng để gọi start-delivery trước khi xác nhận đơn.
  final String? deliveryGroupId;

  final String orderCode;
  final DeliveryOrderStatus status;
  final String deliveryType;
  final double totalAmount;
  final double deliveryFee;
  final DateTime orderDate;
  final String customerName;
  final String customerPhone;

  /// Home delivery: maps from BE `addressLine` (CustomerAddress.AddressLine)
  final String? deliveryAddress;

  /// Pickup: maps from BE `collectionPointName` (CollectionPoint.Name)
  final String? pickupPointName;

  /// Not returned by BE in DeliveryOrderResponseDto (always null from API)
  final String? pickupPointAddress;
  final String? deliveryNote;
  final String timeSlotDisplay;
  final int totalItems;
  final List<DeliveryOrderItem> items;

  /// GPS coordinate of delivery/pickup location (from BE Latitude)
  final double? latitude;

  /// GPS coordinate of delivery/pickup location (from BE Longitude)
  final double? longitude;

  const DeliveryOrder({
    required this.orderId,
    this.deliveryGroupId,
    required this.orderCode,
    required this.status,
    required this.deliveryType,
    required this.totalAmount,
    required this.deliveryFee,
    required this.orderDate,
    required this.customerName,
    required this.customerPhone,
    this.deliveryAddress,
    this.pickupPointName,
    this.pickupPointAddress,
    this.deliveryNote,
    required this.timeSlotDisplay,
    required this.totalItems,
    this.items = const [],
    this.latitude,
    this.longitude,
  });

  /// BE uses string values like `HomeDelivery` / `Pickup` (see Order.DeliveryType), not `home` / `pickup`.
  static String _normalizeDeliveryType(String raw) =>
      raw.toLowerCase().replaceAll('_', '');

  /// Check if this is a home delivery
  bool get isHomeDelivery {
    final t = _normalizeDeliveryType(deliveryType);
    return t == 'home' || t == 'homedelivery';
  }

  /// Check if this is a pickup order
  bool get isPickup {
    final t = _normalizeDeliveryType(deliveryType);
    return t == 'pickup' || t == 'storepickup';
  }

  /// Get the delivery destination address shown on cards (home: addressLine; pickup: point address or name)
  String get destinationAddress {
    if (isHomeDelivery) {
      return deliveryAddress ?? '';
    }
    return pickupPointAddress ?? pickupPointName ?? '';
  }

  /// Check if order is pending (not yet paid or processing)
  bool get isPending =>
      status == DeliveryOrderStatus.pending ||
      status == DeliveryOrderStatus.paidProcessing;

  /// Check if order is ready for delivery
  bool get isReadyToShip => status == DeliveryOrderStatus.readyToShip;

  /// Check if order is delivered and waiting confirmation
  bool get isDeliveredWaitConfirm =>
      status == DeliveryOrderStatus.deliveredWaitConfirm;

  /// Check if order is completed
  bool get isCompleted => status == DeliveryOrderStatus.completed;

  /// Check if order failed
  bool get isFailed => status == DeliveryOrderStatus.failed;

  /// Check if order can be confirmed (Ready_To_Ship status)
  bool get canConfirm => status == DeliveryOrderStatus.readyToShip;

  /// Total order value (including delivery fee)
  double get totalValue => totalAmount + deliveryFee;

  @override
  List<Object?> get props => [
    orderId,
    deliveryGroupId,
    orderCode,
    status,
    deliveryType,
    totalAmount,
    deliveryFee,
    orderDate,
    customerName,
    customerPhone,
    deliveryAddress,
    pickupPointName,
    pickupPointAddress,
    deliveryNote,
    timeSlotDisplay,
    totalItems,
    items,
    latitude,
    longitude,
  ];
}

/// Order list/detail: [OrderState]. Delivery history rows: [DeliveryState] (PickedUp, InTransit, …).
enum DeliveryOrderStatus {
  pending,
  paidProcessing,
  readyToShip,
  deliveredWaitConfirm,
  completed,
  canceled,
  refunded,
  failed,
  /// [DeliveryState.PickedUp] in delivery logs / history API
  pickedUp,
  /// [DeliveryState.InTransit] in delivery logs / history API
  deliveryInTransit;

  /// Parse status string from backend API
  static DeliveryOrderStatus fromString(String status) {
    switch (status.toLowerCase().replaceAll('_', '')) {
      case 'pending':
        return DeliveryOrderStatus.pending;
      case 'paidprocessing':
        return DeliveryOrderStatus.paidProcessing;
      case 'readytoship':
        return DeliveryOrderStatus.readyToShip;
      case 'deliveredwaitconfirm':
        return DeliveryOrderStatus.deliveredWaitConfirm;
      case 'completed':
        return DeliveryOrderStatus.completed;
      case 'canceled':
        return DeliveryOrderStatus.canceled;
      case 'refunded':
        return DeliveryOrderStatus.refunded;
      case 'failed':
        return DeliveryOrderStatus.failed;
      case 'pickedup':
        return DeliveryOrderStatus.pickedUp;
      case 'intransit':
        return DeliveryOrderStatus.deliveryInTransit;
      default:
        return DeliveryOrderStatus.pending;
    }
  }

  /// Convert to backend-compatible string (with underscores)
  String toApiString() {
    switch (this) {
      case DeliveryOrderStatus.pending:
        return 'Pending';
      case DeliveryOrderStatus.paidProcessing:
        return 'Paid_Processing';
      case DeliveryOrderStatus.readyToShip:
        return 'Ready_To_Ship';
      case DeliveryOrderStatus.deliveredWaitConfirm:
        return 'Delivered_Wait_Confirm';
      case DeliveryOrderStatus.completed:
        return 'Completed';
      case DeliveryOrderStatus.canceled:
        return 'Canceled';
      case DeliveryOrderStatus.refunded:
        return 'Refunded';
      case DeliveryOrderStatus.failed:
        return 'Failed';
      case DeliveryOrderStatus.pickedUp:
        return 'PickedUp';
      case DeliveryOrderStatus.deliveryInTransit:
        return 'InTransit';
    }
  }

  String get displayName {
    switch (this) {
      case DeliveryOrderStatus.pending:
        return 'Chờ thanh toán';
      case DeliveryOrderStatus.paidProcessing:
        return 'Đang xử lý';
      case DeliveryOrderStatus.readyToShip:
        return 'Sẵn sàng giao';
      case DeliveryOrderStatus.deliveredWaitConfirm:
        return 'Chờ xác nhận';
      case DeliveryOrderStatus.completed:
        return 'Hoàn thành';
      case DeliveryOrderStatus.canceled:
        return 'Đã hủy';
      case DeliveryOrderStatus.refunded:
        return 'Đã hoàn tiền';
      case DeliveryOrderStatus.failed:
        return 'Thất bại';
      case DeliveryOrderStatus.pickedUp:
        return 'Đã lấy hàng';
      case DeliveryOrderStatus.deliveryInTransit:
        return 'Đang vận chuyển';
    }
  }
}

/// Delivery Order Item - items within an order
class DeliveryOrderItem extends Equatable {
  final String orderItemId;
  final String productName;
  final int quantity;
  final double unitPrice;
  final double subTotal;

  const DeliveryOrderItem({
    required this.orderItemId,
    required this.productName,
    required this.quantity,
    required this.unitPrice,
    required this.subTotal,
  });

  @override
  List<Object?> get props => [
    orderItemId,
    productName,
    quantity,
    unitPrice,
    subTotal,
  ];
}

/// Delivery Record - history entry
class DeliveryRecord extends Equatable {
  final String deliveryId;
  final String orderId;
  final String orderCode;
  final String userId;
  final String deliveryStaffName;
  final DeliveryOrderStatus status;
  final String? failureReason;
  final DateTime? deliveredAt;

  /// GPS coordinate recorded at delivery time (from BE DeliveryLog.DeliveryLatitude)
  final double? deliveryLatitude;

  /// GPS coordinate recorded at delivery time (from BE DeliveryLog.DeliveryLongitude)
  final double? deliveryLongitude;

  /// URL ảnh chứng minh (BE DeliveryRecordResponseDto.proofImageUrl)
  final String? proofImageUrl;

  const DeliveryRecord({
    required this.deliveryId,
    required this.orderId,
    required this.orderCode,
    required this.userId,
    required this.deliveryStaffName,
    required this.status,
    this.failureReason,
    this.deliveredAt,
    this.deliveryLatitude,
    this.deliveryLongitude,
    this.proofImageUrl,
  });

  @override
  List<Object?> get props => [
    deliveryId,
    orderId,
    orderCode,
    userId,
    deliveryStaffName,
    status,
    failureReason,
    deliveredAt,
    deliveryLatitude,
    deliveryLongitude,
    proofImageUrl,
  ];
}
