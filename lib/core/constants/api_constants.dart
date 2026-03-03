/// API Constants for CloseExp Delivery Staff App
///
/// This file contains all API-related constants including base URLs,
/// endpoints, and timeout configurations.
library;

import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;

class ApiConstants {
  ApiConstants._();

  // Base URL - Environment-aware configuration
  static String get baseUrl {
    if (kIsWeb) {
      return 'http://localhost:5000/api';
    }
    if (Platform.isAndroid) {
      return 'http://10.0.2.2:5000/api'; // Android Emulator
    }
    if (Platform.isIOS) {
      return 'http://localhost:5000/api'; // iOS Simulator
    }
    return 'http://localhost:5000/api';
  }

  // Production URL (uncomment when deploying)
  // static const String baseUrl = 'https://your-production-url.com/api';

  // ============== AUTH ENDPOINTS ==============
  static const String login = '/auth/login';
  static const String register = '/auth/register';
  static const String googleLogin = '/auth/google-login';
  static const String refreshToken = '/auth/refresh-token';
  static const String logout = '/auth/logout';
  static const String logoutAll = '/auth/logout-all';
  static const String verifyOtp = '/auth/verify-otp';
  static const String resendOtp = '/auth/resend-otp';
  static const String forgotPassword = '/auth/forgot-password';
  static const String resetPassword = '/auth/reset-password';

  // ============== USER ENDPOINTS ==============
  static const String currentUser = '/users/current-user';
  static const String users = '/users';

  // ============== DELIVERY ENDPOINTS ==============
  // Delivery Groups
  static const String deliveryGroupsAvailable = '/delivery/groups/available';
  static const String deliveryGroupsMy = '/delivery/groups/my';
  static String deliveryGroupById(String id) => '/delivery/groups/$id';
  static String acceptDeliveryGroup(String id) => '/delivery/groups/$id/accept';
  static String startDeliveryGroup(String id) => '/delivery/groups/$id/start';
  static String completeDeliveryGroup(String id) =>
      '/delivery/groups/$id/complete';

  // Delivery Orders
  static String deliveryOrderById(String id) => '/delivery/orders/$id';
  static String confirmDelivery(String id) =>
      '/delivery/orders/$id/confirm-delivery';
  static String reportDeliveryFailure(String id) =>
      '/delivery/orders/$id/report-failure';

  // Delivery Stats & History
  static const String deliveryHistory = '/delivery/history';
  static const String deliveryStats = '/delivery/stats';

  // ============== UPLOAD ENDPOINTS ==============
  static const String upload = '/upload';

  // ============== TIMEOUTS ==============
  static const Duration connectionTimeout = Duration(seconds: 30);
  static const Duration receiveTimeout = Duration(seconds: 30);
  static const Duration sendTimeout = Duration(seconds: 30);
}
