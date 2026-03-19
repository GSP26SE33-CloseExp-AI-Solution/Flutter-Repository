import 'package:equatable/equatable.dart';
import 'delivery_order.dart';

/// Delivery Group Entity - Domain Layer
///
/// Represents a collection of orders assigned to a delivery staff
/// for a specific time slot and delivery area.
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

/// Delivery Group Status Enum matching backend
/// Backend values: "Pending", "Assigned", "InTransit", "Completed"
enum DeliveryGroupStatus {
  pending,
  assigned,
  inTransit,
  completed;

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
    }
  }

  String get displayName {
    switch (this) {
      case DeliveryGroupStatus.pending:
        return 'Có sẵn';
      case DeliveryGroupStatus.assigned:
        return 'Đã nhận';
      case DeliveryGroupStatus.inTransit:
        return 'Đang giao';
      case DeliveryGroupStatus.completed:
        return 'Hoàn thành';
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
  ];
}
