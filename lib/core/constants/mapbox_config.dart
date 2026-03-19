class MapboxConfig {
  MapboxConfig._();

  // Inject at runtime to avoid committing tokens to source control.
  static const String accessToken = String.fromEnvironment(
    'MAPBOX_ACCESS_TOKEN',
    defaultValue: '',
  );

  static bool get isConfigured => accessToken.trim().isNotEmpty;
}
