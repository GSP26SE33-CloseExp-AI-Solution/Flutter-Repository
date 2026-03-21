import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/router/app_router.dart';
import '../../domain/entities/delivery_group.dart';
import '../bloc/delivery_bloc.dart';
import '../bloc/delivery_event.dart';
import '../bloc/delivery_state.dart';
import '../widgets/widgets.dart';

/// My Deliveries Page - shows delivery groups assigned to current staff
class MyDeliveriesPage extends StatefulWidget {
  const MyDeliveriesPage({super.key});
  // TODO: Fix color the match app theme
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
        LoadMyGroups(page: state.currentPage + 1, status: _getCurrentStatus()),
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
        listener: _handleStateChange,
        builder: _buildBody,
      ),
    );
  }

  void _handleStateChange(BuildContext context, DeliveryState state) {
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
        SnackBar(content: Text(state.message), backgroundColor: Colors.red),
      );
    } else if (state is DeliveryActionError) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(state.message), backgroundColor: Colors.red),
      );
      _loadGroups(refresh: true);
    }
  }

  Widget _buildBody(BuildContext context, DeliveryState state) {
    if (state is DeliveryLoading) {
      return const DeliveryLoadingState(message: 'Đang tải...');
    }

    if (state is MyGroupsLoaded) {
      if (state.isEmpty) {
        return DeliveryEmptyState(
          icon: Icons.delivery_dining_outlined,
          title: 'Chưa có đơn hàng nào',
          subtitle: 'Nhận đơn từ tab "Đơn có sẵn" để bắt đầu',
          actionLabel: 'Làm mới',
          onAction: () => _loadGroups(refresh: true),
        );
      }
      return _buildGroupsList(state);
    }

    if (state is DeliveryError) {
      return DeliveryErrorState(
        message: state.message,
        onRetry: () => _loadGroups(refresh: true),
      );
    }

    return const SizedBox.shrink();
  }

  Widget _buildGroupsList(MyGroupsLoaded state) {
    return RefreshIndicator(
      onRefresh: () async => _loadGroups(refresh: true),
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
                ? () => _handleStartDelivery(group)
                : null,
            onComplete:
                group.status == DeliveryGroupStatus.inTransit &&
                    group.pendingOrders == 0
                ? () => _handleCompleteGroup(group)
                : null,
          );
        },
      ),
    );
  }

  void _handleStartDelivery(DeliveryGroupSummary group) async {
    final confirmed = await showDeliveryConfirmDialog(
      context: context,
      title: 'Bắt đầu giao hàng',
      content:
          'Bắt đầu giao hàng cho nhóm "${group.groupCode}"?\n\n'
          '• Số đơn: ${group.totalOrders}\n'
          '• Khu vực: ${group.deliveryArea}',
      confirmLabel: 'Bắt đầu',
    );
    if (confirmed == true && mounted) {
      context.read<DeliveryBloc>().add(
        StartDelivery(groupId: group.deliveryGroupId),
      );
    }
  }

  void _handleCompleteGroup(DeliveryGroupSummary group) async {
    final confirmed = await showDeliveryConfirmDialog(
      context: context,
      title: 'Hoàn thành nhóm giao',
      content:
          'Xác nhận hoàn thành nhóm giao "${group.groupCode}"?\n\n'
          '• Đã giao: ${group.completedOrders}/${group.totalOrders}',
      confirmLabel: 'Hoàn thành',
    );
    if (confirmed == true && mounted) {
      context.read<DeliveryBloc>().add(
        CompleteDeliveryGroup(groupId: group.deliveryGroupId),
      );
    }
  }
}
