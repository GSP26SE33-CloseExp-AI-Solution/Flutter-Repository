import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../domain/entities/delivery_stats.dart';
import '../bloc/delivery_bloc.dart';
import '../bloc/delivery_event.dart';
import '../bloc/delivery_state.dart';

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
      appBar: AppBar(
        title: const Text('Thống kê giao hàng'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadStats,
            tooltip: 'Làm mới',
          ),
        ],
      ),
      body: BlocBuilder<DeliveryBloc, DeliveryState>(
        builder: (context, state) {
          if (state is DeliveryLoading) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Đang tải thống kê...'),
                ],
              ),
            );
          }

          if (state is DeliveryStatsLoaded) {
            return _buildStatsContent(state.stats);
          }

          if (state is DeliveryError) {
            return _buildErrorState(state.message);
          }

          return const SizedBox.shrink();
        },
      ),
    );
  }

  Widget _buildErrorState(String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 80, color: Colors.red[300]),
          const SizedBox(height: 16),
          Text(
            message,
            style: TextStyle(fontSize: 16, color: Colors.grey[600]),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _loadStats,
            icon: const Icon(Icons.refresh),
            label: const Text('Thử lại'),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsContent(DeliveryStats stats) {
    return RefreshIndicator(
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
            const Text(
              'Tổng quan',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            _buildOverviewCards(stats),
            const SizedBox(height: 20),

            // Order breakdown
            const Text(
              'Chi tiết đơn hàng',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            _buildOrderBreakdown(stats),
            const SizedBox(height: 20),

            // Quick actions
            const Text(
              'Thao tác nhanh',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            _buildQuickActions(),
          ],
        ),
      ),
    );
  }

  Widget _buildStaffInfoCard(DeliveryStats stats) {
    final dateFormat = DateFormat('dd/MM/yyyy HH:mm');
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            CircleAvatar(
              radius: 32,
              backgroundColor: Colors.blue[100],
              child: Icon(Icons.person, size: 36, color: Colors.blue[700]),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    stats.deliveryStaffName,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Nhân viên giao hàng',
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                  if (stats.lastDeliveryAt != null)
                    Text(
                      'Giao hàng gần nhất: ${dateFormat.format(stats.lastDeliveryAt!)}',
                      style: TextStyle(
                        color: Colors.grey[500],
                        fontSize: 12,
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
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
            Colors.blue,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatCard(
            'Tổng đơn hàng',
            stats.totalOrders.toString(),
            Icons.shopping_bag,
            Colors.purple,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatCard(
            'Tỷ lệ thành công',
            stats.successRateDisplay,
            Icons.trending_up,
            stats.completionRate >= 80 ? Colors.green : Colors.orange,
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Icon(icon, color: color, size: 32),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOrderBreakdown(DeliveryStats stats) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _buildBreakdownRow(
              'Hoàn thành',
              stats.completedOrders,
              stats.totalOrders,
              Colors.green,
            ),
            const Divider(),
            _buildBreakdownRow(
              'Đang xử lý',
              stats.pendingOrders,
              stats.totalOrders,
              Colors.orange,
            ),
            const Divider(),
            _buildBreakdownRow(
              'Đang giao',
              stats.inTransitOrders,
              stats.totalOrders,
              Colors.blue,
            ),
            const Divider(),
            _buildBreakdownRow(
              'Thất bại',
              stats.failedOrders,
              stats.totalOrders,
              Colors.red,
            ),
          ],
        ),
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
            child: Text(label),
          ),
          Text(
            '$count',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: 100,
            child: LinearProgressIndicator(
              value: percentage / 100,
              backgroundColor: Colors.grey[200],
              valueColor: AlwaysStoppedAnimation<Color>(color),
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: 50,
            child: Text(
              '${percentage.toStringAsFixed(1)}%',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
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
          Colors.blue,
          () => context.push('/delivery/history'),
        ),
        const SizedBox(height: 8),
        _buildActionCard(
          'Danh sách nhóm giao hàng',
          'Quản lý các nhóm đang giao',
          Icons.list_alt,
          Colors.green,
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
    return Card(
      child: ListTile(
        onTap: onTap,
        leading: CircleAvatar(
          backgroundColor: color.withOpacity(0.1),
          child: Icon(icon, color: color),
        ),
        title: Text(title),
        subtitle: Text(subtitle),
        trailing: Icon(Icons.chevron_right, color: Colors.grey[400]),
      ),
    );
  }
}
