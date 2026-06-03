import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/api_constants.dart';
import '../../../../core/router/app_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../injection_container.dart';
import '../../domain/entities/delivery_group.dart';
import '../../domain/services/shipper_location_service.dart';
import '../bloc/delivery_bloc.dart';
import '../bloc/delivery_event.dart';
import '../bloc/delivery_state.dart';
import '../widgets/widgets.dart';

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
  final ShipperLocationService _shipperLocationService =
      sl<ShipperLocationService>();
  String? _pendingMapGroupId;
  String _selectedSortBy = ApiConstants.deliveryGroupSortBalanced;
  bool _useWorkQueueMode = true;
  int _workQueueLimit = 10;
  ({double latitude, double longitude})? _shipperLocation;
  bool _isResolvingLocation = false;

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
        !state.isWorkQueue &&
        state.hasNextPage &&
        !state.isLoadingMore &&
        _scrollController.position.pixels >=
            _scrollController.position.maxScrollExtent - 200) {
      context.read<DeliveryBloc>().add(
        LoadMyGroups(
          page: state.currentPage + 1,
          status: _getCurrentStatus(),
          sortBy: _effectiveSortBy,
          currentLatitude: _shipperLocation?.latitude,
          currentLongitude: _shipperLocation?.longitude,
        ),
      );
    }
  }

  String? _getCurrentStatus() {
    switch (_tabController.index) {
      case 0:
        return null; // ALl
      case 1:
        return DeliveryGroupStatus.inTransit.toApiString();
      case 2:
        return ApiConstants.deliveryMyGroupsStatusDone;
      default:
        return null;
    }
  }

  String get _effectiveSortBy =>
      _isCompletedTab ? ApiConstants.deliveryGroupSortRecentFirst : _selectedSortBy;

  bool get _isCompletedTab => _tabController.index == 2;

  bool get _isLocationPreferredSort =>
      _selectedSortBy == ApiConstants.deliveryGroupSortDistanceFirst ||
      _selectedSortBy == ApiConstants.deliveryGroupSortBalanced;

  bool get _shouldResolveLocation => _isLocationPreferredSort;

  bool get _effectiveWorkQueueMode => _useWorkQueueMode && !_isCompletedTab;

  Future<void> _loadGroups({bool refresh = false}) async {
    if (_shouldResolveLocation) {
      await _resolveShipperLocation();
    }

    if (!mounted) {
      return;
    }

    if (_effectiveWorkQueueMode) {
      context.read<DeliveryBloc>().add(
        LoadMyWorkQueue(
          limit: _workQueueLimit,
          status: _getCurrentStatus(),
          sortBy: _effectiveSortBy,
          currentLatitude: _shipperLocation?.latitude,
          currentLongitude: _shipperLocation?.longitude,
          refresh: refresh,
        ),
      );
      return;
    }

    context.read<DeliveryBloc>().add(
      LoadMyGroups(
        status: _getCurrentStatus(),
        refresh: refresh,
        sortBy: _effectiveSortBy,
        currentLatitude: _shipperLocation?.latitude,
        currentLongitude: _shipperLocation?.longitude,
      ),
    );
  }

  Future<void> _resolveShipperLocation() async {
    if (_isResolvingLocation) {
      return;
    }

    setState(() {
      _isResolvingLocation = true;
    });

    final result = await _shipperLocationService.resolveCurrentLocation();
    if (!mounted) {
      return;
    }

    setState(() {
      _shipperLocation = result.location;
      _isResolvingLocation = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(kToolbarHeight + 48),
        child: AppBar(
          backgroundColor: Colors.transparent,
          foregroundColor: Colors.white,
          elevation: 0,
          flexibleSpace: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppColors.headerGradientStart,
                  AppColors.headerGradientEnd,
                ],
              ),
            ),
          ),
          title: Text(
            'Đơn hàng của tôi',
            style: AppTypography.header1.copyWith(
              fontSize: 20,
              color: Colors.white,
              letterSpacing: -0.60,
            ),
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh),
              color: AppColors.neutralLight,
              onPressed: () {
                _loadGroups(refresh: true);
              },
              tooltip: 'Làm mới',
            ),
          ],
          bottom: TabBar(
            controller: _tabController,
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white.withValues(alpha: 0.7),
            indicatorColor: Colors.white,
            labelStyle: AppTypography.header3.copyWith(
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
            unselectedLabelStyle: AppTypography.header3.copyWith(
              color: Colors.white.withValues(alpha: 0.7),
            ),
            tabs: const [
              Tab(text: 'Tất cả'),
              Tab(text: 'Đang giao'),
              Tab(text: 'Đã xong'),
            ],
          ),
        ),
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
        context.pushReplacement(
          '${Routes.deliveryMap}?groupId=${Uri.encodeComponent(startedGroupId)}',
        );
      }

      if (!shouldOpenMap) {
        _loadGroups(refresh: true);
      }
    } else if (state is DeliveryGroupCompleted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Đã hoàn thành nhóm giao'),
          backgroundColor: AppColors.successGradientEnd,
        ),
      );
      _loadGroups(refresh: true);
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
      _loadGroups(refresh: true);
    }
  }

  Widget _buildBody(BuildContext context, DeliveryState state) {
    if (state is DeliveryLoading) {
      return const DeliveryLoadingState(message: 'Đang tải...');
    }

    if (state is MyGroupsLoaded) {
      if (state.isEmpty) {
        return Column(
          children: [
            _buildQueryControls(state),
            Expanded(
              child: DeliveryEmptyState(
                icon: Icons.delivery_dining_outlined,
                title: 'Chưa có đơn hàng nào',
                subtitle: 'Nhận đơn từ tab "Đơn có sẵn" để bắt đầu',
                actionLabel: 'Làm mới',
                onAction: () {
                  _loadGroups(refresh: true);
                },
              ),
            ),
          ],
        );
      }
      return _buildGroupsList(state);
    }

    if (state is DeliveryError) {
      return DeliveryErrorState(
        message: state.message,
        onRetry: () {
          _loadGroups(refresh: true);
        },
      );
    }

    return const SizedBox.shrink();
  }

  Widget _buildGroupsList(MyGroupsLoaded state) {
    return RefreshIndicator(
      color: AppColors.headerGradientEnd,
      onRefresh: () => _loadGroups(refresh: true),
      child: ListView(
        controller: _scrollController,
        padding: const EdgeInsets.all(16),
        children: [
          _buildQueryControls(state),
          const SizedBox(height: 12),
          ...state.groups.map((group) {
            return DeliveryGroupCard(
              group: group,
              showAcceptButton: false,
              onTap: () => context.push(
                Routes.deliveryGroupDetails(group.deliveryGroupId),
              ),
              onStart: group.status == DeliveryGroupStatus.assigned
                  ? () => _handleStartDelivery(group)
                  : null,
              onComplete: group.status == DeliveryGroupStatus.inTransit
                  ? () => _handleCompleteGroup(group)
                  : null,
            );
          }),
          if (state.isLoadingMore)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: CircularProgressIndicator(color: AppColors.primary),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildQueryControls(MyGroupsLoaded state) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.cardSurface,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  state.isWorkQueue
                      ? 'Đang hiển thị work queue ưu tiên'
                      : 'Đang hiển thị danh sách phân trang',
                  style: AppTypography.bodyRegular1.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
              if (_isResolvingLocation)
                const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
            ],
          ),
          const SizedBox(height: 10),
          DropdownButtonFormField<String>(
            initialValue: _selectedSortBy,
            decoration: const InputDecoration(
              labelText: 'Sắp xếp',
              border: OutlineInputBorder(),
              isDense: true,
            ),
            items: const [
              DropdownMenuItem(
                value: ApiConstants.deliveryGroupSortBalanced,
                child: Text('Cân bằng'),
              ),
              DropdownMenuItem(
                value: ApiConstants.deliveryGroupSortTimeFirst,
                child: Text('Ưu tiên thời gian'),
              ),
              DropdownMenuItem(
                value: ApiConstants.deliveryGroupSortDistanceFirst,
                child: Text('Ưu tiên khoảng cách'),
              ),
            ],
            onChanged: (value) {
              if (value == null || value == _selectedSortBy) {
                return;
              }
              setState(() {
                _selectedSortBy = value;
              });
              _loadGroups(refresh: true);
            },
          ),
          const SizedBox(height: 8),
          SwitchListTile.adaptive(
            contentPadding: EdgeInsets.zero,
            title: const Text('Chế độ work queue'),
            subtitle: Text(
              _isCompletedTab
                  ? 'Tab Đã xong luôn dùng phân trang, sắp xếp mới nhất trước'
                  : 'Bật để lấy top nhóm ưu tiên từ hệ thống',
            ),
            value: _useWorkQueueMode,
            onChanged: (value) {
              setState(() {
                _useWorkQueueMode = value;
              });
              _loadGroups(refresh: true);
            },
          ),
          if (_effectiveWorkQueueMode) ...[
            const SizedBox(height: 8),
            DropdownButtonFormField<int>(
              initialValue: _workQueueLimit,
              decoration: const InputDecoration(
                labelText: 'Giới hạn top N',
                border: OutlineInputBorder(),
                isDense: true,
              ),
              items: const [
                DropdownMenuItem(value: 5, child: Text('Top 5')),
                DropdownMenuItem(value: 10, child: Text('Top 10')),
                DropdownMenuItem(value: 20, child: Text('Top 20')),
              ],
              onChanged: (value) {
                if (value == null || value == _workQueueLimit) {
                  return;
                }
                setState(() {
                  _workQueueLimit = value;
                });
                _loadGroups(refresh: true);
              },
            ),
          ],
          if (_shouldResolveLocation)
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                onPressed: _isResolvingLocation
                    ? null
                    : () {
                        _loadGroups(refresh: true);
                      },
                icon: const Icon(Icons.my_location),
                label: Text(
                  _shipperLocation == null
                      ? 'Lấy vị trí hiện tại'
                      : 'Cập nhật vị trí hiện tại',
                ),
              ),
            ),
        ],
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

  void _handleCompleteGroup(DeliveryGroupSummary group) async {
    final confirmed = await showDeliveryConfirmDialog(
      context: context,
      title: 'Hoàn thành nhóm giao',
      content:
          'Xác nhận hoàn thành nhóm giao "${group.groupCode}"?\n\n'
          '• Đã giao: ${group.completedOrders}/${group.totalOrders}\n'
          '• Hệ thống sẽ kiểm tra item chưa giao trước khi chốt nhóm.',
      confirmLabel: 'Hoàn thành',
    );
    if (confirmed == true && mounted) {
      context.read<DeliveryBloc>().add(
        CompleteDeliveryGroup(groupId: group.deliveryGroupId),
      );
    }
  }
}
