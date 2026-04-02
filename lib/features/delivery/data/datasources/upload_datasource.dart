import 'dart:io';
import 'package:dio/dio.dart';
import '../../../../core/constants/api_constants.dart';
import '../../../../core/error/exceptions.dart';

/// Upload Data Source - Data Layer
///
/// Handles file upload API calls.
abstract class UploadDataSource {
  /// Upload a file and return the uploaded file URL
  Future<UploadResult> uploadFile(File file);

  /// Upload a file from bytes and return the uploaded file URL
  Future<UploadResult> uploadFileBytes({
    required List<int> bytes,
    required String fileName,
    required String mimeType,
  });
}

/// Implementation of UploadDataSource
class UploadDataSourceImpl implements UploadDataSource {
  final Dio _dio;

  UploadDataSourceImpl({required Dio dio}) : _dio = dio;

  @override
  Future<UploadResult> uploadFile(File file) async {
    try {
      final fileName = file.path.split('/').last;
      final mimeType = _getMimeType(fileName);

      final formData = FormData.fromMap({
        'file': await MultipartFile.fromFile(
          file.path,
          filename: fileName,
          contentType: DioMediaType.parse(mimeType),
        ),
      });

      final response = await _dio.post(
        // Chứng minh giao hàng: dùng DeliveryRemoteDataSource.uploadDeliveryProofImage
        // (POST /delivery/orders/{id}/proof-image). Đây là /upload/test (generic).
        ApiConstants.uploadTest,
        data: formData,
        options: Options(contentType: 'multipart/form-data'),
      );

      return _handleUploadResponse(response);
    } on DioException catch (e) {
      throw _handleDioError(e, 'Tải file lên thất bại');
    } catch (e) {
      throw ServerException(message: 'Tải file lên thất bại: $e');
    }
  }

  @override
  Future<UploadResult> uploadFileBytes({
    required List<int> bytes,
    required String fileName,
    required String mimeType,
  }) async {
    try {
      final formData = FormData.fromMap({
        'file': MultipartFile.fromBytes(
          bytes,
          filename: fileName,
          contentType: DioMediaType.parse(mimeType),
        ),
      });

      final response = await _dio.post(
        // Generic test upload — không dùng cho proof giao hàng (xem DeliveryRemoteDataSource).
        ApiConstants.uploadTest,
        data: formData,
        options: Options(contentType: 'multipart/form-data'),
      );

      return _handleUploadResponse(response);
    } on DioException catch (e) {
      throw _handleDioError(e, 'Tải file lên thất bại');
    } catch (e) {
      throw ServerException(message: 'Tải file lên thất bại: $e');
    }
  }

  UploadResult _handleUploadResponse(Response response) {
    if (response.statusCode == 200) {
      final apiResponse = response.data as Map<String, dynamic>;

      if (apiResponse['success'] == true) {
        final data = apiResponse['data'] as Map<String, dynamic>;
        return UploadResult(
          key: data['key'] as String? ?? '',
          url: data['url'] as String? ?? '',
        );
      } else {
        throw ServerException(
          message: apiResponse['message'] ?? 'Tải file lên thất bại',
        );
      }
    } else {
      throw ServerException(
        message: 'Tải file lên thất bại',
        statusCode: response.statusCode,
      );
    }
  }

  Exception _handleDioError(DioException e, String defaultMessage) {
    if (e.response != null) {
      final data = e.response?.data;
      String message = defaultMessage;

      if (data is Map<String, dynamic>) {
        message = data['message'] ?? message;
      }

      return ServerException(
        message: message,
        statusCode: e.response?.statusCode,
      );
    }

    return NetworkException(message: 'Không có kết nối mạng');
  }

  String _getMimeType(String fileName) {
    final extension = fileName.split('.').last.toLowerCase();
    switch (extension) {
      case 'jpg':
      case 'jpeg':
        return 'image/jpeg';
      case 'png':
        return 'image/png';
      case 'gif':
        return 'image/gif';
      case 'webp':
        return 'image/webp';
      case 'bmp':
        return 'image/bmp';
      default:
        return 'application/octet-stream';
    }
  }
}

/// Result from file upload
class UploadResult {
  final String key;
  final String url;

  const UploadResult({required this.key, required this.url});
}
