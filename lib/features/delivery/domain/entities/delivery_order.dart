import 'package:equatable/equatable.dart';

/// Delivery Order Entity - Domain Layer
///
/// Represents an individual order within a delivery group.
class DeliveryOrder extends Equatable {
  final String orderId;
  final String orderCode;
  final DeliveryOrderStatus status;
  final String deliveryType;
  final double totalAmount;
  final double deliveryFee;
  final DateTime orderDate;
  final String customerName;
  final String customerPhone;
  final String? deliveryAddress;
  final String? pickupPointName;
  final String? pickupPointAddress;
  final String? deliveryNote;
  final String timeSlotDisplay;
  final int totalItems;
  final List<DeliveryOrderItem> items;

  const DeliveryOrder({
    required this.orderId,
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
  });

  /// Check if this is a home delivery
  bool get isHomeDelivery => deliveryType.toLowerCase() == 'home';

  /// Check if this is a pickup order
  bool get isPickup => deliveryType.toLowerCase() == 'pickup';

  /// Get the delivery destination address
  String get destinationAddress =>
      isHomeDelivery ? (deliveryAddress ?? '') : (pickupPointAddress ?? '');

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
  ];
}

/// Delivery Order Status Enum matching backend OrderState enum
/// Backend OrderState: Pending, Paid_Processing, Ready_To_Ship, Delivered_Wait_Confirm, Completed, Canceled, Refunded, Failed
enum DeliveryOrderStatus {
  pending,
  paidProcessing,
  readyToShip,
  deliveredWaitConfirm,
  completed,
  canceled,
  refunded,
  failed;

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

  const DeliveryRecord({
    required this.deliveryId,
    required this.orderId,
    required this.orderCode,
    required this.userId,
    required this.deliveryStaffName,
    required this.status,
    this.failureReason,
    this.deliveredAt,
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
  ];
}
