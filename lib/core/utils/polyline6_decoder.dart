/// Decodes Mapbox / OSRM polyline6 encoded strings (precision 1e6).
class Polyline6Decoder {
  Polyline6Decoder._();

  static List<({double latitude, double longitude})> decode(String encoded) {
    return decodeWithPrecision(encoded, 6);
  }

  /// Decodes encoded polyline with explicit precision digits (5 or 6).
  static List<({double latitude, double longitude})> decodeWithPrecision(
    String encoded,
    int precision,
  ) {
    if (encoded.isEmpty) return [];
    if (precision < 1) return [];

    final scale = _precisionScale(precision);

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

      points.add((latitude: lat / scale, longitude: lng / scale));
    }

    return points;
  }

  /// Decode theo `polylineEncoding` từ BE: polyline6, polyline5, polyline.
  static List<({double latitude, double longitude})> decodeByEncoding(
    String encoded,
    String? polylineEncoding,
  ) {
    final normalized = (polylineEncoding ?? '').trim().toLowerCase();
    if (normalized.contains('6')) {
      return decodeWithPrecision(encoded, 6);
    }
    if (normalized.contains('5') || normalized == 'polyline') {
      return decodeWithPrecision(encoded, 5);
    }

    // Keep backward compatibility with previous behavior.
    return decode(encoded);
  }

  static double _precisionScale(int precision) {
    switch (precision) {
      case 5:
        return 1e5;
      case 6:
        return 1e6;
      default:
        return 1e6;
    }
  }
}
