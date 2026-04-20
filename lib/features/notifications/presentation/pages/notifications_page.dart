import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/router/app_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../auth/presentation/bloc/auth_event.dart';
import '../../domain/entities/notification_item.dart';
import '../bloc/notifications_bloc.dart';
import '../bloc/notifications_event.dart';
import '../bloc/notifications_state.dart';

class NotificationsPage extends StatefulWidget {
  const NotificationsPage({super.key});

  @override
  State<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage> {
  final DateFormat _dateTimeFormatter = DateFormat('dd/MM/yyyy HH:mm');

  @override
  void initState() {
    super.initState();
    context.read<NotificationsBloc>().add(const LoadMyNotifications());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Thông báo',
          style: AppTypography.header2.copyWith(color: AppColors.neutralDark),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Làm mới',
            onPressed: () {
              context.read<NotificationsBloc>().add(
                const LoadMyNotifications(forceRefresh: true),
              );
            },
          ),
        ],
      ),
      body: BlocConsumer<NotificationsBloc, NotificationsState>(
        listener: (context, state) {
          if (state is NotificationsSessionExpired) {
            context.read<AuthBloc>().add(const SessionExpiredEvent());
          }
        },
        builder: (context, state) {
          if (state is NotificationsLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state is NotificationsError) {
            return _buildError(state.message);
          }

          if (state is NotificationsListLoaded) {
            return _buildList(state);
          }

          return const SizedBox.shrink();
        },
      ),
    );
  }

  Widget _buildError(String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.error_outline,
              size: 52,
              color: AppColors.error.withValues(alpha: 0.85),
            ),
            const SizedBox(height: 12),
            Text(
              message,
              textAlign: TextAlign.center,
              style: AppTypography.bodyRegular1.copyWith(
                color: AppColors.neutralDark,
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                context.read<NotificationsBloc>().add(
                  const LoadMyNotifications(forceRefresh: true),
                );
              },
              child: const Text('Thử lại'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildList(NotificationsListLoaded state) {
    return RefreshIndicator(
      onRefresh: () async {
        context.read<NotificationsBloc>().add(
          const LoadMyNotifications(forceRefresh: true),
        );
      },
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: Row(
              children: [
                ChoiceChip(
                  label: const Text('Tất cả'),
                  selected: !state.unreadOnly,
                  onSelected: (_) {
                    context.read<NotificationsBloc>().add(
                      const ToggleUnreadFilter(unreadOnly: false),
                    );
                  },
                ),
                const SizedBox(width: 8),
                ChoiceChip(
                  label: Text('Chưa đọc (${state.unreadCount})'),
                  selected: state.unreadOnly,
                  onSelected: (_) {
                    context.read<NotificationsBloc>().add(
                      const ToggleUnreadFilter(unreadOnly: true),
                    );
                  },
                ),
              ],
            ),
          ),
          Expanded(
            child: state.isEmpty
                ? _buildEmpty(state.unreadOnly)
                : ListView.separated(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                    itemCount: state.visibleItems.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 10),
                    itemBuilder: (context, index) {
                      final item = state.visibleItems[index];
                      return _NotificationCard(
                        item: item,
                        createdAtText: _dateTimeFormatter.format(
                          item.createdAt,
                        ),
                        onTap: () {
                          if (!item.isRead) {
                            context.read<NotificationsBloc>().add(
                              MarkNotificationAsRead(
                                notificationId: item.notificationId,
                              ),
                            );
                          }

                          final orderId = item.orderId?.trim();
                          if (orderId != null && orderId.isNotEmpty) {
                            context.push(
                              Routes.notificationThread(orderId),
                              extra: item.orderCode,
                            );
                          }
                        },
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmpty(bool unreadOnly) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        const SizedBox(height: 120),
        const Icon(
          Icons.notifications_none,
          size: 74,
          color: AppColors.neutralMid,
        ),
        const SizedBox(height: 10),
        Center(
          child: Text(
            unreadOnly
                ? 'Không còn thông báo chưa đọc'
                : 'Bạn chưa có thông báo nào',
            style: AppTypography.bodyRegular1.copyWith(
              color: AppColors.neutralMid,
            ),
          ),
        ),
      ],
    );
  }
}

class _NotificationCard extends StatelessWidget {
  final NotificationItem item;
  final String createdAtText;
  final VoidCallback onTap;

  const _NotificationCard({
    required this.item,
    required this.createdAtText,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: onTap,
      child: Ink(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: item.isRead
              ? AppColors.surfaceWhite
              : AppColors.notificationUnreadBackground,
          border: Border.all(color: AppColors.cardBorder),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    item.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.subHeader.copyWith(
                      color: AppColors.neutralDark,
                      fontWeight: item.isRead
                          ? FontWeight.w600
                          : FontWeight.w700,
                    ),
                  ),
                ),
                if (!item.isRead)
                  const SizedBox(
                    width: 9,
                    height: 9,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: AppColors.primaryGradientEnd,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              item.content,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: AppTypography.bodyRegular1.copyWith(
                color: AppColors.neutralDark,
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 6,
              children: [
                _MetaChip(
                  label: item.type.displayName,
                  icon: Icons.sell_outlined,
                ),
                if (item.orderCode != null && item.orderCode!.trim().isNotEmpty)
                  _MetaChip(
                    label: item.orderCode!,
                    icon: Icons.receipt_long_outlined,
                  ),
                _MetaChip(label: createdAtText, icon: Icons.schedule),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _MetaChip extends StatelessWidget {
  final String label;
  final IconData icon;

  const _MetaChip({required this.label, required this.icon});

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.notificationMetaChipBackground,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: AppColors.neutralMid),
            const SizedBox(width: 6),
            Text(
              label,
              style: AppTypography.bodyRegular1.copyWith(
                color: AppColors.neutralMid,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
