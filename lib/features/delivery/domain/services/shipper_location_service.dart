enum ShipperLocationStatus {
  success,
  serviceDisabled,
  denied,
  deniedForever,
  failed,
}

class ShipperLocationResult {
  const ShipperLocationResult({required this.status, this.location});

  final ShipperLocationStatus status;

  final ({double latitude, double longitude})? location;

  bool get hasLocation =>
      status == ShipperLocationStatus.success && location != null;
}

abstract class ShipperLocationService {
  Future<ShipperLocationResult> resolveCurrentLocation();
}
