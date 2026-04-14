import 'dart:convert';

import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;
import 'package:flutter/services.dart';

/// Mapbox token configuration.
///
/// Priority:
/// 1. Compile-time: `flutter run --dart-define=MAPBOX_ACCESS_TOKEN=pk.xxx`
///    or `--dart-define-from-file=mapbox.dev.json` (see [mapbox_maps_flutter](https://pub.dev/packages/mapbox_maps_flutter))
/// 2. Debug/profile only: bundled [mapbox.dev.json] — must be listed under
///    `flutter: assets:` in [pubspec.yaml] (copy from [mapbox.example.json]).
///
/// Prefer (1) for release/CI so tokens are not committed. (2) is for local dev only.
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

  /// Whether [mapbox_maps_flutter] [MapWidget] is supported for this build target.
  /// The SDK supports Android and iOS only (not web or desktop).
  static bool get isMapWidgetSupported =>
      !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.android ||
          defaultTargetPlatform == TargetPlatform.iOS);
}
