import '../../domain/entities/delivery_stats.dart';

/// Delivery stats model: JSON cho API.
class DeliveryStatsModel extends DeliveryStats {
  const DeliveryStatsModel({
    required super.deliveryStaffId,
    required super.deliveryStaffName,
    required super.totalAssignedGroups,
    required super.totalOrders,
    required super.completedOrders,
    required super.failedOrders,
    required super.pendingOrders,
    required super.inTransitOrders,
    required super.completionRate,
    super.lastDeliveryAt,
  });

  factory DeliveryStatsModel.fromJson(Map<String, dynamic> json) {
    return DeliveryStatsModel(
      deliveryStaffId: json['deliveryStaffId'] as String? ?? '',
      deliveryStaffName: json['deliveryStaffName'] as String? ?? '',
      totalAssignedGroups: json['totalAssignedGroups'] as int? ?? 0,
      totalOrders: json['totalOrders'] as int? ?? 0,
      completedOrders: json['completedOrders'] as int? ?? 0,
      failedOrders: json['failedOrders'] as int? ?? 0,
      pendingOrders: json['pendingOrders'] as int? ?? 0,
      inTransitOrders: json['inTransitOrders'] as int? ?? 0,
      completionRate: (json['completionRate'] as num?)?.toDouble() ?? 0,
      lastDeliveryAt: _parseNullableDateTime(json['lastDeliveryAt']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'deliveryStaffId': deliveryStaffId,
      'deliveryStaffName': deliveryStaffName,
      'totalAssignedGroups': totalAssignedGroups,
      'totalOrders': totalOrders,
      'completedOrders': completedOrders,
      'failedOrders': failedOrders,
      'pendingOrders': pendingOrders,
      'inTransitOrders': inTransitOrders,
      'completionRate': completionRate,
      'lastDeliveryAt': lastDeliveryAt?.toIso8601String(),
    };
  }

  static DateTime? _parseNullableDateTime(dynamic dateTime) {
    if (dateTime == null) return null;
    if (dateTime is String) return DateTime.parse(dateTime);
    return null;
  }
}
