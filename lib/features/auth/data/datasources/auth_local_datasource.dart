import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/error/exceptions.dart';
import '../models/user_model.dart';

/// Auth Local Data Source - Data Layer
///
/// Handles all local storage operations related to authentication.
/// Uses flutter_secure_storage for secure token storage.
abstract class AuthLocalDataSource {
  /// Cache the auth tokens and user data
  Future<void> cacheAuthData({
    required String accessToken,
    required String refreshToken,
    required DateTime expiresAt,
    required UserModel user,
  });

  /// Get cached access token
  Future<String?> getAccessToken();

  /// Get cached refresh token
  Future<String?> getRefreshToken();

  /// Get cached user
  Future<UserModel?> getCachedUser();

  /// Get token expiry time
  Future<DateTime?> getTokenExpiry();

  /// Clear all cached auth data (logout)
  Future<void> clearAuthData();

  /// Check if user is logged in (has valid token)
  Future<bool> isLoggedIn();
}

/// Implementation of AuthLocalDataSource
class AuthLocalDataSourceImpl implements AuthLocalDataSource {
  final FlutterSecureStorage _secureStorage;

  AuthLocalDataSourceImpl({required FlutterSecureStorage secureStorage})
    : _secureStorage = secureStorage;

  @override
  Future<void> cacheAuthData({
    required String accessToken,
    required String refreshToken,
    required DateTime expiresAt,
    required UserModel user,
  }) async {
    try {
      await Future.wait([
        _secureStorage.write(
          key: AppConstants.accessTokenKey,
          value: accessToken,
        ),
        _secureStorage.write(
          key: AppConstants.refreshTokenKey,
          value: refreshToken,
        ),
        _secureStorage.write(
          key: AppConstants.tokenExpiryKey,
          value: expiresAt.toIso8601String(),
        ),
        _secureStorage.write(
          key: AppConstants.userKey,
          value: jsonEncode(user.toJson()),
        ),
      ]);
    } catch (e) {
      throw CacheException(message: 'Không thể lưu thông tin đăng nhập: $e');
    }
  }

  @override
  Future<String?> getAccessToken() async {
    try {
      return await _secureStorage.read(key: AppConstants.accessTokenKey);
    } catch (e) {
      throw CacheException(message: 'Không thể đọc token: $e');
    }
  }

  @override
  Future<String?> getRefreshToken() async {
    try {
      return await _secureStorage.read(key: AppConstants.refreshTokenKey);
    } catch (e) {
      throw CacheException(message: 'Không thể đọc refresh token: $e');
    }
  }

  @override
  Future<UserModel?> getCachedUser() async {
    try {
      final userJson = await _secureStorage.read(key: AppConstants.userKey);
      if (userJson == null) return null;

      final userMap = jsonDecode(userJson) as Map<String, dynamic>;
      return UserModel.fromJson(userMap);
    } catch (e) {
      throw CacheException(message: 'Không thể đọc thông tin người dùng: $e');
    }
  }

  @override
  Future<DateTime?> getTokenExpiry() async {
    try {
      final expiryString = await _secureStorage.read(
        key: AppConstants.tokenExpiryKey,
      );
      if (expiryString == null) return null;
      return DateTime.parse(expiryString);
    } catch (e) {
      throw CacheException(message: 'Không thể đọc thời hạn token: $e');
    }
  }

  @override
  Future<void> clearAuthData() async {
    try {
      await Future.wait([
        _secureStorage.delete(key: AppConstants.accessTokenKey),
        _secureStorage.delete(key: AppConstants.refreshTokenKey),
        _secureStorage.delete(key: AppConstants.tokenExpiryKey),
        _secureStorage.delete(key: AppConstants.userKey),
      ]);
    } catch (e) {
      throw CacheException(message: 'Không thể xóa dữ liệu đăng nhập: $e');
    }
  }

  @override
  Future<bool> isLoggedIn() async {
    try {
      final token = await getAccessToken();
      if (token == null) return false;

      final expiry = await getTokenExpiry();
      if (expiry == null) return false;

      // Check if token is expired
      return DateTime.now().isBefore(expiry);
    } catch (e) {
      return false;
    }
  }
}
