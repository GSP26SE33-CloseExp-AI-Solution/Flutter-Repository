import '../../domain/entities/auth_result.dart';
import 'user_model.dart';

/// Auth response model: serialize/deserialize phản hồi đăng nhập từ API.
class AuthResponseModel extends AuthResult {
  const AuthResponseModel({
    required super.accessToken,
    required super.refreshToken,
    required super.expiresAt,
    required super.user,
  });

  /// Create from JSON (API response wrapped in ApiResponse)
  factory AuthResponseModel.fromJson(Map<String, dynamic> json) {
    // The API returns data wrapped in ApiResponse structure
    final data = json['data'] as Map<String, dynamic>? ?? json;

    return AuthResponseModel(
      accessToken: data['accessToken'] as String? ?? '',
      refreshToken: data['refreshToken'] as String? ?? '',
      expiresAt: _parseDateTime(data['expiresAt']),
      user: UserModel.fromJson(data['user'] as Map<String, dynamic>? ?? {}),
    );
  }

  /// Convert to JSON for local storage
  Map<String, dynamic> toJson() {
    return {
      'accessToken': accessToken,
      'refreshToken': refreshToken,
      'expiresAt': expiresAt.toIso8601String(),
      'user': (user as UserModel).toJson(),
    };
  }

  /// Parse DateTime from JSON
  static DateTime _parseDateTime(dynamic dateTime) {
    if (dateTime == null) {
      return DateTime.now().add(const Duration(hours: 1));
    }
    if (dateTime is String) {
      return DateTime.parse(dateTime);
    }
    return DateTime.now().add(const Duration(hours: 1));
  }
}

/// Login Request Model
class LoginRequestModel {
  final String email;
  final String password;

  const LoginRequestModel({required this.email, required this.password});

  Map<String, dynamic> toJson() {
    return {'email': email, 'password': password};
  }
}





/// Refresh Token Request Model
class RefreshTokenRequestModel {
  final String refreshToken;

  const RefreshTokenRequestModel({required this.refreshToken});

  Map<String, dynamic> toJson() {
    return {'refreshToken': refreshToken};
  }
}

/// Logout Request Model
class LogoutRequestModel {
  final String refreshToken;

  const LogoutRequestModel({required this.refreshToken});

  Map<String, dynamic> toJson() {
    return {'refreshToken': refreshToken};
  }
}



/// Update Profile Request Model
class UpdateProfileRequestModel {
  final String? fullName;
  final String? phone;

  const UpdateProfileRequestModel({this.fullName, this.phone});

  Map<String, dynamic> toJson() {
    return {
      if (fullName != null) 'fullName': fullName,
      if (phone != null) 'phone': phone,
    };
  }
}
