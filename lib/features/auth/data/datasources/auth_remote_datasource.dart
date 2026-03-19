import 'package:dio/dio.dart';
import '../../../../core/constants/api_constants.dart';
import '../../../../core/error/exceptions.dart';
import '../models/auth_response_model.dart';
import '../models/user_model.dart';

/// Auth Remote Data Source - Data Layer
///
/// Handles all API calls related to authentication.
/// This is the interface contract.
abstract class AuthRemoteDataSource {
  /// Login with email and password
  Future<AuthResponseModel> login({
    required String email,
    required String password,
  });

  /// Refresh access token using refresh token
  Future<AuthResponseModel> refreshToken({required String refreshToken});

  /// Logout (invalidate refresh token)
  Future<void> logout({required String refreshToken});

  /// Logout from all devices
  Future<void> logoutAll({required String accessToken});
  // ============== USER PROFILE ==============

  /// Get current user profile
  Future<UserModel> getCurrentUser();

  /// Update current user profile
  Future<UserModel> updateProfile({String? fullName, String? phone});
}

/// Implementation of AuthRemoteDataSource
class AuthRemoteDataSourceImpl implements AuthRemoteDataSource {
  final Dio _dio;

  AuthRemoteDataSourceImpl({required Dio dio}) : _dio = dio;

  @override
  Future<AuthResponseModel> login({
    required String email,
    required String password,
  }) async {
    try {
      final response = await _dio.post(
        ApiConstants.login,
        data: LoginRequestModel(email: email, password: password).toJson(),
      );

      return _handleAuthResponse(response);
    } on DioException catch (e) {
      throw _handleDioError(e, 'Đăng nhập thất bại');
    }
  }

  @override
  Future<AuthResponseModel> refreshToken({required String refreshToken}) async {
    try {
      final response = await _dio.post(
        ApiConstants.refreshToken,
        data: RefreshTokenRequestModel(refreshToken: refreshToken).toJson(),
      );

      return _handleAuthResponse(response);
    } on DioException catch (e) {
      throw _handleDioError(e, 'Làm mới token thất bại');
    }
  }

  @override
  Future<void> logout({required String refreshToken}) async {
    try {
      final response = await _dio.post(
        ApiConstants.logout,
        data: LogoutRequestModel(refreshToken: refreshToken).toJson(),
      );

      _handleApiResponse(response, 'Đăng xuất thất bại');
    } on DioException catch (e) {
      throw _handleDioError(e, 'Đăng xuất thất bại');
    }
  }

  @override
  Future<void> logoutAll({required String accessToken}) async {
    try {
      final response = await _dio.post(
        ApiConstants.logoutAll,
        options: Options(headers: {'Authorization': 'Bearer $accessToken'}),
      );

      _handleApiResponse(response, 'Đăng xuất thất bại');
    } on DioException catch (e) {
      throw _handleDioError(e, 'Đăng xuất khỏi tất cả thiết bị thất bại');
    }
  }
  // ============== Helper Methods ==============

  AuthResponseModel _handleAuthResponse(Response response) {
    if (response.statusCode == 200 || response.statusCode == 201) {
      final apiResponse = response.data as Map<String, dynamic>;

      if (apiResponse['success'] == true) {
        final data = apiResponse['data'];
        if (data is! Map<String, dynamic>) {
          throw const AuthenticationException(
            message: 'Phản hồi đăng nhập không hợp lệ từ máy chủ',
          );
        }
        return AuthResponseModel.fromJson(apiResponse);
      } else {
        throw AuthenticationException(
          message: _extractBackendMessage(apiResponse) ?? 'Thao tác thất bại',
        );
      }
    } else {
      throw ServerException(
        message: 'Thao tác thất bại',
        statusCode: response.statusCode,
      );
    }
  }

  void _handleApiResponse(Response response, String defaultError) {
    if (response.statusCode == 200) {
      final apiResponse = response.data as Map<String, dynamic>;

      if (apiResponse['success'] != true) {
        throw ServerException(
          message: apiResponse['message'] ?? defaultError,
          statusCode: response.statusCode,
        );
      }
    } else {
      throw ServerException(
        message: defaultError,
        statusCode: response.statusCode,
      );
    }
  }

  Exception _handleDioError(DioException e, String defaultMessage) {
    if (e.response != null) {
      final data = e.response?.data;
      final message = _extractBackendMessage(data) ?? defaultMessage;

      final statusCode = e.response?.statusCode;

      // 401 Unauthorized - token expired or invalid
      if (statusCode == 401) {
        return AuthenticationException(
          message: message,
          statusCode: statusCode,
        );
      }

      // 409 Conflict - email already exists
      if (statusCode == 409) {
        return AuthenticationException(
          message: message,
          statusCode: statusCode,
        );
      }

      return AuthenticationException(message: message, statusCode: statusCode);
    }

    return NetworkException(message: 'Không có kết nối mạng');
  }

  String? _extractBackendMessage(dynamic data) {
    if (data is! Map<String, dynamic>) {
      return null;
    }

    final message = data['message'];
    if (message is String && message.trim().isNotEmpty) {
      return message;
    }

    final title = data['title'];
    if (title is String && title.trim().isNotEmpty) {
      return title;
    }

    final errors = data['errors'];
    if (errors is List && errors.isNotEmpty) {
      final first = errors.first;
      if (first is String && first.trim().isNotEmpty) {
        return first;
      }
    }

    if (errors is Map<String, dynamic> && errors.isNotEmpty) {
      for (final value in errors.values) {
        if (value is List && value.isNotEmpty) {
          final first = value.first;
          if (first is String && first.trim().isNotEmpty) {
            return first;
          }
        }
      }
    }

    return null;
  }

  // ============== USER PROFILE ==============

  @override
  Future<UserModel> getCurrentUser() async {
    try {
      final response = await _dio.get(ApiConstants.currentUser);
      return _handleUserResponse(response);
    } on DioException catch (e) {
      throw _handleDioError(e, 'Không thể tải thông tin người dùng');
    }
  }

  @override
  Future<UserModel> updateProfile({String? fullName, String? phone}) async {
    try {
      final response = await _dio.put(
        ApiConstants.updateCurrentUser,
        data: UpdateProfileRequestModel(
          fullName: fullName,
          phone: phone,
        ).toJson(),
      );
      return _handleUserResponse(response);
    } on DioException catch (e) {
      throw _handleDioError(e, 'Cập nhật thông tin thất bại');
    }
  }

  UserModel _handleUserResponse(Response response) {
    if (response.statusCode == 200) {
      final apiResponse = response.data as Map<String, dynamic>;

      if (apiResponse['success'] == true) {
        final data = apiResponse['data'] as Map<String, dynamic>;
        return UserModel.fromJson(data);
      } else {
        throw ServerException(
          message: apiResponse['message'] ?? 'Thao tác thất bại',
        );
      }
    } else {
      throw ServerException(
        message: 'Thao tác thất bại',
        statusCode: response.statusCode,
      );
    }
  }
}
