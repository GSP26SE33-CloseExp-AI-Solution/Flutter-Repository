import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../../core/router/app_router.dart';
import '../../domain/entities/delivery_group.dart';
import '../../domain/entities/delivery_order.dart';
import '../bloc/delivery_bloc.dart';
import '../bloc/delivery_event.dart';
import '../bloc/delivery_state.dart';

/// Delivery Group Details Page
class DeliveryGroupDetailsPage extends StatefulWidget {
  final String groupId;

  const DeliveryGroupDetailsPage({super.key, required this.groupId});

  @override
  State<DeliveryGroupDetailsPage> createState() =>
      _DeliveryGroupDetailsPageState();
}

class _DeliveryGroupDetailsPageState extends State<DeliveryGroupDetailsPage> {
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
      appBar: AppBar(
        title: const Text('Chi tiết nhóm giao'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadGroupDetails,
            tooltip: 'Làm mới',
          ),
        ],
      ),
      body: BlocConsumer<DeliveryBloc, DeliveryState>(
        listener: (context, state) {
          if (state is DeliveryStarted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Đã bắt đầu giao hàng'),
                backgroundColor: Colors.green,
              ),
            );
            _loadGroupDetails();
          } else if (state is DeliveryGroupCompleted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Đã hoàn thành nhóm giao'),
                backgroundColor: Colors.green,
              ),
            );
            context.pop();
          } else if (state is DeliveryConfirmed ||
              state is DeliveryFailureReported) {
            _loadGroupDetails();
          } else if (state is DeliveryError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: Colors.red,
              ),
            );
          }
        },
        builder: (context, state) {
          if (state is DeliveryLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state is GroupDetailsLoaded) {
            return _buildGroupDetails(state.group);
          }

          if (state is DeliveryError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, size: 64, color: Colors.red[300]),
                  const SizedBox(height: 16),
                  Text(state.message),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _loadGroupDetails,
                    child: const Text('Thử lại'),
                  ),
                ],
              ),
            );
          }

          return const SizedBox.shrink();
        },
      ),
    );
  }

  Widget _buildGroupDetails(DeliveryGroup group) {
    final dateFormat = DateFormat('dd/MM/yyyy');
    final currencyFormat = NumberFormat.currency(locale: 'vi_VN', symbol: '₫');

    return RefreshIndicator(
      onRefresh: () async => _loadGroupDetails(),
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Group Info Card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          group.groupCode,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        _buildStatusBadge(group.status),
                      ],
                    ),
                    const Divider(height: 24),
                    _buildInfoRow(
                      Icons.calendar_today,
                      'Ngày giao',
                      dateFormat.format(group.deliveryDate),
                    ),
                    _buildInfoRow(
                      Icons.access_time,
                      'Khung giờ',
                      group.timeSlotDisplay,
                    ),
                    _buildInfoRow(
                      Icons.location_on,
                      'Khu vực',
                      group.deliveryArea,
                    ),
                    _buildInfoRow(
                      Icons.local_shipping,
                      'Loại giao',
                      group.deliveryType,
                    ),
                    const Divider(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildStatItem(
                          'Tổng đơn',
                          group.totalOrders.toString(),
                          Colors.blue,
                        ),
                        _buildStatItem(
                          'Đã giao',
                          group.completedOrders.toString(),
                          Colors.green,
                        ),
                        _buildStatItem(
                          'Thất bại',
                          group.failedOrders.toString(),
                          Colors.red,
                        ),
                        _buildStatItem(
                          'Còn lại',
                          group.pendingOrders.toString(),
                          Colors.orange,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Action Buttons
            if (group.status == DeliveryGroupStatus.assigned)
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => _showStartDialog(group),
                  icon: const Icon(Icons.play_arrow),
                  label: const Text('Bắt đầu giao hàng'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.all(16),
                  ),
                ),
              ),

            if (group.status == DeliveryGroupStatus.inTransit &&
                group.allOrdersDone)
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => _showCompleteDialog(group),
                  icon: const Icon(Icons.check_circle),
                  label: const Text('Hoàn thành nhóm giao'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.all(16),
                  ),
                ),
              ),

            const SizedBox(height: 24),

            // Orders List
            Text(
              'Danh sách đơn hàng (${group.orders.length})',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),

            if (group.orders.isEmpty)
              const Card(
                child: Padding(
                  padding: EdgeInsets.all(32),
                  child: Center(child: Text('Không có đơn hàng')),
                ),
              )
            else
              ...group.orders.map(
                (order) => _buildOrderCard(order, currencyFormat),
              ),

            if (group.notes != null && group.notes!.isNotEmpty) ...[
              const SizedBox(height: 16),
              Card(
                color: Colors.yellow[50],
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      const Icon(Icons.note, color: Colors.orange),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          group.notes!,
                          style: const TextStyle(fontStyle: FontStyle.italic),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStatusBadge(DeliveryGroupStatus status) {
    Color color;
    switch (status) {
      case DeliveryGroupStatus.pending:
        color = Colors.blue;
      case DeliveryGroupStatus.assigned:
        color = Colors.orange;
      case DeliveryGroupStatus.inTransit:
        color = Colors.purple;
      case DeliveryGroupStatus.completed:
        color = Colors.green;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color),
      ),
      child: Text(
        status.displayName,
        style: TextStyle(color: color, fontWeight: FontWeight.w600),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.grey[600]),
          const SizedBox(width: 12),
          Text('$label: ', style: TextStyle(color: Colors.grey[600])),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(label, style: TextStyle(color: Colors.grey[600], fontSize: 12)),
      ],
    );
  }

  Widget _buildOrderCard(DeliveryOrder order, NumberFormat currencyFormat) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () => context.push(Routes.deliveryOrderDetails(order.orderId)),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    order.orderCode,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  _buildOrderStatusBadge(order.status),
                ],
              ),
              const Divider(height: 16),
              Row(
                children: [
                  const Icon(Icons.person, size: 16, color: Colors.grey),
                  const SizedBox(width: 8),
                  Text(order.customerName),
                ],
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  const Icon(Icons.phone, size: 16, color: Colors.grey),
                  const SizedBox(width: 8),
                  Text(order.customerPhone),
                ],
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  const Icon(Icons.location_on, size: 16, color: Colors.grey),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      order.destinationAddress,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const Divider(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '${order.totalItems} sản phẩm',
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                  Text(
                    currencyFormat.format(order.totalValue),
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.blue,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOrderStatusBadge(DeliveryOrderStatus status) {
    Color color;
    switch (status) {
      case DeliveryOrderStatus.pending:
      case DeliveryOrderStatus.paidProcessing:
        color = Colors.orange;
      case DeliveryOrderStatus.readyToShip:
        color = Colors.blue;
      case DeliveryOrderStatus.deliveredWaitConfirm:
        color = Colors.purple;
      case DeliveryOrderStatus.completed:
        color = Colors.green;
      case DeliveryOrderStatus.failed:
        color = Colors.red;
      case DeliveryOrderStatus.canceled:
      case DeliveryOrderStatus.refunded:
        color = Colors.grey;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        status.displayName,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  void _showStartDialog(DeliveryGroup group) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Bắt đầu giao hàng'),
        content: Text('Bắt đầu giao hàng cho nhóm "${group.groupCode}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              context.read<DeliveryBloc>().add(
                StartDelivery(groupId: group.deliveryGroupId),
              );
            },
            child: const Text('Bắt đầu'),
          ),
        ],
      ),
    );
  }

  void _showCompleteDialog(DeliveryGroup group) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hoàn thành nhóm giao'),
        content: Text('Xác nhận hoàn thành nhóm giao "${group.groupCode}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              context.read<DeliveryBloc>().add(
                CompleteDeliveryGroup(groupId: group.deliveryGroupId),
              );
            },
            child: const Text('Hoàn thành'),
          ),
        ],
      ),
    );
  }
}
