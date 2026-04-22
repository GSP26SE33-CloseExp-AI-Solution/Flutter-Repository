import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/delivery_group.dart';
import '../entities/delivery_order.dart';
import '../entities/delivery_route_plan.dart';
import '../entities/delivery_stats.dart';

/// Delivery Repository Interface - Domain Layer
///
/// Defines the contract for delivery data operations.
/// Implementation is in the data layer.
abstract class DeliveryRepository {
  // ============== DELIVERY GROUPS ==============

  /// Nhóm Pending đã được admin gán cho shipper đăng nhập — chờ Accept
  Future<Either<Failure, List<DeliveryGroupSummary>>> getAvailableGroups({
    DateTime? deliveryDate,
  });

  /// Get delivery groups assigned to current staff (paginated)
  Future<Either<Failure, PaginatedDeliveryGroups>> getMyGroups({
    int page = 1,
    int pageSize = 10,
    String? status,
    DateTime? deliveryDate,
    String? sortBy,
    double? currentLatitude,
    double? currentLongitude,
  });

  Future<Either<Failure, List<DeliveryGroupSummary>>> getMyWorkQueue({
    int limit = 10,
    String? status,
    DateTime? deliveryDate,
    String? sortBy,
    double? currentLatitude,
    double? currentLongitude,
  });

  /// Get detailed delivery group by ID
  Future<Either<Failure, DeliveryGroup>> getDeliveryGroupById(String groupId);

  /// Accept a delivery group
  Future<Either<Failure, DeliveryGroup>> acceptDeliveryGroup(
    String groupId, {
    String? notes,
  });

  /// Start delivery for a group
  Future<Either<Failure, DeliveryGroup>> startDelivery(
    String groupId, {
    String? notes,
  });

  /// Complete a delivery group
  Future<Either<Failure, DeliveryGroup>> completeDeliveryGroup(String groupId);

  /// Tối ưu thứ tự điểm + polyline (BE gọi Mapbox).
  ///
  /// [skipPickupLeg]: khi shipper đã lấy hàng, set `true` để BE bỏ Leg A (pickup)
  /// và chỉ trả về Leg B (siêu thị → khách).
  Future<Either<Failure, DeliveryRoutePlan>> computeDeliveryRoutePlan(
    String groupId, {
    double? startLatitude,
    double? startLongitude,
    String metric = 'distance',
    bool skipPickupLeg = false,
  });

  // ============== DELIVERY ORDERS ==============

  /// Get order details for delivery
  Future<Either<Failure, DeliveryOrder>> getOrderDetails(
    String orderId, {
    String? groupId,
  });

  /// Upload ảnh chứng minh — BE `POST /delivery/orders/{id}/proof-image` (field `file`).
  Future<Either<Failure, String>> uploadDeliveryProofImage(
    String orderId,
    String localFilePath,
  );

  /// Xác nhận giao — BE bắt buộc [proofImageUrl] (http/https) và [verificationCode] (khớp orderCode).
  Future<Either<Failure, DeliveryOrder>> confirmDelivery(
    String orderId, {
    required String proofImageUrl,
    required String verificationCode,
    String? notes,
    String? deliveryGroupId,
  });

  /// Report delivery failure
  Future<Either<Failure, DeliveryOrder>> reportDeliveryFailure(
    String orderId, {
    required String failureReason,
    String? notes,
    List<String>? orderItemIds,
    String? deliveryGroupId,
  });

  // ============== HISTORY & STATS ==============

  /// Get delivery history (paginated)
  Future<Either<Failure, PaginatedDeliveryHistory>> getDeliveryHistory({
    int page = 1,
    int pageSize = 20,
    DateTime? fromDate,
    DateTime? toDate,
    String? status,
  });

  /// Get delivery statistics for current staff
  Future<Either<Failure, DeliveryStats>> getDeliveryStats();
}

/// Paginated response for delivery groups
class PaginatedDeliveryGroups {
  final List<DeliveryGroupSummary> groups;
  final int currentPage;
  final int totalPages;
  final int totalCount;
  final bool hasNextPage;

  const PaginatedDeliveryGroups({
    required this.groups,
    required this.currentPage,
    required this.totalPages,
    required this.totalCount,
    required this.hasNextPage,
  });

  bool get isEmpty => groups.isEmpty;
  bool get isNotEmpty => groups.isNotEmpty;
}

/// Paginated response for delivery history
class PaginatedDeliveryHistory {
  final List<DeliveryRecord> records;
  final int currentPage;
  final int totalPages;
  final int totalCount;
  final bool hasNextPage;

  const PaginatedDeliveryHistory({
    required this.records,
    required this.currentPage,
    required this.totalPages,
    required this.totalCount,
    required this.hasNextPage,
  });

  bool get isEmpty => records.isEmpty;
  bool get isNotEmpty => records.isNotEmpty;
}
