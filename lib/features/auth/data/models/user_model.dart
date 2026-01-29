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
  });

  /// Create UserModel from JSON (API response)
  factory UserModel.fromJson(Map<String, dynamic> json) {
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
      'status': status.index,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
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
    );
  }

  /// Parse status from JSON (can be int or string)
  static UserStatus _parseStatus(dynamic status) {
    if (status == null) return UserStatus.inactive;
    if (status is int) return UserStatus.fromInt(status);
    if (status is String) return UserStatus.fromString(status);
    return UserStatus.inactive;
  }

  /// Parse DateTime from JSON (can be null)
  static DateTime _parseDateTime(dynamic dateTime) {
    if (dateTime == null) return DateTime.now();
    if (dateTime is String) return DateTime.parse(dateTime);
    return DateTime.now();
  }
}
