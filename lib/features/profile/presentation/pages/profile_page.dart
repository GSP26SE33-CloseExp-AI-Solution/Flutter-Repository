import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/app_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../auth/presentation/bloc/auth_event.dart';
import '../../../auth/presentation/bloc/auth_state.dart';
import '../../../notifications/presentation/bloc/notifications_bloc.dart';
import '../../../notifications/presentation/bloc/notifications_state.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  int _resolveUnreadCount(NotificationsState state) {
    if (state is NotificationsListLoaded) {
      return state.unreadCount;
    }
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, state) {
        final user = state is AuthAuthenticated ? state.user : null;

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
                tooltip: 'Đăng xuất',
                icon: const Icon(Icons.logout, color: AppColors.error),
                onPressed: () =>
                    context.read<AuthBloc>().add(const LogoutEvent()),
              ),
            ],
          ),
          body: Padding(
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
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Avatar + name row
                  Row(
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: const BoxDecoration(
                          color: AppColors.avatarBackground,
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Text(
                            user?.fullName.isNotEmpty == true
                                ? user!.fullName[0].toUpperCase()
                                : 'D',
                            style: AppTypography.subHeader.copyWith(
                              fontSize: 18,
                              color: AppColors.bodyOnSurface,
                            ),
                          ),
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

                  // Info rows
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
        );
      },
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
