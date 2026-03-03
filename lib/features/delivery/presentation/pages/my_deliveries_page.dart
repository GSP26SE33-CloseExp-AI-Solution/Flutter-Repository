import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/router/app_router.dart';
import '../../domain/entities/delivery_group.dart';
import '../bloc/delivery_bloc.dart';
import '../bloc/delivery_event.dart';
import '../bloc/delivery_state.dart';
import '../widgets/delivery_group_card.dart';

/// My Deliveries Page - shows delivery groups assigned to current staff
class MyDeliveriesPage extends StatefulWidget {
  const MyDeliveriesPage({super.key});

  @override
  State<MyDeliveriesPage> createState() => _MyDeliveriesPageState();
}

class _MyDeliveriesPageState extends State<MyDeliveriesPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(_onTabChanged);
    _scrollController.addListener(_onScroll);
    _loadGroups();
  }

  @override
  void dispose() {
    _tabController.removeListener(_onTabChanged);
    _tabController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _onTabChanged() {
    if (_tabController.indexIsChanging) return;
    _loadGroups(refresh: true);
  }

  void _onScroll() {
    final state = context.read<DeliveryBloc>().state;
    if (state is MyGroupsLoaded &&
        state.hasNextPage &&
        !state.isLoadingMore &&
        _scrollController.position.pixels >=
            _scrollController.position.maxScrollExtent - 200) {
      context.read<DeliveryBloc>().add(
            LoadMyGroups(
              page: state.currentPage + 1,
              status: _getCurrentStatus(),
            ),
          );
    }
  }

  String? _getCurrentStatus() {
    switch (_tabController.index) {
      case 0:
        return null; // All
      case 1:
        return 'InProgress';
      case 2:
        return 'Completed';
      default:
        return null;
    }
  }

  void _loadGroups({bool refresh = false}) {
    context.read<DeliveryBloc>().add(
          LoadMyGroups(status: _getCurrentStatus(), refresh: refresh),
        );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Đơn hàng của tôi'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          indicatorColor: Colors.white,
          tabs: const [
            Tab(text: 'Tất cả'),
            Tab(text: 'Đang giao'),
            Tab(text: 'Hoàn thành'),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => _loadGroups(refresh: true),
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
            _loadGroups(refresh: true);
          } else if (state is DeliveryGroupCompleted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Đã hoàn thành nhóm giao'),
                backgroundColor: Colors.green,
              ),
            );
            _loadGroups(refresh: true);
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

          if (state is MyGroupsLoaded) {
            if (state.isEmpty) {
              return _buildEmptyState();
            }
            return _buildGroupsList(state);
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
          Icon(Icons.delivery_dining_outlined, size: 80, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            'Chưa có đơn hàng nào',
            style: TextStyle(fontSize: 18, color: Colors.grey[600]),
          ),
          const SizedBox(height: 8),
          Text(
            'Nhận đơn từ tab "Đơn có sẵn" để bắt đầu',
            style: TextStyle(color: Colors.grey[500]),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () => _loadGroups(refresh: true),
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
            onPressed: () => _loadGroups(refresh: true),
            icon: const Icon(Icons.refresh),
            label: const Text('Thử lại'),
          ),
        ],
      ),
    );
  }

  Widget _buildGroupsList(MyGroupsLoaded state) {
    return RefreshIndicator(
      onRefresh: () async {
        _loadGroups(refresh: true);
      },
      child: ListView.builder(
        controller: _scrollController,
        padding: const EdgeInsets.all(16),
        itemCount: state.groups.length + (state.isLoadingMore ? 1 : 0),
        itemBuilder: (context, index) {
          if (index == state.groups.length) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: CircularProgressIndicator(),
              ),
            );
          }

          final group = state.groups[index];
          return DeliveryGroupCard(
            group: group,
            showAcceptButton: false,
            onTap: () => context.push(
              Routes.deliveryGroupDetails(group.deliveryGroupId),
            ),
            onStart: group.status == DeliveryGroupStatus.assigned
                ? () => _showStartDialog(group)
                : null,
            onComplete: group.status == DeliveryGroupStatus.inTransit &&
                    group.pendingOrders == 0
                ? () => _showCompleteDialog(group)
                : null,
          );
        },
      ),
    );
  }

  void _showStartDialog(DeliveryGroupSummary group) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Bắt đầu giao hàng'),
        content: Text(
          'Bắt đầu giao hàng cho nhóm "${group.groupCode}"?\n\n'
          '• Số đơn: ${group.totalOrders}\n'
          '• Khu vực: ${group.deliveryArea}',
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
                    StartDelivery(groupId: group.deliveryGroupId),
                  );
            },
            child: const Text('Bắt đầu'),
          ),
        ],
      ),
    );
  }

  void _showCompleteDialog(DeliveryGroupSummary group) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hoàn thành nhóm giao'),
        content: Text(
          'Xác nhận hoàn thành nhóm giao "${group.groupCode}"?\n\n'
          '• Đã giao: ${group.completedOrders}/${group.totalOrders}',
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
