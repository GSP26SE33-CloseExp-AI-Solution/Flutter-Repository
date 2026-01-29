/// API Constants for CloseExp Delivery Staff App
///
/// This file contains all API-related constants including base URLs,
/// endpoints, and timeout configurations.
library;

class ApiConstants {
  ApiConstants._();

  // Base URL - Change this for different environments
  static const String baseUrl = 'http://10.0.2.2:5000/api'; // Android Emulator
  // static const String baseUrl = 'http://localhost:5000/api'; // iOS Simulator
  // static const String baseUrl = 'https://your-production-url.com/api'; // Production

  // Auth Endpoints
  static const String login = '/auth/login';
  static const String register = '/auth/register';
  static const String refreshToken = '/auth/refresh-token';
  static const String logout = '/auth/logout';

  // Timeouts
  static const Duration connectionTimeout = Duration(seconds: 30);
  static const Duration receiveTimeout = Duration(seconds: 30);
  static const Duration sendTimeout = Duration(seconds: 30);
}
