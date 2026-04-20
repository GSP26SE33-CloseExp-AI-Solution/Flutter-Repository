import 'package:dio/dio.dart';

import '../../../../core/constants/api_constants.dart';
import '../../../../core/error/exceptions.dart';
import '../models/notification_item_model.dart';

abstract class NotificationRemoteDataSource {
  Future<List<NotificationItemModel>> getMyNotifications();

  Future<List<NotificationItemModel>> getOrderNotifications(String orderId);

  Future<NotificationItemModel> markAsRead(String notificationId);
}

class NotificationRemoteDataSourceImpl implements NotificationRemoteDataSource {
  final Dio dio;

  NotificationRemoteDataSourceImpl({required this.dio});

  @override
  Future<List<NotificationItemModel>> getMyNotifications() async {
    try {
      final response = await dio.get(ApiConstants.notificationsMe);
      return _handleListResponse(response);
    } on DioException catch (e) {
      throw _mapDioException(e, 'Không thể tải danh sách thông báo');
    }
  }

  @override
  Future<List<NotificationItemModel>> getOrderNotifications(
    String orderId,
  ) async {
    try {
      final response = await dio.get(
        ApiConstants.notificationsByOrder(orderId),
      );
      return _handleListResponse(response);
    } on DioException catch (e) {
      throw _mapDioException(e, 'Không thể tải luồng thông báo đơn hàng');
    }
  }

  @override
  Future<NotificationItemModel> markAsRead(String notificationId) async {
    try {
      final response = await dio.put(
        ApiConstants.notificationById(notificationId),
        data: {'isRead': true},
      );
      return _handleSingleResponse(response);
    } on DioException catch (e) {
      throw _mapDioException(e, 'Không thể cập nhật trạng thái đã đọc');
    }
  }

  List<NotificationItemModel> _handleListResponse(Response response) {
    final body = response.data;
    if (response.statusCode == 200 && body is Map<String, dynamic>) {
      if (body['success'] == true) {
        final items = body['data'] as List<dynamic>? ?? const [];
        return items
            .whereType<Map<String, dynamic>>()
            .map(NotificationItemModel.fromJson)
            .toList();
      }

      throw ServerException(
        message: _extractErrorMessage(body) ?? 'Yêu cầu thất bại',
        statusCode: response.statusCode,
      );
    }

    throw ServerException(
      message: 'Yêu cầu thất bại',
      statusCode: response.statusCode,
    );
  }

  NotificationItemModel _handleSingleResponse(Response response) {
    final body = response.data;
    if (response.statusCode == 200 && body is Map<String, dynamic>) {
      if (body['success'] == true) {
        final data = body['data'];
        if (data is Map<String, dynamic>) {
          return NotificationItemModel.fromJson(data);
        }

        throw const ServerException(
          message: 'Dữ liệu thông báo không hợp lệ từ máy chủ',
        );
      }

      throw ServerException(
        message: _extractErrorMessage(body) ?? 'Yêu cầu thất bại',
        statusCode: response.statusCode,
      );
    }

    throw ServerException(
      message: 'Yêu cầu thất bại',
      statusCode: response.statusCode,
    );
  }

  AppException _mapDioException(DioException error, String fallbackMessage) {
    final existing = error.error;
    if (existing is AppException) {
      return existing;
    }

    final statusCode = error.response?.statusCode;
    final message =
        _extractErrorMessage(error.response?.data) ?? fallbackMessage;

    if (statusCode == 401) {
      return UnauthorizedException(message: message, statusCode: statusCode);
    }

    if (statusCode == 403) {
      return ForbiddenException(message: message, statusCode: statusCode);
    }

    if (error.type == DioExceptionType.connectionError ||
        error.type == DioExceptionType.connectionTimeout ||
        error.type == DioExceptionType.sendTimeout ||
        error.type == DioExceptionType.receiveTimeout) {
      return NetworkException(message: message);
    }

    return ServerException(message: message, statusCode: statusCode);
  }

  String? _extractErrorMessage(dynamic data) {
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

    if (errors is Map<String, dynamic>) {
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
}
