import '../../domain/entities/user_image.dart';

class UserImageModel extends UserImage {
  const UserImageModel({
    required super.imageId,
    required super.userId,
    required super.imageUrl,
    required super.preSignedUrl,
    required super.imageType,
    required super.isPrimary,
    required super.createdAt,
  });

  factory UserImageModel.fromJson(Map<String, dynamic> json) {
    return UserImageModel(
      imageId: json['imageId']?.toString() ?? '',
      userId: json['userId']?.toString() ?? '',
      imageUrl: json['imageUrl'] as String? ?? '',
      preSignedUrl: json['preSignedUrl'] as String? ?? '',
      imageType: json['imageType'] as String? ?? 'avatar',
      isPrimary: json['isPrimary'] as bool? ?? false,
      createdAt: _parseDateTime(json['createdAt']),
    );
  }

  static DateTime _parseDateTime(dynamic value) {
    if (value is String) {
      return DateTime.tryParse(value) ?? DateTime.now();
    }
    return DateTime.now();
  }
}
