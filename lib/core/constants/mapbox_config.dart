import 'dart:convert';

import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;
import 'package:flutter/services.dart';

/// Mapbox token config: prefer dart-define, fallback to mapbox.dev.json asset for local dev.
class MapboxConfig {
  MapboxConfig._();

  static const String _fromDefine = String.fromEnvironment(
    'MAPBOX_ACCESS_TOKEN',
    defaultValue: '',
  );

  static String _accessToken = _fromDefine.trim();

  /// Call from [main] after [WidgetsFlutterBinding.ensureInitialized].
  static Future<void> initialize() async {
    if (_fromDefine.trim().isNotEmpty) {
      _accessToken = _fromDefine.trim();
      return;
    }

    try {
      final raw = await rootBundle.loadString('mapbox.dev.json');
      final map = jsonDecode(raw) as Map<String, dynamic>;
      final token = map['MAPBOX_ACCESS_TOKEN'];
      if (token is String && token.trim().isNotEmpty) {
        _accessToken = token.trim();
      }
    } catch (_) {
      // Missing asset or invalid JSON — leave empty
    }
  }

  static String get accessToken => _accessToken;

  static bool get isConfigured => _accessToken.isNotEmpty;

  /// Whether [MapWidget] is supported (Android/iOS only, not web or desktop).
  static bool get isMapWidgetSupported =>
      !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.android ||
          defaultTargetPlatform == TargetPlatform.iOS);
}
