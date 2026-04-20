import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../auth/presentation/bloc/auth_event.dart';
import '../../domain/entities/notification_item.dart';
import '../bloc/notifications_bloc.dart';
import '../bloc/notifications_event.dart';
import '../bloc/notifications_state.dart';

class NotificationThreadPage extends StatefulWidget {
  final String orderId;
  final String? orderCode;

  const NotificationThreadPage({
    super.key,
    required this.orderId,
    this.orderCode,
  });

  @override
  State<NotificationThreadPage> createState() => _NotificationThreadPageState();
}

class _NotificationThreadPageState extends State<NotificationThreadPage> {
  final DateFormat _dateTimeFormatter = DateFormat('dd/MM/yyyy HH:mm');

  @override
  void initState() {
    super.initState();
    context.read<NotificationsBloc>().add(
      LoadOrderNotificationThread(orderId: widget.orderId),
    );
  }

  @override
  Widget build(BuildContext context) {
    final subtitle =
        widget.orderCode == null || widget.orderCode!.trim().isEmpty
        ? widget.orderId
        : widget.orderCode!;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Luồng thông báo',
          style: AppTypography.header2.copyWith(color: AppColors.neutralDark),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(26),
          child: Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text(
              subtitle,
              style: AppTypography.bodyRegular1.copyWith(
                color: AppColors.neutralMid,
              ),
            ),
          ),
        ),
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

          if (state is NotificationsThreadLoaded) {
            if (state.items.isEmpty) {
              return _buildEmpty();
            }

            return ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
              itemCount: state.items.length,
              separatorBuilder: (_, _) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                final item = state.items[index];
                return _ThreadCard(
                  item: item,
                  createdAtText: _dateTimeFormatter.format(item.createdAt),
                  onMarkRead: item.isRead
                      ? null
                      : () {
                          context.read<NotificationsBloc>().add(
                            MarkNotificationAsRead(
                              notificationId: item.notificationId,
                            ),
                          );
                        },
                );
              },
            );
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
                  LoadOrderNotificationThread(orderId: widget.orderId),
                );
              },
              child: const Text('Thử lại'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.timeline, size: 68, color: AppColors.neutralMid),
          const SizedBox(height: 10),
          Text(
            'Chưa có mốc cập nhật cho đơn này',
            style: AppTypography.bodyRegular1.copyWith(
              color: AppColors.neutralMid,
            ),
          ),
        ],
      ),
    );
  }
}

class _ThreadCard extends StatelessWidget {
  final NotificationItem item;
  final String createdAtText;
  final VoidCallback? onMarkRead;

  const _ThreadCard({
    required this.item,
    required this.createdAtText,
    required this.onMarkRead,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
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
                  style: AppTypography.subHeader.copyWith(
                    color: AppColors.neutralDark,
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
            style: AppTypography.bodyRegular1.copyWith(
              color: AppColors.neutralDark,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            createdAtText,
            style: AppTypography.bodyRegular1.copyWith(
              color: AppColors.neutralMid,
              fontSize: 12,
            ),
          ),
          if (onMarkRead != null) ...[
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerRight,
              child: OutlinedButton.icon(
                onPressed: onMarkRead,
                icon: const Icon(Icons.done_all, size: 18),
                label: const Text('Đánh dấu đã đọc'),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
