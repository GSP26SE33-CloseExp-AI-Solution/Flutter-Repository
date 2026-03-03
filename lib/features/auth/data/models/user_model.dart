import '../../domain/entities/user.dart';

/// User Model - Data Layer
///
/// This model handles serialization/deserialization for API communication.
/// It extends the User entity and adds JSON conversion methods.
class UserModel extends User {
  const UserModel({
    required super.userId,
    required super.fullName,
    required super.email,
    required super.phone,
    required super.roleName,
    required super.roleId,
    required super.status,
    required super.createdAt,
    required super.updatedAt,
    super.marketStaffInfo,
  });

  /// Create UserModel from JSON (API response)
  factory UserModel.fromJson(Map<String, dynamic> json) {
    // Parse marketStaffInfo if present
    MarketStaffInfoModel? marketStaffInfo;
    if (json['marketStaffInfo'] != null) {
      marketStaffInfo = MarketStaffInfoModel.fromJson(
        json['marketStaffInfo'] as Map<String, dynamic>,
      );
    }

    return UserModel(
      userId: json['userId'] as String,
      fullName: json['fullName'] as String? ?? '',
      email: json['email'] as String? ?? '',
      phone: json['phone'] as String? ?? '',
      roleName: json['roleName'] as String? ?? '',
      roleId: json['roleId'] as int? ?? 0,
      status: _parseStatus(json['status']),
      createdAt: _parseDateTime(json['createdAt']),
      updatedAt: _parseDateTime(json['updatedAt']),
      marketStaffInfo: marketStaffInfo,
    );
  }

  /// Convert to JSON for local storage
  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'fullName': fullName,
      'email': email,
      'phone': phone,
      'roleName': roleName,
      'roleId': roleId,
      'status': status.toApiString(),
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'marketStaffInfo': marketStaffInfo != null
          ? (marketStaffInfo as MarketStaffInfoModel).toJson()
          : null,
    };
  }

  /// Convert Entity to Model
  factory UserModel.fromEntity(User user) {
    return UserModel(
      userId: user.userId,
      fullName: user.fullName,
      email: user.email,
      phone: user.phone,
      roleName: user.roleName,
      roleId: user.roleId,
      status: user.status,
      createdAt: user.createdAt,
      updatedAt: user.updatedAt,
      marketStaffInfo: user.marketStaffInfo != null
          ? MarketStaffInfoModel.fromEntity(user.marketStaffInfo!)
          : null,
    );
  }

  /// Parse status from JSON (can be int or string)
  static UserStatus _parseStatus(dynamic status) {
    if (status == null) return UserStatus.unverified;
    if (status is int) return UserStatus.fromInt(status);
    if (status is String) return UserStatus.fromString(status);
    return UserStatus.unverified;
  }

  /// Parse DateTime from JSON (can be null)
  static DateTime _parseDateTime(dynamic dateTime) {
    if (dateTime == null) return DateTime.now();
    if (dateTime is String) return DateTime.parse(dateTime);
    return DateTime.now();
  }
}

/// MarketStaffInfo Model for serialization
/// Matches BE MarketStaffInfoDto structure
class MarketStaffInfoModel extends MarketStaffInfo {
  const MarketStaffInfoModel({
    required super.marketStaffId,
    required super.position,
    required super.joinedAt,
    super.supermarket,
  });

  factory MarketStaffInfoModel.fromJson(Map<String, dynamic> json) {
    SupermarketBasicInfoModel? supermarket;
    if (json['supermarket'] != null) {
      supermarket = SupermarketBasicInfoModel.fromJson(
        json['supermarket'] as Map<String, dynamic>,
      );
    }

    return MarketStaffInfoModel(
      marketStaffId: json['marketStaffId'] as String? ?? '',
      position: json['position'] as String? ?? '',
      joinedAt: _parseDateTime(json['joinedAt']),
      supermarket: supermarket,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'marketStaffId': marketStaffId,
      'position': position,
      'joinedAt': joinedAt.toIso8601String(),
      'supermarket': supermarket != null
          ? (supermarket as SupermarketBasicInfoModel).toJson()
          : null,
    };
  }

  factory MarketStaffInfoModel.fromEntity(MarketStaffInfo entity) {
    return MarketStaffInfoModel(
      marketStaffId: entity.marketStaffId,
      position: entity.position,
      joinedAt: entity.joinedAt,
      supermarket: entity.supermarket != null
          ? SupermarketBasicInfoModel.fromEntity(entity.supermarket!)
          : null,
    );
  }

  static DateTime _parseDateTime(dynamic dateTime) {
    if (dateTime == null) return DateTime.now();
    if (dateTime is String) return DateTime.parse(dateTime);
    return DateTime.now();
  }
}

/// SupermarketBasicInfo Model for serialization
/// Matches BE SupermarketBasicInfoDto structure
class SupermarketBasicInfoModel extends SupermarketBasicInfo {
  const SupermarketBasicInfoModel({
    required super.supermarketId,
    required super.name,
    required super.address,
    required super.contactPhone,
  });

  factory SupermarketBasicInfoModel.fromJson(Map<String, dynamic> json) {
    return SupermarketBasicInfoModel(
      supermarketId: json['supermarketId'] as String? ?? '',
      name: json['name'] as String? ?? '',
      address: json['address'] as String? ?? '',
      contactPhone: json['contactPhone'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'supermarketId': supermarketId,
      'name': name,
      'address': address,
      'contactPhone': contactPhone,
    };
  }

  factory SupermarketBasicInfoModel.fromEntity(SupermarketBasicInfo entity) {
    return SupermarketBasicInfoModel(
      supermarketId: entity.supermarketId,
      name: entity.name,
      address: entity.address,
      contactPhone: entity.contactPhone,
    );
  }
}
