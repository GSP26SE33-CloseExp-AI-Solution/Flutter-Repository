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
  final MarketStaffInfo? marketStaffInfo;

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
    this.marketStaffInfo,
  });

  /// Check if user is a delivery staff
  bool get isDeliveryStaff => roleName == 'DeliveryStaff';

  /// Check if user is a supplier staff (nhân viên siêu thị)
  bool get isSupplierStaff => roleName == 'SupplierStaff';

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
    marketStaffInfo,
  ];
}

/// Market Staff Info - nested entity for MarketStaff users
/// Matches BE MarketStaffInfoDto structure
class MarketStaffInfo extends Equatable {
  final String marketStaffId;
  final String position;
  final DateTime joinedAt;
  final SupermarketBasicInfo? supermarket;

  const MarketStaffInfo({
    required this.marketStaffId,
    required this.position,
    required this.joinedAt,
    this.supermarket,
  });

  /// Get supermarket ID from nested supermarket
  String? get supermarketId => supermarket?.supermarketId;

  /// Get supermarket name from nested supermarket
  String? get supermarketName => supermarket?.name;

  @override
  List<Object?> get props => [marketStaffId, position, joinedAt, supermarket];
}

/// Supermarket Basic Info - nested entity
/// Matches BE SupermarketBasicInfoDto structure
class SupermarketBasicInfo extends Equatable {
  final String supermarketId;
  final String name;
  final String address;
  final String contactPhone;

  const SupermarketBasicInfo({
    required this.supermarketId,
    required this.name,
    required this.address,
    required this.contactPhone,
  });

  @override
  List<Object?> get props => [supermarketId, name, address, contactPhone];
}

/// User Status Enum matching backend UserState
enum UserStatus {
  /// Tài khoản vừa đăng ký - chưa xác minh email
  unverified,

  /// Email đã xác minh - chờ Admin phê duyệt
  pendingApproval,

  /// Tài khoản đã được Admin phê duyệt - có thể hoạt động
  active,

  /// Admin từ chối phê duyệt tài khoản
  rejected,

  /// Tài khoản bị khóa tạm thời (đăng nhập sai nhiều lần)
  locked,

  /// Tài khoản bị Admin cấm vĩnh viễn
  banned,

  /// Tài khoản đã bị xóa
  deleted,

  /// Tài khoản bị ẩn khỏi public view
  hidden;

  static UserStatus fromString(String status) {
    switch (status.toLowerCase()) {
      case 'unverified':
        return UserStatus.unverified;
      case 'pendingapproval':
      case 'pending_approval':
        return UserStatus.pendingApproval;
      case 'active':
        return UserStatus.active;
      case 'rejected':
        return UserStatus.rejected;
      case 'locked':
        return UserStatus.locked;
      case 'banned':
        return UserStatus.banned;
      case 'deleted':
        return UserStatus.deleted;
      case 'hidden':
        return UserStatus.hidden;
      default:
        return UserStatus.unverified;
    }
  }

  static UserStatus fromInt(int status) {
    if (status >= 0 && status < UserStatus.values.length) {
      return UserStatus.values[status];
    }
    return UserStatus.unverified;
  }

  String get displayName {
    switch (this) {
      case UserStatus.unverified:
        return 'Chưa xác minh';
      case UserStatus.pendingApproval:
        return 'Chờ phê duyệt';
      case UserStatus.active:
        return 'Hoạt động';
      case UserStatus.rejected:
        return 'Bị từ chối';
      case UserStatus.locked:
        return 'Bị khóa';
      case UserStatus.banned:
        return 'Bị cấm';
      case UserStatus.deleted:
        return 'Đã xóa';
      case UserStatus.hidden:
        return 'Ẩn';
    }
  }

  String toApiString() {
    switch (this) {
      case UserStatus.unverified:
        return 'Unverified';
      case UserStatus.pendingApproval:
        return 'PendingApproval';
      case UserStatus.active:
        return 'Active';
      case UserStatus.rejected:
        return 'Rejected';
      case UserStatus.locked:
        return 'Locked';
      case UserStatus.banned:
        return 'Banned';
      case UserStatus.deleted:
        return 'Deleted';
      case UserStatus.hidden:
        return 'Hidden';
    }
  }
}
