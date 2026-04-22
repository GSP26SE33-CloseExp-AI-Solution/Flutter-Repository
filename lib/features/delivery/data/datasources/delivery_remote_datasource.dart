import 'dart:io';

import 'package:dio/dio.dart';
import '../../../../core/constants/api_constants.dart';
import '../../../../core/error/exceptions.dart';
import '../models/delivery_group_model.dart';
import '../models/delivery_order_model.dart';
import '../models/delivery_route_plan_model.dart';
import '../models/delivery_stats_model.dart';

/// Delivery Remote Data Source - Data Layer
///
/// Handles all API calls related to delivery operations.
abstract class DeliveryRemoteDataSource {
  // Delivery Groups
  Future<List<DeliveryGroupSummaryModel>> getAvailableGroups({
    DateTime? deliveryDate,
  });
  Future<PaginatedGroupsResponse> getMyGroups({
    int page = 1,
    int pageSize = 10,
    String? status,
    DateTime? deliveryDate,
    String? sortBy,
    double? currentLatitude,
    double? currentLongitude,
  });
  Future<List<DeliveryGroupSummaryModel>> getMyWorkQueue({
    int limit = 10,
    String? status,
    DateTime? deliveryDate,
    String? sortBy,
    double? currentLatitude,
    double? currentLongitude,
  });
  Future<DeliveryGroupModel> getDeliveryGroupById(String groupId);
  Future<DeliveryGroupModel> acceptDeliveryGroup(
    String groupId, {
    String? notes,
  });
  Future<DeliveryGroupModel> startDelivery(String groupId, {String? notes});
  Future<DeliveryGroupModel> completeDeliveryGroup(String groupId);

  Future<DeliveryRoutePlanModel> computeDeliveryRoutePlan(
    String groupId, {
    double? startLatitude,
    double? startLongitude,
    String metric = 'distance',
    bool skipPickupLeg = false,
  });

  // Delivery Orders
  /// Khi có [groupId], BE sẽ scope item theo đúng nhóm → tránh việc đơn đa-siêu-thị
  /// trả về item thuộc nhóm khác mà shipper cũng đang sở hữu.
  Future<DeliveryOrderModel> getOrderDetails(String orderId, {String? groupId});

  /// BE: POST multipart `file` → dùng URL trả về cho [confirmDelivery].
  Future<String> uploadDeliveryProofImage(String orderId, String localFilePath);

  /// BE [ConfirmDeliveryRequestDto]: proofImageUrl + verificationCode là bắt buộc.
  Future<DeliveryOrderModel> confirmDelivery(
    String orderId, {
    required String proofImageUrl,
    required String verificationCode,
    String? notes,
    String? deliveryGroupId,
  });
  Future<DeliveryOrderModel> reportDeliveryFailure(
    String orderId, {
    required String failureReason,
    String? notes,
    List<String>? orderItemIds,
    String? deliveryGroupId,
  });

  // History & Stats
  Future<PaginatedHistoryResponse> getDeliveryHistory({
    int page = 1,
    int pageSize = 20,
    DateTime? fromDate,
    DateTime? toDate,
    String? status,
  });
  Future<DeliveryStatsModel> getDeliveryStats();
}

/// Implementation of DeliveryRemoteDataSource
class DeliveryRemoteDataSourceImpl implements DeliveryRemoteDataSource {
  final Dio _dio;

  DeliveryRemoteDataSourceImpl({required Dio dio}) : _dio = dio;

  @override
  Future<List<DeliveryGroupSummaryModel>> getAvailableGroups({
    DateTime? deliveryDate,
  }) async {
    try {
      final queryParams = <String, dynamic>{};
      if (deliveryDate != null) {
        queryParams['deliveryDate'] = deliveryDate.toIso8601String().split(
          'T',
        )[0];
      }

      final response = await _dio.get(
        ApiConstants.deliveryGroupsAvailable,
        queryParameters: queryParams.isNotEmpty ? queryParams : null,
      );
      return _handleListResponse<DeliveryGroupSummaryModel>(
        response,
        DeliveryGroupSummaryModel.fromJson,
      );
    } on DioException {
      rethrow;
    } catch (e) {
      throw ServerException(message: 'Không thể tải danh sách giao hàng: $e');
    }
  }

  @override
  Future<PaginatedGroupsResponse> getMyGroups({
    int page = 1,
    int pageSize = 10,
    String? status,
    DateTime? deliveryDate,
    String? sortBy,
    double? currentLatitude,
    double? currentLongitude,
  }) async {
    try {
      final queryParams = <String, dynamic>{
        'pageNumber': page,
        'pageSize': pageSize,
      };
      if (status != null) queryParams['status'] = status;
      if (deliveryDate != null) {
        queryParams['deliveryDate'] = deliveryDate.toIso8601String().split(
          'T',
        )[0];
      }
      if (sortBy != null && sortBy.trim().isNotEmpty) {
        queryParams['sortBy'] = sortBy.trim();
      }
      if (currentLatitude != null) {
        queryParams['currentLatitude'] = currentLatitude;
      }
      if (currentLongitude != null) {
        queryParams['currentLongitude'] = currentLongitude;
      }

      final response = await _dio.get(
        ApiConstants.deliveryGroupsMy,
        queryParameters: queryParams,
      );
      return _handlePaginatedResponse(
        response,
        DeliveryGroupSummaryModel.fromJson,
        pageSize,
      );
    } on DioException {
      rethrow;
    } catch (e) {
      throw ServerException(message: 'Không thể tải danh sách đơn hàng: $e');
    }
  }

  @override
  Future<List<DeliveryGroupSummaryModel>> getMyWorkQueue({
    int limit = 10,
    String? status,
    DateTime? deliveryDate,
    String? sortBy,
    double? currentLatitude,
    double? currentLongitude,
  }) async {
    try {
      final queryParams = <String, dynamic>{'limit': limit};
      if (status != null) queryParams['status'] = status;
      if (deliveryDate != null) {
        queryParams['deliveryDate'] = deliveryDate.toIso8601String().split(
          'T',
        )[0];
      }
      if (sortBy != null && sortBy.trim().isNotEmpty) {
        queryParams['sortBy'] = sortBy.trim();
      }
      if (currentLatitude != null) {
        queryParams['currentLatitude'] = currentLatitude;
      }
      if (currentLongitude != null) {
        queryParams['currentLongitude'] = currentLongitude;
      }

      final response = await _dio.get(
        ApiConstants.deliveryGroupsMyWorkQueue,
        queryParameters: queryParams,
      );
      return _handleListResponse<DeliveryGroupSummaryModel>(
        response,
        DeliveryGroupSummaryModel.fromJson,
      );
    } on DioException {
      rethrow;
    } catch (e) {
      throw ServerException(message: 'Không thể tải work queue: $e');
    }
  }

  @override
  Future<DeliveryGroupModel> getDeliveryGroupById(String groupId) async {
    try {
      final response = await _dio.get(ApiConstants.deliveryGroupById(groupId));
      return _handleSingleResponse(response, DeliveryGroupModel.fromJson);
    } on DioException {
      rethrow;
    } catch (e) {
      throw ServerException(message: 'Không thể tải thông tin nhóm giao: $e');
    }
  }

  @override
  Future<DeliveryGroupModel> acceptDeliveryGroup(
    String groupId, {
    String? notes,
  }) async {
    try {
      final response = await _dio.post(
        ApiConstants.acceptDeliveryGroup(groupId),
        data: {'notes': notes},
      );
      return _handleSingleResponse(response, DeliveryGroupModel.fromJson);
    } on DioException {
      rethrow;
    } catch (e) {
      throw ServerException(message: 'Không thể nhận đơn giao hàng: $e');
    }
  }

  @override
  Future<DeliveryGroupModel> startDelivery(
    String groupId, {
    String? notes,
  }) async {
    try {
      final response = await _dio.post(
        ApiConstants.startDeliveryGroup(groupId),
        data: {'notes': notes},
      );
      return _handleSingleResponse(response, DeliveryGroupModel.fromJson);
    } on DioException {
      rethrow;
    } catch (e) {
      throw ServerException(message: 'Không thể bắt đầu giao hàng: $e');
    }
  }

  @override
  Future<DeliveryGroupModel> completeDeliveryGroup(String groupId) async {
    try {
      final response = await _dio.post(
        ApiConstants.completeDeliveryGroup(groupId),
      );
      return _handleSingleResponse(response, DeliveryGroupModel.fromJson);
    } on DioException {
      rethrow;
    } catch (e) {
      throw ServerException(message: 'Không thể hoàn thành nhóm giao: $e');
    }
  }

  @override
  Future<DeliveryRoutePlanModel> computeDeliveryRoutePlan(
    String groupId, {
    double? startLatitude,
    double? startLongitude,
    String metric = 'distance',
    bool skipPickupLeg = false,
  }) async {
    try {
      final data = <String, dynamic>{
        'metric': metric,
        if (startLatitude != null) 'startLatitude': startLatitude,
        if (startLongitude != null) 'startLongitude': startLongitude,
        if (skipPickupLeg) 'skipPickupLeg': true,
      };
      final response = await _dio.post(
        ApiConstants.deliveryGroupRoutePlan(groupId),
        data: data,
      );
      return _handleSingleResponse(response, DeliveryRoutePlanModel.fromJson);
    } on DioException {
      rethrow;
    } catch (e) {
      throw ServerException(message: 'Không thể tính lộ trình: $e');
    }
  }

  @override
  Future<DeliveryOrderModel> getOrderDetails(
    String orderId, {
    String? groupId,
  }) async {
    try {
      final trimmedGroupId = groupId?.trim();
      final queryParameters = <String, dynamic>{};
      if (trimmedGroupId != null && trimmedGroupId.isNotEmpty) {
        queryParameters['groupId'] = trimmedGroupId;
      }
      final response = await _dio.get(
        ApiConstants.deliveryOrderById(orderId),
        queryParameters: queryParameters.isEmpty ? null : queryParameters,
      );
      return _handleSingleResponse(response, DeliveryOrderModel.fromJson);
    } on DioException {
      rethrow;
    } catch (e) {
      throw ServerException(message: 'Không thể tải thông tin đơn hàng: $e');
    }
  }

  @override
  Future<String> uploadDeliveryProofImage(
    String orderId,
    String localFilePath,
  ) async {
    try {
      final file = File(localFilePath);
      final fileName = file.path.replaceAll(r'\', '/').split('/').last;
      final mimeType = _mimeTypeForFileName(fileName);
      final formData = FormData.fromMap({
        'file': await MultipartFile.fromFile(
          file.path,
          filename: fileName,
          contentType: DioMediaType.parse(mimeType),
        ),
      });
      final response = await _dio.post(
        ApiConstants.deliveryOrderProofImage(orderId),
        data: formData,
        options: Options(contentType: 'multipart/form-data'),
      );
      if (response.statusCode == 200) {
        final apiResponse = response.data as Map<String, dynamic>;
        if (apiResponse['success'] == true) {
          final data = apiResponse['data'] as Map<String, dynamic>;
          final url = (data['proofImageUrl'] as String?)?.trim() ?? '';
          if (url.isEmpty) {
            throw ServerException(
              message: 'Phản hồi upload thiếu proofImageUrl',
            );
          }
          return url;
        }
        throw ServerException(
          message: apiResponse['message'] ?? 'Upload ảnh chứng minh thất bại',
        );
      }
      throw ServerException(
        message: 'Upload ảnh chứng minh thất bại',
        statusCode: response.statusCode,
      );
    } on DioException {
      rethrow;
    } catch (e) {
      if (e is ServerException) rethrow;
      throw ServerException(message: 'Upload ảnh chứng minh thất bại: $e');
    }
  }

  @override
  Future<DeliveryOrderModel> confirmDelivery(
    String orderId, {
    required String proofImageUrl,
    required String verificationCode,
    String? notes,
    String? deliveryGroupId,
  }) async {
    try {
      final trimmedGroupId = deliveryGroupId?.trim();
      final data = <String, dynamic>{
        'proofImageUrl': proofImageUrl.trim(),
        'verificationCode': verificationCode.trim(),
        if (notes != null && notes.trim().isNotEmpty) 'notes': notes.trim(),
        if (trimmedGroupId != null && trimmedGroupId.isNotEmpty)
          'deliveryGroupId': trimmedGroupId,
      };
      final response = await _dio.post(
        ApiConstants.confirmDelivery(orderId),
        data: data,
      );
      // Backend returns DeliveryOrderResponseDto after confirm action.
      return _handleSingleResponse(response, DeliveryOrderModel.fromJson);
    } on DioException {
      rethrow;
    } catch (e) {
      throw ServerException(message: 'Không thể xác nhận giao hàng: $e');
    }
  }

  @override
  Future<DeliveryOrderModel> reportDeliveryFailure(
    String orderId, {
    required String failureReason,
    String? notes,
    List<String>? orderItemIds,
    String? deliveryGroupId,
  }) async {
    try {
      final trimmedGroupId = deliveryGroupId?.trim();
      final payload = <String, dynamic>{
        'failureReason': failureReason,
        if (notes != null && notes.trim().isNotEmpty) 'notes': notes.trim(),
        if (orderItemIds != null && orderItemIds.isNotEmpty)
          'orderItemIds': orderItemIds,
        if (trimmedGroupId != null && trimmedGroupId.isNotEmpty)
          'deliveryGroupId': trimmedGroupId,
      };
      final response = await _dio.post(
        ApiConstants.reportDeliveryFailure(orderId),
        data: payload,
      );
      // Backend returns DeliveryOrderResponseDto after failure report.
      return _handleSingleResponse(response, DeliveryOrderModel.fromJson);
    } on DioException {
      rethrow;
    } catch (e) {
      throw ServerException(message: 'Không thể báo cáo thất bại: $e');
    }
  }

  @override
  Future<PaginatedHistoryResponse> getDeliveryHistory({
    int page = 1,
    int pageSize = 20,
    DateTime? fromDate,
    DateTime? toDate,
    String? status,
  }) async {
    try {
      final queryParams = <String, dynamic>{
        'pageNumber': page,
        'pageSize': pageSize,
      };
      if (fromDate != null) {
        queryParams['fromDate'] = fromDate.toIso8601String().split('T')[0];
      }
      if (toDate != null) {
        queryParams['toDate'] = toDate.toIso8601String().split('T')[0];
      }
      if (status != null) queryParams['status'] = status;

      final response = await _dio.get(
        ApiConstants.deliveryHistory,
        queryParameters: queryParams,
      );
      return _handlePaginatedHistoryResponse(
        response,
        DeliveryRecordModel.fromJson,
        pageSize,
      );
    } on DioException {
      rethrow;
    } catch (e) {
      throw ServerException(message: 'Không thể tải lịch sử giao hàng: $e');
    }
  }

  @override
  Future<DeliveryStatsModel> getDeliveryStats() async {
    try {
      final response = await _dio.get(ApiConstants.deliveryStats);
      return _handleSingleResponse(response, DeliveryStatsModel.fromJson);
    } on DioException {
      rethrow;
    } catch (e) {
      throw ServerException(message: 'Không thể tải thống kê: $e');
    }
  }

  // ============== HELPER METHODS ==============

  T _handleSingleResponse<T>(
    Response response,
    T Function(Map<String, dynamic>) fromJson,
  ) {
    if (response.statusCode == 200) {
      final apiResponse = response.data as Map<String, dynamic>;
      if (apiResponse['success'] == true) {
        final data = apiResponse['data'] as Map<String, dynamic>;
        return fromJson(data);
      }
      throw ServerException(
        message: apiResponse['message'] ?? 'Yêu cầu thất bại',
      );
    }
    throw ServerException(
      message: 'Yêu cầu thất bại',
      statusCode: response.statusCode,
    );
  }

  List<T> _handleListResponse<T>(
    Response response,
    T Function(Map<String, dynamic>) fromJson,
  ) {
    if (response.statusCode == 200) {
      final apiResponse = response.data as Map<String, dynamic>;
      if (apiResponse['success'] == true) {
        final dataList = apiResponse['data'] as List<dynamic>? ?? [];
        return dataList
            .map((e) => fromJson(e as Map<String, dynamic>))
            .toList();
      }
      throw ServerException(
        message: apiResponse['message'] ?? 'Yêu cầu thất bại',
      );
    }
    throw ServerException(
      message: 'Yêu cầu thất bại',
      statusCode: response.statusCode,
    );
  }

  PaginatedGroupsResponse _handlePaginatedResponse(
    Response response,
    DeliveryGroupSummaryModel Function(Map<String, dynamic>) fromJson,
    int requestedPageSize,
  ) {
    if (response.statusCode == 200) {
      final apiResponse = response.data as Map<String, dynamic>;
      if (apiResponse['success'] == true) {
        final data = apiResponse['data'] as Map<String, dynamic>;
        final items = data['items'] as List<dynamic>? ?? [];
        final totalResult = data['totalResult'] as int? ?? 0;
        final currentPage = data['page'] as int? ?? 1;
        final pageSize = data['pageSize'] as int? ?? requestedPageSize;
        final totalPages = pageSize > 0 ? (totalResult / pageSize).ceil() : 1;

        return PaginatedGroupsResponse(
          groups: items
              .map((e) => fromJson(e as Map<String, dynamic>))
              .toList(),
          currentPage: currentPage,
          totalPages: totalPages,
          totalCount: totalResult,
          hasNextPage: currentPage < totalPages,
        );
      }
      throw ServerException(
        message: apiResponse['message'] ?? 'Yêu cầu thất bại',
      );
    }
    throw ServerException(
      message: 'Yêu cầu thất bại',
      statusCode: response.statusCode,
    );
  }

  PaginatedHistoryResponse _handlePaginatedHistoryResponse(
    Response response,
    DeliveryRecordModel Function(Map<String, dynamic>) fromJson,
    int requestedPageSize,
  ) {
    if (response.statusCode == 200) {
      final apiResponse = response.data as Map<String, dynamic>;
      if (apiResponse['success'] == true) {
        final data = apiResponse['data'] as Map<String, dynamic>;
        final items = data['items'] as List<dynamic>? ?? [];
        final totalResult = data['totalResult'] as int? ?? 0;
        final currentPage = data['page'] as int? ?? 1;
        final pageSize = data['pageSize'] as int? ?? requestedPageSize;
        final totalPages = pageSize > 0 ? (totalResult / pageSize).ceil() : 1;

        return PaginatedHistoryResponse(
          records: items
              .map((e) => fromJson(e as Map<String, dynamic>))
              .toList(),
          currentPage: currentPage,
          totalPages: totalPages,
          totalCount: totalResult,
          hasNextPage: currentPage < totalPages,
        );
      }
      throw ServerException(
        message: apiResponse['message'] ?? 'Yêu cầu thất bại',
      );
    }
    throw ServerException(
      message: 'Yêu cầu thất bại',
      statusCode: response.statusCode,
    );
  }

  static String _mimeTypeForFileName(String fileName) {
    final extension = fileName.split('.').last.toLowerCase();
    if (extension == 'jpg' || extension == 'jpeg') return 'image/jpeg';
    if (extension == 'png') return 'image/png';
    if (extension == 'gif') return 'image/gif';
    if (extension == 'webp') return 'image/webp';
    if (extension == 'bmp') return 'image/bmp';
    return 'application/octet-stream';
  }
}

/// Paginated response wrapper for groups
class PaginatedGroupsResponse {
  final List<DeliveryGroupSummaryModel> groups;
  final int currentPage;
  final int totalPages;
  final int totalCount;
  final bool hasNextPage;

  const PaginatedGroupsResponse({
    required this.groups,
    required this.currentPage,
    required this.totalPages,
    required this.totalCount,
    required this.hasNextPage,
  });
}

/// Paginated response wrapper for history
class PaginatedHistoryResponse {
  final List<DeliveryRecordModel> records;
  final int currentPage;
  final int totalPages;
  final int totalCount;
  final bool hasNextPage;

  const PaginatedHistoryResponse({
    required this.records,
    required this.currentPage,
    required this.totalPages,
    required this.totalCount,
    required this.hasNextPage,
  });
}
