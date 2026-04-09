import '../../domain/entities/delivery_route_plan.dart';

class DeliveryRoutePlanModel extends DeliveryRoutePlan {
  const DeliveryRoutePlanModel({
    required super.orderedOrderIds,
    required super.totalDistanceKm,
    required super.totalDurationMinutes,
    required super.encodedPolyline,
    required super.polylineEncoding,
    required super.metric,
    required super.skippedOrderIds,
  });

  factory DeliveryRoutePlanModel.fromJson(Map<String, dynamic> json) {
    List<String> parseIdList(dynamic raw) {
      if (raw is! List) return [];
      return raw.map((e) => e.toString()).toList();
    }

    double parseDouble(dynamic v) {
      if (v is num) return v.toDouble();
      if (v is String) return double.tryParse(v) ?? 0;
      return 0;
    }

    return DeliveryRoutePlanModel(
      orderedOrderIds: parseIdList(json['orderedOrderIds']),
      totalDistanceKm: parseDouble(json['totalDistanceKm']),
      totalDurationMinutes: parseDouble(json['totalDurationMinutes']),
      encodedPolyline: (json['encodedPolyline'] as String?) ?? '',
      polylineEncoding: (json['polylineEncoding'] as String?) ?? 'polyline6',
      metric: (json['metric'] as String?) ?? 'distance',
      skippedOrderIds: parseIdList(json['skippedOrderIds']),
    );
  }
}
