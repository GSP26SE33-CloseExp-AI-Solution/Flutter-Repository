/// Decodes Mapbox / OSRM polyline6 encoded strings (precision 1e6).
class Polyline6Decoder {
  Polyline6Decoder._();

  static List<({double latitude, double longitude})> decode(String encoded) {
    if (encoded.isEmpty) return [];

    final points = <({double latitude, double longitude})>[];
    var index = 0;
    var lat = 0;
    var lng = 0;

    while (index < encoded.length) {
      var result = 0;
      var shift = 0;
      int b;
      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1f) << shift;
        shift += 5;
      } while (b >= 0x20);
      final dLat = (result & 1) != 0 ? ~(result >> 1) : (result >> 1);
      lat += dLat;

      result = 0;
      shift = 0;
      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1f) << shift;
        shift += 5;
      } while (b >= 0x20);
      final dLng = (result & 1) != 0 ? ~(result >> 1) : (result >> 1);
      lng += dLng;

      points.add((
        latitude: lat / 1e6,
        longitude: lng / 1e6,
      ));
    }

    return points;
  }
}
