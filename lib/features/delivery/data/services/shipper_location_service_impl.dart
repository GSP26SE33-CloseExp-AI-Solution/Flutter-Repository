import 'package:geolocator/geolocator.dart' as geo;

import '../../domain/services/shipper_location_service.dart';

class ShipperLocationServiceImpl implements ShipperLocationService {
  @override
  Future<ShipperLocationResult> resolveCurrentLocation() async {
    try {
      final serviceEnabled = await geo.Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        return const ShipperLocationResult(
          status: ShipperLocationStatus.serviceDisabled,
        );
      }

      var permission = await geo.Geolocator.checkPermission();
      if (permission == geo.LocationPermission.denied) {
        permission = await geo.Geolocator.requestPermission();
      }

      if (permission == geo.LocationPermission.denied ||
          permission == geo.LocationPermission.deniedForever) {
        final status = permission == geo.LocationPermission.deniedForever
            ? ShipperLocationStatus.deniedForever
            : ShipperLocationStatus.denied;
        return ShipperLocationResult(status: status);
      }

      final position = await geo.Geolocator.getCurrentPosition(
        locationSettings: const geo.LocationSettings(
          accuracy: geo.LocationAccuracy.high,
          timeLimit: Duration(seconds: 8),
        ),
      );

      return ShipperLocationResult(
        status: ShipperLocationStatus.success,
        location: (latitude: position.latitude, longitude: position.longitude),
      );
    } catch (_) {
      return const ShipperLocationResult(status: ShipperLocationStatus.failed);
    }
  }
}
