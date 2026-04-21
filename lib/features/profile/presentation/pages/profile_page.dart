import 'package:closed_deliver/features/delivery/presentation/widgets/widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../core/usecases/usecase.dart';
import '../../../../injection_container.dart';
import '../../../../core/router/app_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../auth/domain/entities/user.dart';
import '../../../auth/domain/entities/user_image.dart';
import '../../../auth/domain/usecases/delete_current_user_image_usecase.dart';
import '../../../auth/domain/usecases/get_primary_image_usecase.dart';
import '../../../auth/domain/usecases/upload_current_user_image_usecase.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../auth/presentation/bloc/auth_event.dart';
import '../../../auth/presentation/bloc/auth_state.dart';
import '../../../notifications/presentation/bloc/notifications_bloc.dart';
import '../../../notifications/presentation/bloc/notifications_state.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final ImagePicker _imagePicker = ImagePicker();
  UserImage? _primaryImage;
  bool _isPickingAvatar = false;

  @override
  void initState() {
    super.initState();
    _loadPrimaryAvatar();
  }

  Future<void> _loadPrimaryAvatar() async {
    try {
      final result = await sl<GetPrimaryImageUseCase>()(
        const NoParams(),
      ).timeout(const Duration(seconds: 10));

      if (!mounted) {
        return;
      }

      result.fold(
        (_) {
          setState(() {
            _primaryImage = null;
          });
        },
        (image) {
          setState(() {
            _primaryImage = image;
          });
        },
      );
    } catch (_) {
      if (!mounted) {
        return;
      }
      setState(() {
        _primaryImage = null;
      });
    }
  }

  int _resolveUnreadCount(NotificationsState state) {
    if (state is NotificationsListLoaded) {
      return state.unreadCount;
    }
    return 0;
  }

  Future<void> _openEditProfileDialog(User user) async {
    final result = await showDialog<_EditProfileResult>(
      context: context,
      builder: (dialogContext) => _EditProfileDialog(user: user),
    );

    if (!mounted || result == null) {
      return;
    }

    context.read<AuthBloc>().add(
      UpdateProfileEvent(fullName: result.fullName, phone: result.phone),
    );
  }

  Future<void> _pickAvatar(ImageSource source) async {
    if (_isPickingAvatar) {
      return;
    }

    setState(() {
      _isPickingAvatar = true;
    });

    try {
      final image = await _imagePicker.pickImage(
        source: source,
        imageQuality: 80,
        maxWidth: 1080,
      );

      if (image == null) {
        return;
      }

      final result = await sl<UploadCurrentUserImageUseCase>()(
        UploadCurrentUserImageParams(filePath: image.path),
      );

      if (!mounted) {
        return;
      }

      result.fold(
        (failure) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(failure.message),
              backgroundColor: AppColors.error,
            ),
          );
        },
        (uploadedImage) {
          setState(() {
            _primaryImage = uploadedImage;
          });

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Cập nhật ảnh đại diện thành công'),
              backgroundColor: AppColors.successGradientEnd,
            ),
          );
        },
      );
    } catch (_) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Không thể chọn ảnh đại diện, vui lòng thử lại'),
          backgroundColor: AppColors.error,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isPickingAvatar = false;
        });
      }
    }
  }

  Future<void> _removeAvatar() async {
    final imageId = _primaryImage?.imageId;
    if (imageId == null || imageId.isEmpty) {
      return;
    }

    final result = await sl<DeleteCurrentUserImageUseCase>()(
      DeleteCurrentUserImageParams(imageId: imageId),
    );

    if (!mounted) {
      return;
    }

    result.fold(
      (failure) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(failure.message),
            backgroundColor: AppColors.error,
          ),
        );
      },
      (_) {
        setState(() {
          _primaryImage = null;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Đã xóa ảnh đại diện'),
            backgroundColor: AppColors.successGradientEnd,
          ),
        );
      },
    );
  }

  Future<void> _showAvatarPickerSheet() async {
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  leading: const Icon(Icons.photo_library_outlined),
                  title: const Text('Chọn từ thư viện'),
                  onTap: () {
                    Navigator.of(sheetContext).pop();
                    _pickAvatar(ImageSource.gallery);
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.camera_alt_outlined),
                  title: const Text('Chụp ảnh mới'),
                  onTap: () {
                    Navigator.of(sheetContext).pop();
                    _pickAvatar(ImageSource.camera);
                  },
                ),
                if (_primaryImage != null)
                  ListTile(
                    leading: const Icon(
                      Icons.delete_outline,
                      color: AppColors.error,
                    ),
                    title: const Text('Xóa ảnh đại diện'),
                    onTap: () {
                      Navigator.of(sheetContext).pop();
                      _removeAvatar();
                    },
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  ImageProvider<Object>? _resolveAvatarImageProvider() {
    final avatarUrl = _primaryImage?.displayUrl.trim() ?? '';
    if (avatarUrl.isEmpty) {
      return null;
    }

    return NetworkImage(avatarUrl);
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<AuthBloc, AuthState>(
      listenWhen: (previous, current) {
        return current is ProfileUpdateFailure ||
            (previous is ProfileUpdateLoading && current is AuthAuthenticated);
      },
      listener: (context, state) {
        if (state is ProfileUpdateFailure) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message),
              backgroundColor: AppColors.error,
            ),
          );
          return;
        }

        if (state is AuthAuthenticated) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Cập nhật thông tin thành công'),
              backgroundColor: AppColors.successGradientEnd,
            ),
          );
        }
      },
      builder: (context, state) {
        final user = state is AuthAuthenticated ? state.user : null;
        final isUpdating = state is ProfileUpdateLoading;
        final avatarImageProvider = _resolveAvatarImageProvider();
        final isAvatarBusy = _isPickingAvatar;

        return Scaffold(
          appBar: AppBar(
            title: Text(
              'Tài khoản',
              style: AppTypography.header2.copyWith(
                color: AppColors.neutralDark,
              ),
            ),
            actions: [
              BlocBuilder<NotificationsBloc, NotificationsState>(
                builder: (context, notificationState) {
                  final unreadCount = _resolveUnreadCount(notificationState);
                  return IconButton(
                    tooltip: 'Thông báo',
                    onPressed: () => context.push(Routes.notifications),
                    icon: Stack(
                      clipBehavior: Clip.none,
                      children: [
                        const Icon(
                          Icons.notifications_none,
                          color: AppColors.neutralDark,
                        ),
                        if (unreadCount > 0)
                          Positioned(
                            right: -3,
                            top: -3,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 5,
                                vertical: 2,
                              ),
                              decoration: const BoxDecoration(
                                color: AppColors.error,
                                shape: BoxShape.rectangle,
                                borderRadius: BorderRadius.all(
                                  Radius.circular(10),
                                ),
                              ),
                              child: Text(
                                unreadCount > 99
                                    ? '99+'
                                    : unreadCount.toString(),
                                style: AppTypography.bodyRegular1.copyWith(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  );
                },
              ),
              IconButton(
                tooltip: 'Chỉnh sửa thông tin',
                onPressed: user == null || isUpdating
                    ? null
                    : () => _openEditProfileDialog(user),
                icon: isUpdating
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.edit_outlined),
              ),
              IconButton(
                tooltip: 'Đăng xuất',
                icon: const Icon(Icons.logout, color: AppColors.error),
                onPressed: () =>
                    context.read<AuthBloc>().add(const LogoutEvent()),
              ),
            ],
          ),
          body: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppColors.surfaceWhite,
                  border: Border.all(color: AppColors.cardBorder),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.06),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        InkWell(
                          onTap: isAvatarBusy ? null : _showAvatarPickerSheet,
                          borderRadius: BorderRadius.circular(28),
                          child: Stack(
                            clipBehavior: Clip.none,
                            children: [
                              CircleAvatar(
                                radius: 24,
                                backgroundColor: AppColors.avatarBackground,
                                backgroundImage: avatarImageProvider,
                                child: avatarImageProvider == null
                                    ? Text(
                                        user?.fullName.isNotEmpty == true
                                            ? user!.fullName[0].toUpperCase()
                                            : 'D',
                                        style: AppTypography.subHeader.copyWith(
                                          fontSize: 18,
                                          color: AppColors.bodyOnSurface,
                                        ),
                                      )
                                    : null,
                              ),
                              Positioned(
                                right: -2,
                                bottom: -2,
                                child: Container(
                                  width: 20,
                                  height: 20,
                                  decoration: BoxDecoration(
                                    color: AppColors.primary,
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: AppColors.surfaceWhite,
                                      width: 1.5,
                                    ),
                                  ),
                                  child: isAvatarBusy
                                      ? const Padding(
                                          padding: EdgeInsets.all(4),
                                          child: CircularProgressIndicator(
                                            strokeWidth: 1.6,
                                            color: Colors.white,
                                          ),
                                        )
                                      : const Icon(
                                          Icons.camera_alt_outlined,
                                          size: 12,
                                          color: Colors.white,
                                        ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                user?.fullName ?? 'Delivery Staff',
                                style: AppTypography.header2.copyWith(
                                  fontFamily: 'DM Sans',
                                  fontSize: 16,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                user?.roleName ?? '',
                                style: AppTypography.bodyRegular1.copyWith(
                                  fontSize: 13,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const Divider(height: 24, color: AppColors.cardBorder),
                    if (user?.email != null && user!.email.isNotEmpty)
                      _InfoRow(
                        icon: Icons.email_outlined,
                        label: 'Email',
                        value: user.email,
                      ),
                    if (user?.phone != null && user!.phone.isNotEmpty)
                      _InfoRow(
                        icon: Icons.phone_outlined,
                        label: 'Số điện thoại',
                        value: user.phone,
                      ),
                    const SizedBox(height: 14),
                    const Divider(color: AppColors.cardBorder),
                    const SizedBox(height: 6),
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      onTap: () => context.push(Routes.notifications),
                      leading: const Icon(
                        Icons.notifications_active_outlined,
                        color: AppColors.primary,
                      ),
                      title: Text(
                        'Trung tâm thông báo',
                        style: AppTypography.subHeader.copyWith(
                          color: AppColors.neutralDark,
                        ),
                      ),
                      subtitle:
                          BlocBuilder<NotificationsBloc, NotificationsState>(
                            builder: (context, notificationState) {
                              final unreadCount = _resolveUnreadCount(
                                notificationState,
                              );
                              return Text(
                                unreadCount > 0
                                    ? 'Bạn có $unreadCount thông báo chưa đọc'
                                    : 'Không có thông báo chưa đọc',
                                style: AppTypography.bodyRegular1.copyWith(
                                  color: AppColors.textSecondary,
                                ),
                              );
                            },
                          ),
                      trailing: const Icon(
                        Icons.chevron_right,
                        color: AppColors.neutralMid,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _EditProfileResult {
  final String fullName;
  final String? phone;

  const _EditProfileResult({required this.fullName, this.phone});
}

class _EditProfileDialog extends StatefulWidget {
  final User user;

  const _EditProfileDialog({required this.user});

  @override
  State<_EditProfileDialog> createState() => _EditProfileDialogState();
}

class _EditProfileDialogState extends State<_EditProfileDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _fullNameController;
  late final TextEditingController _phoneController;

  @override
  void initState() {
    super.initState();
    _fullNameController = TextEditingController(text: widget.user.fullName);
    _phoneController = TextEditingController(text: widget.user.phone);
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  void _onSave() {
    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }

    final fullName = _fullNameController.text.trim();
    final phone = _phoneController.text.trim();

    Navigator.of(context).pop(
      _EditProfileResult(
        fullName: fullName,
        phone: phone.isEmpty ? null : phone,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Cập nhật thông tin cơ bản'),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: _fullNameController,
              textInputAction: TextInputAction.next,
              decoration: const InputDecoration(
                labelText: 'Họ và tên',
                hintText: 'Nhập họ và tên',
                prefixIcon: Icon(Icons.person_outline),
              ),
              validator: (value) {
                final input = value?.trim() ?? '';
                if (input.isEmpty) {
                  return 'Vui lòng nhập họ và tên';
                }
                if (input.length < 2) {
                  return 'Họ và tên quá ngắn';
                }
                if (input.length > 100) {
                  return 'Họ và tên không quá 100 ký tự';
                }
                return null;
              },
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _phoneController,
              keyboardType: TextInputType.phone,
              textInputAction: TextInputAction.done,
              onFieldSubmitted: (_) => _onSave(),
              decoration: const InputDecoration(
                labelText: 'Số điện thoại',
                hintText: 'Nhập số điện thoại',
                prefixIcon: Icon(Icons.phone_outlined),
              ),
              validator: (value) {
                final input = value?.trim() ?? '';
                if (input.isEmpty) {
                  return null;
                }
                final phonePattern = RegExp(r'^[0-9+\s]{9,15}$');
                if (!phonePattern.hasMatch(input)) {
                  return 'Số điện thoại không hợp lệ';
                }
                return null;
              },
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Hủy'),
        ),
        AppGradientButton(
          onPressed: _onSave,
          child: SizedBox(
            width: 60,
            child: Center(
              child: Text(
                'Lưu',
                style: AppTypography.subHeader.copyWith(
                  color: AppColors.background,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(icon, size: 18, color: AppColors.neutralMid),
          const SizedBox(width: 10),
          Text(
            '$label: ',
            style: AppTypography.bodyRegular1.copyWith(
              fontSize: 13,
              color: AppColors.textSecondary,
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: AppTypography.header3.copyWith(
                color: AppColors.textPrimary,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
