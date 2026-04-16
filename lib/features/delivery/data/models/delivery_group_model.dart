import '../../domain/entities/delivery_group.dart';
import 'delivery_order_model.dart';

/// Delivery Group Model - Data Layer
///
/// Handles serialization/deserialization for API communication.
class DeliveryGroupModel extends DeliveryGroup {
  const DeliveryGroupModel({
    required super.deliveryGroupId,
    required super.groupCode,
    super.deliveryStaffId,
    super.deliveryStaffName,
    required super.timeSlotId,
    required super.timeSlotDisplay,
    required super.deliveryType,
    required super.deliveryArea,
    super.centerLatitude,
    super.centerLongitude,
    required super.status,
    required super.totalOrders,
    required super.completedOrders,
    required super.failedOrders,
    super.notes,
    required super.deliveryDate,
    required super.createdAt,
    required super.updatedAt,
    super.orders,
  });

  factory DeliveryGroupModel.fromJson(Map<String, dynamic> json) {
    final ordersList = json['orders'] as List<dynamic>? ?? [];
    final orders = ordersList
        .map((e) => DeliveryOrderModel.fromJson(e as Map<String, dynamic>))
        .toList();

    return DeliveryGroupModel(
      deliveryGroupId: json['deliveryGroupId'] as String? ?? '',
      groupCode: json['groupCode'] as String? ?? '',
      deliveryStaffId: json['deliveryStaffId'] as String?,
      deliveryStaffName: json['deliveryStaffName'] as String?,
      timeSlotId:
          (json['timeSlotId'] ?? json['deliveryTimeSlotId']) as String? ?? '',
      timeSlotDisplay: json['timeSlotDisplay'] as String? ?? '',
      deliveryType: json['deliveryType'] as String? ?? '',
      deliveryArea: json['deliveryArea'] as String? ?? '',
      centerLatitude: (json['centerLatitude'] as num?)?.toDouble(),
      centerLongitude: (json['centerLongitude'] as num?)?.toDouble(),
      status: DeliveryGroupStatus.fromString(json['status'] as String? ?? ''),
      totalOrders: json['totalOrders'] as int? ?? 0,
      completedOrders: json['completedOrders'] as int? ?? 0,
      failedOrders: json['failedOrders'] as int? ?? 0,
      notes: json['notes'] as String?,
      deliveryDate: _parseDateTime(json['deliveryDate']),
      createdAt: _parseDateTime(json['createdAt']),
      updatedAt: _parseDateTime(json['updatedAt']),
      orders: orders,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'deliveryGroupId': deliveryGroupId,
      'groupCode': groupCode,
      'deliveryStaffId': deliveryStaffId,
      'deliveryStaffName': deliveryStaffName,
      'timeSlotId': timeSlotId,
      'timeSlotDisplay': timeSlotDisplay,
      'deliveryType': deliveryType,
      'deliveryArea': deliveryArea,
      'centerLatitude': centerLatitude,
      'centerLongitude': centerLongitude,
      'status': status.toApiString(),
      'totalOrders': totalOrders,
      'completedOrders': completedOrders,
      'failedOrders': failedOrders,
      'notes': notes,
      'deliveryDate': deliveryDate.toIso8601String(),
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'orders': orders.map((e) => (e as DeliveryOrderModel).toJson()).toList(),
    };
  }

  static DateTime _parseDateTime(dynamic dateTime) {
    if (dateTime == null) return DateTime.now();
    if (dateTime is String) return DateTime.parse(dateTime);
    return DateTime.now();
  }
}

/// Delivery Group Summary Model
class DeliveryGroupSummaryModel extends DeliveryGroupSummary {
  const DeliveryGroupSummaryModel({
    required super.deliveryGroupId,
    required super.groupCode,
    required super.timeSlotDisplay,
    required super.deliveryType,
    required super.deliveryArea,
    super.centerLatitude,
    super.centerLongitude,
    required super.status,
    required super.totalOrders,
    required super.completedOrders,
    required super.deliveryDate,
    super.slotStartAtUtc,
    super.slotEndAtUtc,
    super.distanceFromCurrentKm,
    super.priorityScore,
    super.priorityReasons,
  });

  factory DeliveryGroupSummaryModel.fromJson(Map<String, dynamic> json) {
    return DeliveryGroupSummaryModel(
      deliveryGroupId: json['deliveryGroupId'] as String? ?? '',
      groupCode: json['groupCode'] as String? ?? '',
      timeSlotDisplay: json['timeSlotDisplay'] as String? ?? '',
      deliveryType: json['deliveryType'] as String? ?? '',
      deliveryArea: json['deliveryArea'] as String? ?? '',
      centerLatitude: (json['centerLatitude'] as num?)?.toDouble(),
      centerLongitude: (json['centerLongitude'] as num?)?.toDouble(),
      status: DeliveryGroupStatus.fromString(json['status'] as String? ?? ''),
      totalOrders: json['totalOrders'] as int? ?? 0,
      completedOrders: json['completedOrders'] as int? ?? 0,
      deliveryDate: _parseDateTime(json['deliveryDate']),
      slotStartAtUtc: _tryParseDateTime(json['slotStartAtUtc']),
      slotEndAtUtc: _tryParseDateTime(json['slotEndAtUtc']),
      distanceFromCurrentKm: (json['distanceFromCurrentKm'] as num?)
          ?.toDouble(),
      priorityScore: (json['priorityScore'] as num?)?.toDouble(),
      priorityReasons:
          (json['priorityReasons'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'deliveryGroupId': deliveryGroupId,
      'groupCode': groupCode,
      'timeSlotDisplay': timeSlotDisplay,
      'deliveryType': deliveryType,
      'deliveryArea': deliveryArea,
      'centerLatitude': centerLatitude,
      'centerLongitude': centerLongitude,
      'status': status.name,
      'totalOrders': totalOrders,
      'completedOrders': completedOrders,
      'deliveryDate': deliveryDate.toIso8601String(),
      'slotStartAtUtc': slotStartAtUtc?.toIso8601String(),
      'slotEndAtUtc': slotEndAtUtc?.toIso8601String(),
      'distanceFromCurrentKm': distanceFromCurrentKm,
      'priorityScore': priorityScore,
      'priorityReasons': priorityReasons,
    };
  }

  static DateTime _parseDateTime(dynamic dateTime) {
    if (dateTime == null) return DateTime.now();
    if (dateTime is String) return DateTime.parse(dateTime);
    return DateTime.now();
  }

  static DateTime? _tryParseDateTime(dynamic dateTime) {
    if (dateTime is String && dateTime.isNotEmpty) {
      return DateTime.tryParse(dateTime);
    }
    return null;
  }
}
