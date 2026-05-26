/// Application-level constants: app info, storage keys, configuration values.
library;

class AppConstants {
  AppConstants._();

  // App Info
  static const String appName = 'CloseExp Delivery';
  static const String appVersion = '1.0.0';

  // Storage Keys
  static const String accessTokenKey = 'access_token';
  static const String refreshTokenKey = 'refresh_token';
  static const String userKey = 'user_data';
  static const String tokenExpiryKey = 'token_expiry';

  // Delivery Staff Role
  static const String deliveryStaffRole = 'DeliveryStaff';
}
