library;

import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kDebugMode, kIsWeb;

class ApiConstants {
  ApiConstants._();

  // Base URL - Environment-aware configuration
  static String get baseUrl {
    const envBaseUrl = String.fromEnvironment('API_BASE_URL');
    if (envBaseUrl.isNotEmpty) {
      return envBaseUrl;
    }

    if (!kDebugMode) {
      // throw StateError(
      //   'Missing API_BASE_URL. Provide it via --dart-define for non-debug builds.',
      // );
      return 'https://be-repository.onrender.com/api';
    }

    // For web
    if (kIsWeb) {
      return 'http://localhost:5014/api';
      // return 'https://g9z03vx4-5014.asse.devtunnels.ms/api';
    }
    // For Android
    if (Platform.isAndroid) {
      // Real Device IP address by ethernet cable
      // return 'http://10.159.160.29:5014/api'; // LibraryIP School
      // return 'http://172.31.177.220:5014/api'; // Physical device USB
      // return 'http://10.0.2.2:5014/api'; // Android Emulator
      return 'https://g9z03vx4-5014.asse.devtunnels.ms/api';
    }
    // For iOS
    if (Platform.isIOS) {
      // return 'http://192.168.1.13:5014/api'; // physical device on same LAN
      return 'https://be-repository.onrender.com/api';
    }
    return 'http://localhost:5014/api';
  }

  // Production URL (uncomment when deploying)
  // static const String baseUrl = 'https://????/api';

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
  static const String deliveryGroupsMyWorkQueue =
      '/delivery/groups/my/work-queue';
  static String deliveryGroupById(String id) => '/delivery/groups/$id';
  static String acceptDeliveryGroup(String id) => '/delivery/groups/$id/accept';
  static String startDeliveryGroup(String id) => '/delivery/groups/$id/start';
  static String completeDeliveryGroup(String id) =>
      '/delivery/groups/$id/complete';

  /// POST body: [DeliveryRoutePlanRequestDto] — tối ưu thứ tự + polyline (Mapbox qua BE).
  static String deliveryGroupRoutePlan(String id) =>
      '/delivery/groups/$id/route-plan';

  // Delivery Orders
  static String deliveryOrderById(String id) => '/delivery/orders/$id';
  static String confirmDelivery(String id) =>
      '/delivery/orders/$id/confirm-delivery';

  /// Multipart field name: `file` — trả về `data.proofImageUrl` (DeliveryProofUploadResponseDto).
  static String deliveryOrderProofImage(String orderId) =>
      '/delivery/orders/$orderId/proof-image';
  static String reportDeliveryFailure(String id) =>
      '/delivery/orders/$id/report-failure';

  // Delivery Stats & History
  static const String deliveryHistory = '/delivery/history';
  static const String deliveryStats = '/delivery/stats';

  /// Query `status` cho GET /delivery/groups/my
  static const String deliveryMyGroupsStatusActive = 'InTransit';
  static const String deliveryMyGroupsStatusCompleted = 'Completed';
  static const String deliveryMyGroupsStatusDone = 'Done';

  /// Sort modes for GET /delivery/groups/my and /delivery/groups/my/work-queue
  static const String deliveryGroupSortBalanced = 'balanced';
  static const String deliveryGroupSortTimeFirst = 'timeFirst';
  static const String deliveryGroupSortDistanceFirst = 'distanceFirst';
  static const String deliveryGroupSortRecentFirst = 'recentFirst';

  /// SignalR hub for realtime notifications (no /api prefix).
  static String get notificationsHubUrl {
    final api = baseUrl;
    if (api.endsWith('/api')) {
      return '${api.substring(0, api.length - 4)}/hubs/notifications';
    }
    final uri = Uri.parse(api);
    return '${uri.scheme}://${uri.host}${uri.hasPort ? ':${uri.port}' : ''}/hubs/notifications';
  }

  // ============== UPLOAD ENDPOINTS ==============
  static const String upload = '/upload';
  static const String uploadTest = '/upload/test';

  // ============== USER PROFILE ENDPOINTS ==============
  static const String updateCurrentUser = '/users/current-user';
  static const String currentUserImages = '/users/current-user/images';
  static const String currentUserPrimaryImage =
      '/users/current-user/images/primary';
  static String currentUserImageById(String imageId) =>
      '/users/current-user/images/$imageId';

  // ============== NOTIFICATION ENDPOINTS ==============
  static const String notificationsMe = '/notifications/me';
  static String notificationsByOrder(String orderId) =>
      '/notifications/me/order/$orderId';
  static String notificationById(String notificationId) =>
      '/notifications/$notificationId';

  // ============== TIMEOUTS ==============
  static const Duration connectionTimeout = Duration(seconds: 30);
  static const Duration receiveTimeout = Duration(seconds: 30);
  static const Duration sendTimeout = Duration(seconds: 30);
}
