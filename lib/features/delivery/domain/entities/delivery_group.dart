import 'package:equatable/equatable.dart';
import 'delivery_order.dart';

/// Delivery group: tập đơn giao theo khung giờ và khu vực.
class DeliveryGroup extends Equatable {
  final String deliveryGroupId;
  final String groupCode;
  final String? deliveryStaffId;
  final String? deliveryStaffName;
  final String timeSlotId;
  final String timeSlotDisplay;
  final String deliveryType;
  final String deliveryArea;

  /// Geographic center of the delivery group area (from BE CenterLatitude)
  final double? centerLatitude;

  /// Geographic center of the delivery group area (from BE CenterLongitude)
  final double? centerLongitude;
  final DeliveryGroupStatus status;
  final int totalOrders;
  final int completedOrders;
  final int failedOrders;
  final String? notes;
  final DateTime deliveryDate;
  final DateTime createdAt;
  final DateTime updatedAt;
  final List<DeliveryOrder> orders;

  const DeliveryGroup({
    required this.deliveryGroupId,
    required this.groupCode,
    this.deliveryStaffId,
    this.deliveryStaffName,
    required this.timeSlotId,
    required this.timeSlotDisplay,
    required this.deliveryType,
    required this.deliveryArea,
    this.centerLatitude,
    this.centerLongitude,
    required this.status,
    required this.totalOrders,
    required this.completedOrders,
    required this.failedOrders,
    this.notes,
    required this.deliveryDate,
    required this.createdAt,
    required this.updatedAt,
    this.orders = const [],
  });

  /// Check if this group is available to accept (Pending status)
  bool get isAvailable => status == DeliveryGroupStatus.pending;

  /// Check if this group is assigned to current staff
  bool get isAssigned => status == DeliveryGroupStatus.assigned;

  /// Check if delivery is in progress
  bool get isInProgress => status == DeliveryGroupStatus.inTransit;

  /// Check if group is completed
  bool get isCompleted => status == DeliveryGroupStatus.completed;

  /// Get pending orders count
  int get pendingOrders => totalOrders - completedOrders - failedOrders;

  /// Get completion percentage
  double get completionRate =>
      totalOrders > 0 ? (completedOrders / totalOrders) * 100 : 0;

  /// Check if all orders are done (completed or failed)
  bool get allOrdersDone => pendingOrders == 0;

  @override
  List<Object?> get props => [
    deliveryGroupId,
    groupCode,
    deliveryStaffId,
    deliveryStaffName,
    timeSlotId,
    timeSlotDisplay,
    deliveryType,
    deliveryArea,
    centerLatitude,
    centerLongitude,
    status,
    totalOrders,
    completedOrders,
    failedOrders,
    notes,
    deliveryDate,
    createdAt,
    updatedAt,
    orders,
  ];
}

/// Trạng thái nhóm giao khớp BE DeliveryGroupState.
enum DeliveryGroupStatus {
  pending,
  assigned,
  inTransit,
  completed,
  failed;

  /// Parse status string from backend API
  static DeliveryGroupStatus fromString(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return DeliveryGroupStatus.pending;
      case 'assigned':
        return DeliveryGroupStatus.assigned;
      case 'intransit':
      case 'in_transit':
        return DeliveryGroupStatus.inTransit;
      case 'completed':
        return DeliveryGroupStatus.completed;
      case 'failed':
        return DeliveryGroupStatus.failed;
      default:
        return DeliveryGroupStatus.pending;
    }
  }

  /// Convert to backend-compatible string
  String toApiString() {
    switch (this) {
      case DeliveryGroupStatus.pending:
        return 'Pending';
      case DeliveryGroupStatus.assigned:
        return 'Assigned';
      case DeliveryGroupStatus.inTransit:
        return 'InTransit';
      case DeliveryGroupStatus.completed:
        return 'Completed';
      case DeliveryGroupStatus.failed:
        return 'Failed';
    }
  }

  String get displayName {
    switch (this) {
      case DeliveryGroupStatus.pending:
        return 'Chờ nhận';
      case DeliveryGroupStatus.assigned:
        return 'Đã nhận';
      case DeliveryGroupStatus.inTransit:
        return 'Đang giao';
      case DeliveryGroupStatus.completed:
        return 'Hoàn thành';
      case DeliveryGroupStatus.failed:
        return 'Thất bại';
    }
  }

  /// Delivery dispatch policy hint for shipper UX.
  String get dispatchPolicyHint {
    switch (this) {
      case DeliveryGroupStatus.pending:
        return 'Nhóm có thể bị điều phối lại cho đến khi bạn nhận';
      case DeliveryGroupStatus.assigned:
      case DeliveryGroupStatus.inTransit:
      case DeliveryGroupStatus.completed:
      case DeliveryGroupStatus.failed:
        return 'Nhóm đã khóa điều phối';
    }
  }
}

/// Delivery Group Summary - lightweight version for lists
class DeliveryGroupSummary extends Equatable {
  final String deliveryGroupId;
  final String groupCode;
  final String timeSlotDisplay;
  final String deliveryType;
  final String deliveryArea;

  /// Geographic center of the delivery group area (from BE CenterLatitude)
  final double? centerLatitude;

  /// Geographic center of the delivery group area (from BE CenterLongitude)
  final double? centerLongitude;
  final DeliveryGroupStatus status;
  final int totalOrders;
  final int completedOrders;
  final DateTime deliveryDate;

  /// Additive metadata from BE for prioritized queue/sorting.
  final DateTime? slotStartAtUtc;
  final DateTime? slotEndAtUtc;
  final double? distanceFromCurrentKm;
  final double? priorityScore;
  final List<String> priorityReasons;

  const DeliveryGroupSummary({
    required this.deliveryGroupId,
    required this.groupCode,
    required this.timeSlotDisplay,
    required this.deliveryType,
    required this.deliveryArea,
    this.centerLatitude,
    this.centerLongitude,
    required this.status,
    required this.totalOrders,
    required this.completedOrders,
    required this.deliveryDate,
    this.slotStartAtUtc,
    this.slotEndAtUtc,
    this.distanceFromCurrentKm,
    this.priorityScore,
    this.priorityReasons = const [],
  });

  int get pendingOrders => totalOrders - completedOrders;

  /// Check if group is available for pickup
  bool get isAvailable => status == DeliveryGroupStatus.pending;

  /// Check if group has been assigned to staff
  bool get isAssigned => status == DeliveryGroupStatus.assigned;

  /// Check if group delivery is in progress
  bool get isInProgress => status == DeliveryGroupStatus.inTransit;

  /// Check if group is completed
  bool get isCompleted => status == DeliveryGroupStatus.completed;

  @override
  List<Object?> get props => [
    deliveryGroupId,
    groupCode,
    timeSlotDisplay,
    deliveryType,
    deliveryArea,
    centerLatitude,
    centerLongitude,
    status,
    totalOrders,
    completedOrders,
    deliveryDate,
    slotStartAtUtc,
    slotEndAtUtc,
    distanceFromCurrentKm,
    priorityScore,
    priorityReasons,
  ];
}
