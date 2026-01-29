import 'package:equatable/equatable.dart';

/// User Entity - Domain Layer
///
/// This is the core business entity for User.
/// It represents the user data that the app works with.
class User extends Equatable {
  final String userId;
  final String fullName;
  final String email;
  final String phone;
  final String roleName;
  final int roleId;
  final UserStatus status;
  final DateTime createdAt;
  final DateTime updatedAt;

  const User({
    required this.userId,
    required this.fullName,
    required this.email,
    required this.phone,
    required this.roleName,
    required this.roleId,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Check if user is a delivery staff
  bool get isDeliveryStaff => roleName == 'DeliveryStaff';

  /// Check if user account is active
  bool get isActive => status == UserStatus.active;

  @override
  List<Object?> get props => [
    userId,
    fullName,
    email,
    phone,
    roleName,
    roleId,
    status,
    createdAt,
    updatedAt,
  ];
}

/// User Status Enum matching backend UserState
enum UserStatus {
  active,
  inactive,
  banned,
  deleted,
  hidden;

  static UserStatus fromString(String status) {
    switch (status.toLowerCase()) {
      case 'active':
        return UserStatus.active;
      case 'inactive':
        return UserStatus.inactive;
      case 'banned':
        return UserStatus.banned;
      case 'deleted':
        return UserStatus.deleted;
      case 'hidden':
        return UserStatus.hidden;
      default:
        return UserStatus.inactive;
    }
  }

  static UserStatus fromInt(int status) {
    if (status >= 0 && status < UserStatus.values.length) {
      return UserStatus.values[status];
    }
    return UserStatus.inactive;
  }
}
