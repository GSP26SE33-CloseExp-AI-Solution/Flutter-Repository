import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'dart:math' as math;

import '../../../../core/router/app_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../domain/entities/delivery_group.dart';
import '../bloc/delivery_bloc.dart';
import '../bloc/delivery_event.dart';
import '../bloc/delivery_state.dart';
import '../widgets/widgets.dart';

/// Nhóm admin đã gán cho shipper hiện tại, trạng thái Pending — cần Accept trước khi Start.
class AvailableGroupsPage extends StatefulWidget {
  const AvailableGroupsPage({super.key});
  @override
  State<AvailableGroupsPage> createState() => _AvailableGroupsPageState();
}

class _AvailableGroupsPageState extends State<AvailableGroupsPage> {
  static const ({double latitude, double longitude}) _mockShipperLocation = (
    latitude: 10.776889,
    longitude: 106.700806,
  );

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
    return BlocConsumer<DeliveryBloc, DeliveryState>(
      listener: _handleStateChange,
      builder: (context, state) {
        final subtitle = state is AvailableGroupsLoaded
            ? '${state.groups.length} đơn hàng đang chờ • gần shipper trước'
            : null;

        return Scaffold(
          appBar: GradientAppBar(
            title: 'Đơn hàng cần giao',
            subtitle: subtitle,
            actions: [
              IconButton(
                icon: const Icon(Icons.refresh),
                color: Colors.white,
                onPressed: _loadGroups,
                tooltip: 'Làm mới',
              ),
            ],
          ),
          body: _buildBody(context, state),
        );
      },
    );
  }

  void _handleStateChange(BuildContext context, DeliveryState state) {
    if (state is DeliveryGroupAccepted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Đã nhận đơn ${state.group.groupCode}'),
          backgroundColor: AppColors.successGradientEnd,
        ),
      );
      _loadGroups();
    } else if (state is DeliveryError) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(state.message),
          backgroundColor: AppColors.error,
        ),
      );
    } else if (state is DeliveryActionError) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(state.message),
          backgroundColor: AppColors.error,
        ),
      );
      _loadGroups();
    }
  }

  Widget _buildBody(BuildContext context, DeliveryState state) {
    if (state is DeliveryLoading) {
      return const DeliveryLoadingState(message: 'Đang tải...');
    }

    if (state is AvailableGroupsLoaded) {
      if (state.isEmpty) {
        return DeliveryEmptyState(
          icon: Icons.inbox_outlined,
          title: 'Không có đơn hàng có sẵn',
          subtitle: 'Hãy quay lại sau để kiểm tra đơn mới',
          actionLabel: 'Làm mới',
          onAction: _loadGroups,
        );
      }
      return _buildGroupsList(state.groups);
    }

    if (state is DeliveryError) {
      return DeliveryErrorState(message: state.message, onRetry: _loadGroups);
    }

    return const SizedBox.shrink();
  }

  Widget _buildGroupsList(List<DeliveryGroupSummary> groups) {
    final sortedGroups = [...groups]..sort(_compareByDistance);

    return RefreshIndicator(
      color: AppColors.headerGradientEnd,
      onRefresh: () async => _loadGroups(),
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: sortedGroups.length,
        itemBuilder: (context, index) {
          final group = sortedGroups[index];
          return DeliveryGroupCard(
            group: group,
            distanceKm: _distanceToGroup(group),
            onTap: () => context.push(
              Routes.deliveryGroupDetails(group.deliveryGroupId),
            ),
            onAccept: () => _handleAcceptGroup(group),
          );
        },
      ),
    );
  }

  int _compareByDistance(DeliveryGroupSummary a, DeliveryGroupSummary b) {
    final distanceA = _distanceToGroup(a);
    final distanceB = _distanceToGroup(b);

    if (distanceA == null && distanceB == null) {
      return a.deliveryDate.compareTo(b.deliveryDate);
    }
    if (distanceA == null) return 1;
    if (distanceB == null) return -1;

    final result = distanceA.compareTo(distanceB);
    if (result != 0) return result;
    return a.deliveryDate.compareTo(b.deliveryDate);
  }

  double? _distanceToGroup(DeliveryGroupSummary group) {
    final lat = group.centerLatitude;
    final lng = group.centerLongitude;
    if (lat == null || lng == null) return null;
    return _distanceKm(
      _mockShipperLocation.latitude,
      _mockShipperLocation.longitude,
      lat,
      lng,
    );
  }

  double _distanceKm(
    double startLatitude,
    double startLongitude,
    double endLatitude,
    double endLongitude,
  ) {
    const earthRadiusKm = 6371.0;
    final dLat = _toRadians(endLatitude - startLatitude);
    final dLng = _toRadians(endLongitude - startLongitude);
    final lat1 = _toRadians(startLatitude);
    final lat2 = _toRadians(endLatitude);

    final a =
        math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(lat1) *
            math.cos(lat2) *
            math.sin(dLng / 2) *
            math.sin(dLng / 2);
    final c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
    return earthRadiusKm * c;
  }

  double _toRadians(double degrees) => degrees * (math.pi / 180.0);

  void _handleAcceptGroup(DeliveryGroupSummary group) async {
    final confirmed = await showDeliveryConfirmDialog(
      context: context,
      title: 'Xác nhận nhận đơn',
      content:
          'Bạn có chắc muốn nhận nhóm giao "${group.groupCode}"?\n\n'
          '• Khu vực: ${group.deliveryArea}\n'
          '• Thời gian: ${group.timeSlotDisplay}\n'
          '• Số đơn: ${group.totalOrders}',
      confirmLabel: 'Nhận đơn',
      confirmColor: AppColors.headerGradientEnd,
    );
    if (confirmed == true && mounted) {
      context.read<DeliveryBloc>().add(
        AcceptDeliveryGroup(groupId: group.deliveryGroupId),
      );
    }
  }
}
