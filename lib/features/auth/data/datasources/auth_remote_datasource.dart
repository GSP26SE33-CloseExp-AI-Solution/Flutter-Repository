import 'package:dio/dio.dart';
import '../../../../core/constants/api_constants.dart';
import '../../../../core/error/exceptions.dart';
import '../models/auth_response_model.dart';

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

      if (response.statusCode == 200) {
        final apiResponse = response.data as Map<String, dynamic>;

        // Check if the API response indicates success
        if (apiResponse['success'] == true) {
          return AuthResponseModel.fromJson(apiResponse);
        } else {
          throw AuthenticationException(
            message: apiResponse['message'] ?? 'Đăng nhập thất bại',
          );
        }
      } else {
        throw ServerException(
          message: 'Đăng nhập thất bại',
          statusCode: response.statusCode,
        );
      }
    } on DioException catch (e) {
      if (e.response != null) {
        final data = e.response?.data;
        String message = 'Đăng nhập thất bại';

        if (data is Map<String, dynamic>) {
          message = data['message'] ?? message;
        }

        throw AuthenticationException(
          message: message,
          statusCode: e.response?.statusCode,
        );
      }
      rethrow;
    }
  }
}
