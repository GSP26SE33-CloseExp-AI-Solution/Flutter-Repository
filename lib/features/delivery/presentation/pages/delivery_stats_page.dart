import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../domain/entities/delivery_stats.dart';
import '../bloc/delivery_bloc.dart';
import '../bloc/delivery_event.dart';
import '../bloc/delivery_state.dart';
import '../widgets/widgets.dart';

/// Delivery Stats Page - shows delivery performance statistics
class DeliveryStatsPage extends StatefulWidget {
  const DeliveryStatsPage({super.key});

  @override
  State<DeliveryStatsPage> createState() => _DeliveryStatsPageState();
}

class _DeliveryStatsPageState extends State<DeliveryStatsPage> {
  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  void _loadStats() {
    context.read<DeliveryBloc>().add(const LoadDeliveryStats());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: GradientAppBar(
        title: 'Thống kê giao hàng',
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            color: AppColors.headerGradientEnd,
            onPressed: _loadStats,
            tooltip: 'Làm mới',
          ),
        ],
      ),
      body: BlocBuilder<DeliveryBloc, DeliveryState>(
        builder: (context, state) {
          if (state is DeliveryLoading) {
            return const DeliveryLoadingState(message: 'Đang tải thống kê...');
          }

          if (state is DeliveryStatsLoaded) {
            return _buildStatsContent(state.stats);
          }

          if (state is DeliveryError) {
            return DeliveryErrorState(
              message: state.message,
              onRetry: _loadStats,
            );
          }

          return const SizedBox.shrink();
        },
      ),
    );
  }

  Widget _buildStatsContent(DeliveryStats stats) {
    return RefreshIndicator(
      color: AppColors.headerGradientEnd,
      onRefresh: () async => _loadStats(),
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Staff info card
            _buildStaffInfoCard(stats),
            const SizedBox(height: 20),

            // Main stats cards
            Text('Tổng quan', style: AppTypography.subHeader),
            const SizedBox(height: 12),
            _buildOverviewCards(stats),
            const SizedBox(height: 20),

            // Order breakdown
            Text('Chi tiết đơn hàng', style: AppTypography.subHeader),
            const SizedBox(height: 12),
            _buildOrderBreakdown(stats),
            const SizedBox(height: 20),

            // Quick actions
            Text('Thao tác nhanh', style: AppTypography.subHeader),
            const SizedBox(height: 12),
            _buildQuickActions(),
          ],
        ),
      ),
    );
  }

  Widget _buildStaffInfoCard(DeliveryStats stats) {
    final dateFormat = DateFormat('dd/MM/yyyy HH:mm');
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
      child: Row(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.person, size: 36, color: AppColors.primary),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  stats.deliveryStaffName,
                  style: AppTypography.subHeader.copyWith(
                    fontSize: 18,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Nhân viên giao hàng',
                  style: AppTypography.header3.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
                if (stats.lastDeliveryAt != null)
                  Text(
                    'Giao hàng gần nhất: ${dateFormat.format(stats.lastDeliveryAt!)}',
                    style: AppTypography.bodyRegular1.copyWith(
                      color: AppColors.textSecondary,
                      fontSize: 12,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOverviewCards(DeliveryStats stats) {
    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            'Nhóm giao hàng',
            stats.totalAssignedGroups.toString(),
            Icons.group_work,
            AppColors.accent,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatCard(
            'Tổng đơn hàng',
            stats.totalOrders.toString(),
            Icons.shopping_bag,
            AppColors.primary,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatCard(
            'Tỷ lệ thành công',
            stats.successRateDisplay,
            Icons.trending_up,
            stats.completionRate >= 80
                ? AppColors.successGradientStart
                : AppColors.primaryGradientStart,
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
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
        children: [
          Icon(icon, color: color, size: 32),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontFamily: 'DM Sans',
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: AppTypography.bodyRegular1.copyWith(
              fontSize: 12,
              color: AppColors.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildOrderBreakdown(DeliveryStats stats) {
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
        children: [
          _buildBreakdownRow(
            'Hoàn thành',
            stats.completedOrders,
            stats.totalOrders,
            AppColors.successGradientStart,
          ),
          const Divider(color: AppColors.cardBorder),
          _buildBreakdownRow(
            'Đang xử lý',
            stats.pendingOrders,
            stats.totalOrders,
            AppColors.primaryGradientStart,
          ),
          const Divider(color: AppColors.cardBorder),
          _buildBreakdownRow(
            'Đang giao',
            stats.inTransitOrders,
            stats.totalOrders,
            AppColors.accent,
          ),
          const Divider(color: AppColors.cardBorder),
          _buildBreakdownRow(
            'Thất bại',
            stats.failedOrders,
            stats.totalOrders,
            AppColors.error,
          ),
        ],
      ),
    );
  }

  Widget _buildBreakdownRow(String label, int count, int total, Color color) {
    final percentage = total > 0 ? (count / total) * 100 : 0.0;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(6),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: AppTypography.header3.copyWith(
                color: AppColors.textPrimary,
              ),
            ),
          ),
          Text(
            '$count',
            style: AppTypography.header3.copyWith(
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: 100,
            child: LinearProgressIndicator(
              value: percentage / 100,
              backgroundColor: AppColors.cardBorder,
              valueColor: AlwaysStoppedAnimation<Color>(color),
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: 50,
            child: Text(
              '${percentage.toStringAsFixed(1)}%',
              style: AppTypography.bodyRegular1.copyWith(
                fontSize: 12,
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions() {
    return Column(
      children: [
        _buildActionCard(
          'Xem lịch sử giao hàng',
          'Xem các đơn đã hoàn thành',
          Icons.history,
          AppColors.accent,
          () => context.push('/delivery/history'),
        ),
        const SizedBox(height: 8),
        _buildActionCard(
          'Danh sách nhóm giao hàng',
          'Quản lý các nhóm đang giao',
          Icons.list_alt,
          AppColors.successGradientStart,
          () => context.push('/delivery'),
        ),
      ],
    );
  }

  Widget _buildActionCard(
    String title,
    String subtitle,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: AppColors.cardBorder),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ListTile(
        onTap: onTap,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: color),
        ),
        title: Text(
          title,
          style: AppTypography.header3.copyWith(
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: AppTypography.bodyRegular1.copyWith(
            color: AppColors.textSecondary,
            fontSize: 13,
          ),
        ),
        trailing: Icon(Icons.chevron_right, color: AppColors.textSecondary),
      ),
    );
  }
}
