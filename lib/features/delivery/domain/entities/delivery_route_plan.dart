/// Planned route for a delivery group (from BE Mapbox integration).
class DeliveryRoutePlan {
  final List<String> orderedOrderIds;
  final double totalDistanceKm;
  final double totalDurationMinutes;
  final String encodedPolyline;
  final String polylineEncoding;
  final String metric;
  final List<String> skippedOrderIds;

  /// Chặng A: Vị trí shipper → siêu thị (pickup). Null khi thiếu toạ độ siêu thị.
  final RouteLeg? pickupLeg;

  /// Chặng B: Siêu thị → khách hàng (đã tối ưu thứ tự stop). Null khi bucket rỗng.
  final RouteLeg? deliveryLeg;

  const DeliveryRoutePlan({
    required this.orderedOrderIds,
    required this.totalDistanceKm,
    required this.totalDurationMinutes,
    required this.encodedPolyline,
    required this.polylineEncoding,
    required this.metric,
    required this.skippedOrderIds,
    this.pickupLeg,
    this.deliveryLeg,
  });

  String get summaryLabel =>
      '${totalDistanceKm.toStringAsFixed(1)} km • ${totalDurationMinutes.toStringAsFixed(0)} phút';

  /// Preferred polyline for delivery rendering (Leg B) with fallback to the
  /// legacy top-level [encodedPolyline] for older BE responses.
  String get preferredDeliveryPolyline {
    final leg = deliveryLeg;
    if (leg != null && leg.encodedPolyline.isNotEmpty) {
      return leg.encodedPolyline;
    }
    return encodedPolyline;
  }

  /// Preferred encoding for [preferredDeliveryPolyline].
  String get preferredDeliveryPolylineEncoding {
    final leg = deliveryLeg;
    if (leg != null && leg.encodedPolyline.isNotEmpty) {
      return leg.polylineEncoding;
    }
    return polylineEncoding;
  }
}

/// Chi tiết một chặng trong lộ trình two-leg (pickup / delivery).
class RouteLeg {
  final String kind;
  final double distanceKm;
  final double durationMinutes;
  final String encodedPolyline;
  final String polylineEncoding;
  final String strategyUsed;
  final RouteLegEndpoint? from;
  final RouteLegEndpoint? to;

  const RouteLeg({
    required this.kind,
    required this.distanceKm,
    required this.durationMinutes,
    required this.encodedPolyline,
    required this.polylineEncoding,
    required this.strategyUsed,
    this.from,
    this.to,
  });

  String get summaryLabel =>
      '${distanceKm.toStringAsFixed(1)} km • ${durationMinutes.toStringAsFixed(0)} phút';
}

class RouteLegEndpoint {
  final double latitude;
  final double longitude;
  final String? label;

  const RouteLegEndpoint({
    required this.latitude,
    required this.longitude,
    this.label,
  });
}
