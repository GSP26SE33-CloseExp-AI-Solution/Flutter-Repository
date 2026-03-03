import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/router/app_router.dart';
import '../../domain/entities/delivery_group.dart';
import '../bloc/delivery_bloc.dart';
import '../bloc/delivery_event.dart';
import '../bloc/delivery_state.dart';
import '../widgets/delivery_group_card.dart';

/// Available Groups Page - shows delivery groups available to accept
class AvailableGroupsPage extends StatefulWidget {
  const AvailableGroupsPage({super.key});

  @override
  State<AvailableGroupsPage> createState() => _AvailableGroupsPageState();
}

class _AvailableGroupsPageState extends State<AvailableGroupsPage> {
  @override
  void initState() {
    super.initState();
    _loadGroups();
  }

  void _loadGroups() {
    context.read<DeliveryBloc>().add(const LoadAvailableGroups());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Đơn hàng có sẵn'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadGroups,
            tooltip: 'Làm mới',
          ),
        ],
      ),
      body: BlocConsumer<DeliveryBloc, DeliveryState>(
        listener: (context, state) {
          if (state is DeliveryGroupAccepted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Đã nhận đơn ${state.group.groupCode}'),
                backgroundColor: Colors.green,
              ),
            );
            // Reload available groups
            _loadGroups();
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
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Đang tải...'),
                ],
              ),
            );
          }

          if (state is AvailableGroupsLoaded) {
            if (state.isEmpty) {
              return _buildEmptyState();
            }
            return _buildGroupsList(state.groups);
          }

          if (state is DeliveryError) {
            return _buildErrorState(state.message);
          }

          return const SizedBox.shrink();
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.inbox_outlined, size: 80, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            'Không có đơn hàng có sẵn',
            style: TextStyle(fontSize: 18, color: Colors.grey[600]),
          ),
          const SizedBox(height: 8),
          Text(
            'Hãy quay lại sau để kiểm tra đơn mới',
            style: TextStyle(color: Colors.grey[500]),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _loadGroups,
            icon: const Icon(Icons.refresh),
            label: const Text('Làm mới'),
          ),
        ],
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
            onPressed: _loadGroups,
            icon: const Icon(Icons.refresh),
            label: const Text('Thử lại'),
          ),
        ],
      ),
    );
  }

  Widget _buildGroupsList(List<DeliveryGroupSummary> groups) {
    return RefreshIndicator(
      onRefresh: () async {
        _loadGroups();
      },
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: groups.length,
        itemBuilder: (context, index) {
          final group = groups[index];
          return DeliveryGroupCard(
            group: group,
            onTap: () => context.push(
              Routes.deliveryGroupDetails(group.deliveryGroupId),
            ),
            onAccept: () => _showAcceptDialog(group),
          );
        },
      ),
    );
  }

  void _showAcceptDialog(DeliveryGroupSummary group) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xác nhận nhận đơn'),
        content: Text(
          'Bạn có chắc muốn nhận nhóm giao "${group.groupCode}"?\n\n'
          '• Khu vực: ${group.deliveryArea}\n'
          '• Thời gian: ${group.timeSlotDisplay}\n'
          '• Số đơn: ${group.totalOrders}',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              context.read<DeliveryBloc>().add(
                AcceptDeliveryGroup(groupId: group.deliveryGroupId),
              );
            },
            child: const Text('Nhận đơn'),
          ),
        ],
      ),
    );
  }
}
