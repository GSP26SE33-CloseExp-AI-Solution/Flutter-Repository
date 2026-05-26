import '../../domain/entities/delivery_order.dart';
import '../../domain/repositories/delivery_repository.dart';
import '../../domain/services/shipper_location_service.dart';

/// Sắp [orders] theo [routeStopOrderIds]; đơn không có trong danh sách được đẩy xuống cuối.
List<DeliveryOrder> sortDeliveryOrdersByRouteStopIds(
  List<DeliveryOrder> orders,
  List<String>? routeStopOrderIds,
) {
  if (routeStopOrderIds == null || routeStopOrderIds.isEmpty) {
    return List<DeliveryOrder>.from(orders);
  }
  final byId = <String, DeliveryOrder>{
    for (final o in orders) o.orderId.trim(): o,
  };
  final used = <String>{};
  final out = <DeliveryOrder>[];
  for (final raw in routeStopOrderIds) {
    final id = raw.trim();
    if (id.isEmpty) continue;
    final o = byId[id];
    if (o != null) {
      out.add(o);
      used.add(id);
    }
  }
  for (final o in orders) {
    final id = o.orderId.trim();
    if (!used.contains(id)) {
      out.add(o);
    }
  }
  return out;
}

/// Gọi BE tính lại route-plan để lấy [DeliveryRoutePlan.orderedOrderIds] cùng hướng với route map.
Future<List<String>?> fetchRouteStopOrderIdsForGroup({
  required String groupId,
  required DeliveryRepository repository,
  required ShipperLocationService shipperLocationService,
  double? groupCenterLatitude,
  double? groupCenterLongitude,
  String metric = 'duration',
  bool skipPickupLeg = false,
}) async {
  final loc = await shipperLocationService.resolveCurrentLocation();
  late final double startLat;
  late final double startLng;
  if (loc.hasLocation) {
    startLat = loc.location!.latitude;
    startLng = loc.location!.longitude;
  } else if (groupCenterLatitude != null && groupCenterLongitude != null) {
    startLat = groupCenterLatitude;
    startLng = groupCenterLongitude;
  } else {
    startLat = 10.776889;
    startLng = 106.700806;
  }

  final planResult = await repository.computeDeliveryRoutePlan(
    groupId,
    metric: metric,
    startLatitude: startLat,
    startLongitude: startLng,
    skipPickupLeg: skipPickupLeg,
  );
  return planResult.fold((_) => null, (plan) {
    final ids = plan.orderedOrderIds;
    if (ids.isEmpty) return null;
    return List<String>.from(ids);
  });
}
