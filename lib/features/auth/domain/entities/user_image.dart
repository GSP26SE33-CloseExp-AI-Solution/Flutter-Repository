import 'package:equatable/equatable.dart';

class UserImage extends Equatable {
  final String imageId;
  final String userId;
  final String imageUrl;
  final String preSignedUrl;
  final String imageType;
  final bool isPrimary;
  final DateTime createdAt;

  const UserImage({
    required this.imageId,
    required this.userId,
    required this.imageUrl,
    required this.preSignedUrl,
    required this.imageType,
    required this.isPrimary,
    required this.createdAt,
  });

  String get displayUrl {
    if (preSignedUrl.trim().isNotEmpty) {
      return preSignedUrl;
    }
    return imageUrl;
  }

  @override
  List<Object?> get props => [
    imageId,
    userId,
    imageUrl,
    preSignedUrl,
    imageType,
    isPrimary,
    createdAt,
  ];
}
