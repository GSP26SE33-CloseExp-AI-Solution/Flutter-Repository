import 'package:equatable/equatable.dart';

/// Delivery Stats Entity - Domain Layer
///
/// Represents delivery statistics for the current staff member.
class DeliveryStats extends Equatable {
  final String deliveryStaffId;
  final String deliveryStaffName;
  final int totalAssignedGroups;
  final int totalOrders;
  final int completedOrders;
  final int failedOrders;
  final int pendingOrders;
  final int inTransitOrders;
  final double completionRate;
  final DateTime? lastDeliveryAt;

  const DeliveryStats({
    required this.deliveryStaffId,
    required this.deliveryStaffName,
    required this.totalAssignedGroups,
    required this.totalOrders,
    required this.completedOrders,
    required this.failedOrders,
    required this.pendingOrders,
    required this.inTransitOrders,
    required this.completionRate,
    this.lastDeliveryAt,
  });

  /// Get success rate as percentage string
  String get successRateDisplay => '${completionRate.toStringAsFixed(1)}%';

  /// Check if staff has any pending work
  bool get hasPendingWork => pendingOrders > 0 || inTransitOrders > 0;

  /// Total active orders (pending + in transit)
  int get activeOrders => pendingOrders + inTransitOrders;

  /// Check if staff has made any deliveries
  bool get hasDeliveryHistory => totalOrders > 0;

  @override
  List<Object?> get props => [
        deliveryStaffId,
        deliveryStaffName,
        totalAssignedGroups,
        totalOrders,
        completedOrders,
        failedOrders,
        pendingOrders,
        inTransitOrders,
        completionRate,
        lastDeliveryAt,
      ];

  /// Empty stats for initial state
  static const empty = DeliveryStats(
    deliveryStaffId: '',
    deliveryStaffName: '',
    totalAssignedGroups: 0,
    totalOrders: 0,
    completedOrders: 0,
    failedOrders: 0,
    pendingOrders: 0,
    inTransitOrders: 0,
    completionRate: 0,
    lastDeliveryAt: null,
  );
}
