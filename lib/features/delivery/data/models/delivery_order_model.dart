import '../../domain/entities/delivery_order.dart';

/// Delivery Order Model - Data Layer
///
/// Handles serialization/deserialization for API communication.
class DeliveryOrderModel extends DeliveryOrder {
  const DeliveryOrderModel({
    required super.orderId,
    super.deliveryGroupId,
    required super.orderCode,
    required super.status,
    required super.deliveryType,
    required super.totalAmount,
    required super.deliveryFee,
    required super.orderDate,
    required super.customerName,
    required super.customerPhone,
    super.deliveryAddress,
    super.pickupPointName,
    super.pickupPointAddress,
    super.deliveryNote,
    required super.timeSlotDisplay,
    required super.totalItems,
    super.items,
    super.latitude,
    super.longitude,
  });

  factory DeliveryOrderModel.fromJson(Map<String, dynamic> json) {
    final itemsList = json['items'] as List<dynamic>? ?? [];
    final items = itemsList
        .map((e) => DeliveryOrderItemModel.fromJson(e as Map<String, dynamic>))
        .toList();

    return DeliveryOrderModel(
      orderId: json['orderId'] as String? ?? '',
      deliveryGroupId: _optionalGuidString(json['deliveryGroupId']),
      orderCode: json['orderCode'] as String? ?? '',
      status: DeliveryOrderStatus.fromString(json['status'] as String? ?? ''),
      deliveryType: json['deliveryType'] as String? ?? '',
      totalAmount: (json['totalAmount'] as num?)?.toDouble() ?? 0,
      deliveryFee: (json['deliveryFee'] as num?)?.toDouble() ?? 0,
      orderDate: _parseDateTime(json['orderDate']),
      customerName: json['customerName'] as String? ?? '',
      customerPhone: json['customerPhone'] as String? ?? '',
      // BE field: addressLine (for home delivery) — was 'deliveryAddress' (wrong)
      deliveryAddress: json['addressLine'] as String?,
      // BE field: collectionPointName — was 'pickupPointName' (wrong)
      pickupPointName: json['collectionPointName'] as String?,
      // BE has no separate collectionPointAddress in DeliveryOrderResponseDto
      pickupPointAddress: null,
      deliveryNote: json['deliveryNote'] as String?,
      timeSlotDisplay: json['timeSlotDisplay'] as String? ?? '',
      totalItems: json['totalItems'] as int? ?? 0,
      items: items,
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'orderId': orderId,
      if (deliveryGroupId != null) 'deliveryGroupId': deliveryGroupId,
      'orderCode': orderCode,
      'status': status.toApiString(),
      'deliveryType': deliveryType,
      'totalAmount': totalAmount,
      'deliveryFee': deliveryFee,
      'orderDate': orderDate.toIso8601String(),
      'customerName': customerName,
      'customerPhone': customerPhone,
      'addressLine': deliveryAddress,
      'collectionPointName': pickupPointName,
      'deliveryNote': deliveryNote,
      'timeSlotDisplay': timeSlotDisplay,
      'totalItems': totalItems,
      'latitude': latitude,
      'longitude': longitude,
      'items': items
          .map((e) => (e as DeliveryOrderItemModel).toJson())
          .toList(),
    };
  }

  /// BE trả `deliveryGroupId` dạng Guid (string); null nếu đơn chưa gắn nhóm.
  static String? _optionalGuidString(dynamic value) {
    if (value == null) return null;
    final s = value.toString().trim();
    return s.isEmpty ? null : s;
  }

  static DateTime _parseDateTime(dynamic dateTime) {
    if (dateTime == null) return DateTime.now();
    if (dateTime is String) return DateTime.parse(dateTime);
    return DateTime.now();
  }
}

/// Delivery Order Item Model
class DeliveryOrderItemModel extends DeliveryOrderItem {
  const DeliveryOrderItemModel({
    required super.orderItemId,
    required super.productName,
    required super.quantity,
    required super.unitPrice,
    required super.subTotal,
  });

  factory DeliveryOrderItemModel.fromJson(Map<String, dynamic> json) {
    return DeliveryOrderItemModel(
      orderItemId: json['orderItemId'] as String? ?? '',
      productName: json['productName'] as String? ?? '',
      quantity: json['quantity'] as int? ?? 0,
      unitPrice: (json['unitPrice'] as num?)?.toDouble() ?? 0,
      subTotal: (json['subTotal'] as num?)?.toDouble() ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'orderItemId': orderItemId,
      'productName': productName,
      'quantity': quantity,
      'unitPrice': unitPrice,
      'subTotal': subTotal,
    };
  }
}

/// Delivery Record Model
class DeliveryRecordModel extends DeliveryRecord {
  const DeliveryRecordModel({
    required super.deliveryId,
    required super.orderId,
    required super.orderCode,
    required super.userId,
    required super.deliveryStaffName,
    required super.status,
    super.failureReason,
    super.deliveredAt,
    super.deliveryLatitude,
    super.deliveryLongitude,
    super.proofImageUrl,
  });

  factory DeliveryRecordModel.fromJson(Map<String, dynamic> json) {
    return DeliveryRecordModel(
      deliveryId: json['deliveryId'] as String? ?? '',
      orderId: json['orderId'] as String? ?? '',
      orderCode: json['orderCode'] as String? ?? '',
      userId: json['userId'] as String? ?? '',
      deliveryStaffName: json['deliveryStaffName'] as String? ?? '',
      status: DeliveryOrderStatus.fromString(json['status'] as String? ?? ''),
      failureReason: json['failureReason'] as String?,
      deliveredAt: _parseNullableDateTime(json['deliveredAt']),
      deliveryLatitude: (json['deliveryLatitude'] as num?)?.toDouble(),
      deliveryLongitude: (json['deliveryLongitude'] as num?)?.toDouble(),
      proofImageUrl: json['proofImageUrl'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'deliveryId': deliveryId,
      'orderId': orderId,
      'orderCode': orderCode,
      'userId': userId,
      'deliveryStaffName': deliveryStaffName,
      'status': status.toApiString(),
      'failureReason': failureReason,
      'deliveredAt': deliveredAt?.toIso8601String(),
      'deliveryLatitude': deliveryLatitude,
      'deliveryLongitude': deliveryLongitude,
      'proofImageUrl': proofImageUrl,
    };
  }

  static DateTime? _parseNullableDateTime(dynamic dateTime) {
    if (dateTime == null) return null;
    if (dateTime is String) return DateTime.parse(dateTime);
    return null;
  }
}
