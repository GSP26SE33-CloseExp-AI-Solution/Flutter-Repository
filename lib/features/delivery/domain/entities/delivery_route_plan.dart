/// Planned route for a delivery group (from BE Mapbox integration).
class DeliveryRoutePlan {
  final List<String> orderedOrderIds;
  final double totalDistanceKm;
  final double totalDurationMinutes;
  final String encodedPolyline;
  final String polylineEncoding;
  final String metric;
  final List<String> skippedOrderIds;

  const DeliveryRoutePlan({
    required this.orderedOrderIds,
    required this.totalDistanceKm,
    required this.totalDurationMinutes,
    required this.encodedPolyline,
    required this.polylineEncoding,
    required this.metric,
    required this.skippedOrderIds,
  });

  String get summaryLabel =>
      '${totalDistanceKm.toStringAsFixed(1)} km • ${totalDurationMinutes.toStringAsFixed(0)} phút';
}
