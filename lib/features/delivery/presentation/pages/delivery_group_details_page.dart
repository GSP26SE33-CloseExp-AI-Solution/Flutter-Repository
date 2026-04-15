import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/router/app_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../domain/entities/delivery_group.dart';
import '../bloc/delivery_bloc.dart';
import '../bloc/delivery_event.dart';
import '../bloc/delivery_state.dart';
import '../widgets/widgets.dart';

/// Screen 3 — Delivery Group Details: order list at a delivery point.
class DeliveryGroupDetailsPage extends StatefulWidget {
  final String groupId;

  const DeliveryGroupDetailsPage({super.key, required this.groupId});

  @override
  State<DeliveryGroupDetailsPage> createState() =>
      _DeliveryGroupDetailsPageState();
}

class _DeliveryGroupDetailsPageState extends State<DeliveryGroupDetailsPage> {
  String? _pendingMapGroupId;

  @override
  void initState() {
    super.initState();
    _loadGroupDetails();
  }

  void _loadGroupDetails() {
    context.read<DeliveryBloc>().add(LoadGroupDetails(groupId: widget.groupId));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: GradientAppBar(
        title: 'Chi tiết nhóm giao',
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            color: AppColors.headerGradientEnd,
            onPressed: _loadGroupDetails,
            tooltip: 'Làm mới',
          ),
        ],
      ),
      body: BlocConsumer<DeliveryBloc, DeliveryState>(
        listener: _handleStateChange,
        builder: _buildBody,
      ),
    );
  }

  void _handleStateChange(BuildContext context, DeliveryState state) {
    if (state is DeliveryStarted) {
      final startedGroupId = state.group.deliveryGroupId.trim();
      final shouldOpenMap =
          _pendingMapGroupId != null && _pendingMapGroupId == startedGroupId;
      _pendingMapGroupId = null;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Đã bắt đầu giao hàng'),
          backgroundColor: AppColors.successGradientEnd,
        ),
      );

      if (shouldOpenMap && mounted) {
        context.push(
          '${Routes.deliveryMap}?groupId=${Uri.encodeComponent(startedGroupId)}',
        );
      }

      _loadGroupDetails();
    } else if (state is DeliveryGroupCompleted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Đã hoàn thành nhóm giao'),
          backgroundColor: AppColors.successGradientEnd,
        ),
      );
      context.pop();
    } else if (state is DeliveryConfirmed || state is DeliveryFailureReported) {
      _loadGroupDetails();
    } else if (state is DeliveryError) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(state.message),
          backgroundColor: AppColors.error,
        ),
      );
    } else if (state is DeliveryActionError) {
      _pendingMapGroupId = null;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(state.message),
          backgroundColor: AppColors.error,
        ),
      );
      _loadGroupDetails();
    }
  }

  Widget _buildBody(BuildContext context, DeliveryState state) {
    if (state is DeliveryLoading) return const DeliveryLoadingState();

    if (state is GroupDetailsLoaded) {
      return _GroupDetailsContent(
        group: state.group,
        onRefresh: _loadGroupDetails,
        onStartDelivery: _handleStartDelivery,
        onCompleteGroup: _handleCompleteGroup,
      );
    }

    if (state is DeliveryError) {
      return DeliveryErrorState(
        message: state.message,
        onRetry: _loadGroupDetails,
        secondaryActionLabel: 'Quay về bản đồ',
        onSecondaryAction: () => context.push(
          '${Routes.deliveryMap}?groupId=${Uri.encodeComponent(widget.groupId)}',
        ),
      );
    }

    return const SizedBox.shrink();
  }

  void _handleStartDelivery(DeliveryGroup group) async {
    final confirmed = await showDeliveryConfirmDialog(
      context: context,
      title: 'Bắt đầu giao hàng',
      content: 'Bắt đầu giao hàng cho nhóm "${group.groupCode}"?',
      confirmLabel: 'Bắt đầu',
      confirmColor: AppColors.successGradientEnd,
    );
    if (confirmed == true && mounted) {
      final gid = group.deliveryGroupId.trim();
      if (gid.isNotEmpty) {
        _pendingMapGroupId = gid;
        context.read<DeliveryBloc>().add(StartDelivery(groupId: gid));
      }
    }
  }

  void _handleCompleteGroup(DeliveryGroup group) async {
    final confirmed = await showDeliveryConfirmDialog(
      context: context,
      title: 'Hoàn thành nhóm giao',
      content: 'Xác nhận hoàn thành nhóm giao "${group.groupCode}"?',
      confirmLabel: 'Hoàn thành',
    );
    if (confirmed == true && mounted) {
      context.read<DeliveryBloc>().add(
        CompleteDeliveryGroup(groupId: group.deliveryGroupId),
      );
    }
  }
}

// ── Content widget ──────────────────────────────────────────────────────────

class _GroupDetailsContent extends StatelessWidget {
  final DeliveryGroup group;
  final VoidCallback onRefresh;
  final void Function(DeliveryGroup) onStartDelivery;
  final void Function(DeliveryGroup) onCompleteGroup;

  const _GroupDetailsContent({
    required this.group,
    required this.onRefresh,
    required this.onStartDelivery,
    required this.onCompleteGroup,
  });

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      color: AppColors.headerGradientEnd,
      onRefresh: () async => onRefresh(),
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildGroupInfoCard(),
            const SizedBox(height: 16),
            _buildActionButtons(),
            const SizedBox(height: 24),
            _buildOrdersSection(context),
            if (group.notes != null && group.notes!.isNotEmpty) ...[
              const SizedBox(height: 16),
              DeliveryNoteCard(note: group.notes!),
            ],
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildGroupInfoCard() {
    final dateFormat = DateFormat('dd/MM/yyyy');

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
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
          // Header
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: ClipRect(
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    physics: const BouncingScrollPhysics(),
                    child: Text(
                      group.groupCode,
                      style: AppTypography.header2.copyWith(
                        fontFamily: 'DM Sans',
                        fontSize: 20,
                        color: AppColors.textPrimary,
                      ),
                      maxLines: 1,
                      softWrap: false,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              DeliveryGroupStatusBadge(status: group.status, compact: true),
            ],
          ),

          const Divider(height: 24, color: AppColors.cardBorder),

          DeliveryInfoRow(
            icon: Icons.calendar_today,
            label: 'Ngày giao',
            value: dateFormat.format(group.deliveryDate),
          ),
          DeliveryInfoRow(
            icon: Icons.access_time,
            label: 'Khung giờ',
            value: group.timeSlotDisplay,
          ),
          DeliveryInfoRow(
            icon: Icons.location_on,
            label: 'Khu vực',
            value: group.deliveryArea,
          ),
          DeliveryInfoRow(
            icon: Icons.local_shipping,
            label: 'Loại giao',
            value: group.deliveryType,
          ),

          const Divider(height: 24, color: AppColors.cardBorder),

          // Stats row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              DeliveryStatItem(
                label: 'Tổng đơn',
                value: group.totalOrders.toString(),
                color: AppColors.textPrimary,
              ),
              DeliveryStatItem(
                label: 'Đã giao',
                value: group.completedOrders.toString(),
                color: AppColors.successGradientStart,
              ),
              DeliveryStatItem(
                label: 'Thất bại',
                value: group.failedOrders.toString(),
                color: AppColors.error,
              ),
              DeliveryStatItem(
                label: 'Còn lại',
                value: group.pendingOrders.toString(),
                color: AppColors.headerGradientEnd,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    return Column(
      children: [
        if (group.status == DeliveryGroupStatus.assigned)
          AppGradientButton(
            onPressed: () => onStartDelivery(group),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.play_arrow, color: Colors.white, size: 20),
                const SizedBox(width: 8),
                Text(
                  'Bắt đầu giao hàng',
                  style: AppTypography.header3.copyWith(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),

        if (group.status == DeliveryGroupStatus.inTransit &&
            group.allOrdersDone) ...[
          if (group.status == DeliveryGroupStatus.assigned)
            const SizedBox(height: 12),
          _SuccessButton(
            onPressed: () => onCompleteGroup(group),
            label: 'Hoàn thành nhóm giao',
            icon: Icons.check_circle,
          ),
        ],
      ],
    );
  }

  Widget _buildOrdersSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        DeliverySectionHeader(
          title: 'Danh sách đơn hàng (${group.orders.length})',
        ),
        const SizedBox(height: 12),
        if (group.orders.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: AppColors.cardSurface,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Center(
              child: Text(
                'Không có đơn hàng',
                style: AppTypography.header3.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ),
          )
        else
          ...group.orders.map(
            (order) => DeliveryOrderCard(
              order: order,
              onTap: () => context.push(
                Routes.deliveryOrderDetails(
                  order.orderId,
                  groupId: group.deliveryGroupId,
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _SuccessButton extends StatelessWidget {
  final VoidCallback onPressed;
  final String label;
  final IconData icon;

  const _SuccessButton({
    required this.onPressed,
    required this.label,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [
              AppColors.successGradientStart,
              AppColors.successGradientEnd,
            ],
          ),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          child: InkWell(
            onTap: onPressed,
            borderRadius: BorderRadius.circular(20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, color: Colors.white, size: 20),
                const SizedBox(width: 8),
                Text(
                  label,
                  style: AppTypography.header3.copyWith(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
