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
    super.pickupLeg,
    super.deliveryLeg,
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

    RouteLeg? parseLeg(dynamic raw) {
      if (raw is! Map<String, dynamic>) return null;
      return RouteLeg(
        kind: (raw['kind'] as String?) ?? '',
        distanceKm: parseDouble(raw['distanceKm']),
        durationMinutes: parseDouble(raw['durationMinutes']),
        encodedPolyline: (raw['encodedPolyline'] as String?) ?? '',
        polylineEncoding: (raw['polylineEncoding'] as String?) ?? 'polyline6',
        strategyUsed: (raw['strategyUsed'] as String?) ?? '',
        from: parseEndpoint(raw['from']),
        to: parseEndpoint(raw['to']),
      );
    }

    return DeliveryRoutePlanModel(
      orderedOrderIds: parseIdList(json['orderedOrderIds']),
      totalDistanceKm: parseDouble(json['totalDistanceKm']),
      totalDurationMinutes: parseDouble(json['totalDurationMinutes']),
      encodedPolyline: (json['encodedPolyline'] as String?) ?? '',
      polylineEncoding: (json['polylineEncoding'] as String?) ?? 'polyline6',
      metric: (json['metric'] as String?) ?? 'distance',
      skippedOrderIds: parseIdList(json['skippedOrderIds']),
      pickupLeg: parseLeg(json['pickupLeg']),
      deliveryLeg: parseLeg(json['deliveryLeg']),
    );
  }
}

RouteLegEndpoint? parseEndpoint(dynamic raw) {
  if (raw is! Map<String, dynamic>) return null;
  final lat = raw['latitude'];
  final lng = raw['longitude'];
  if (lat is! num || lng is! num) return null;
  return RouteLegEndpoint(
    latitude: lat.toDouble(),
    longitude: lng.toDouble(),
    label: raw['label'] as String?,
  );
}
