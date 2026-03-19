import 'package:dio/dio.dart';
import '../../../../core/constants/api_constants.dart';
import '../../../../core/error/exceptions.dart';
import '../models/delivery_group_model.dart';
import '../models/delivery_order_model.dart';
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
  });
  Future<DeliveryGroupModel> getDeliveryGroupById(String groupId);
  Future<DeliveryGroupModel> acceptDeliveryGroup(
    String groupId, {
    String? notes,
  });
  Future<DeliveryGroupModel> startDelivery(String groupId, {String? notes});
  Future<DeliveryGroupModel> completeDeliveryGroup(String groupId);

  // Delivery Orders
  Future<DeliveryOrderModel> getOrderDetails(String orderId);
  Future<DeliveryOrderModel> confirmDelivery(
    String orderId, {
    String? proofImageUrl,
    String? notes,
  });
  Future<DeliveryOrderModel> reportDeliveryFailure(
    String orderId, {
    required String failureReason,
    String? notes,
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
  Future<DeliveryOrderModel> getOrderDetails(String orderId) async {
    try {
      final response = await _dio.get(ApiConstants.deliveryOrderById(orderId));
      return _handleSingleResponse(response, DeliveryOrderModel.fromJson);
    } on DioException {
      rethrow;
    } catch (e) {
      throw ServerException(message: 'Không thể tải thông tin đơn hàng: $e');
    }
  }

  @override
  Future<DeliveryOrderModel> confirmDelivery(
    String orderId, {
    String? proofImageUrl,
    String? notes,
  }) async {
    try {
      final response = await _dio.post(
        ApiConstants.confirmDelivery(orderId),
        data: {'proofImageUrl': proofImageUrl, 'notes': notes},
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
  }) async {
    try {
      final response = await _dio.post(
        ApiConstants.reportDeliveryFailure(orderId),
        data: {'failureReason': failureReason, 'notes': notes},
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
