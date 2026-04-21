import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/constants/app_icons.dart';
import '../../../../core/router/app_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../auth/presentation/bloc/auth_event.dart';
import '../../domain/entities/delivery_group.dart';
import '../../domain/entities/delivery_order.dart';
import '../bloc/delivery_bloc.dart';
import '../bloc/delivery_event.dart';
import '../bloc/delivery_state.dart';
import '../widgets/delivery_failure_sheet.dart';
import '../widgets/qr_scan_modal.dart';
import '../widgets/widgets.dart';

/// Screen 4 — Order Details: individual order for delivery.
class OrderDetailsPage extends StatefulWidget {
  final String orderId;
  final String? groupId;

  const OrderDetailsPage({super.key, required this.orderId, this.groupId});

  @override
  State<OrderDetailsPage> createState() => _OrderDetailsPageState();
}

class _OrderDetailsPageState extends State<OrderDetailsPage> {
  final _imagePicker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _loadOrderDetails();
  }

  void _loadOrderDetails() {
    context.read<DeliveryBloc>().add(LoadOrderDetails(orderId: widget.orderId));
  }

  String? _findNextActionableOrderId(DeliveryGroup group) {
    for (final order in group.orders) {
      if (_hasActionableItemsForCurrentGroup(order)) {
        return order.orderId;
      }
    }
    return null;
  }

  void _onOrderActionSuccess(String actionType) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          actionType == 'confirm'
              ? 'Đã xác nhận giao hàng thành công'
              : 'Đã báo cáo giao hàng thất bại',
        ),
        backgroundColor: actionType == 'confirm'
            ? AppColors.successGradientEnd
            : AppColors.headerGradientEnd,
      ),
    );

    // Refresh group to get updated order statuses
    final groupId = widget.groupId?.trim();
    if (groupId != null && groupId.isNotEmpty) {
      context.read<DeliveryBloc>().add(RefreshDeliveryGroup(groupId: groupId));
    } else {
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const GradientAppBar(title: 'Chi tiết đơn hàng'),
      body: BlocConsumer<DeliveryBloc, DeliveryState>(
        listener: (context, state) {
          if (state is DeliverySessionExpired) {
            context.read<AuthBloc>().add(const LogoutEvent());
            return;
          }
          if (state is DeliveryConfirmed) {
            _onOrderActionSuccess('confirm');
          } else if (state is DeliveryFailureReported) {
            _onOrderActionSuccess('failure');
          } else if (state is GroupDetailsLoaded) {
            // Auto-navigate to next actionable order after group refresh
            final nextOrderId = _findNextActionableOrderId(state.group);
            if (nextOrderId != null) {
              final groupId = widget.groupId?.trim();
              context.pop();
              context.push(
                Routes.deliveryOrderDetails(nextOrderId, groupId: groupId),
              );
            } else {
              // No more actionable orders
              context.pop();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Tất cả đơn hàng đã được xử lý'),
                  backgroundColor: AppColors.successGradientEnd,
                ),
              );
            }
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
            _loadOrderDetails();
          }
        },
        builder: (context, state) {
          if (state is DeliveryLoading) {
            return const DeliveryLoadingState(
              message: 'Đang tải chi tiết đơn hàng...',
            );
          }
          if (state is OrderDetailsLoaded) {
            return _buildOrderDetails(state.order);
          }
          if (state is DeliveryError) {
            return DeliveryErrorState(
              message: state.message,
              onRetry: _loadOrderDetails,
              secondaryActionLabel: 'Quay lại lộ trình',
              onSecondaryAction: () {
                final gid = widget.groupId?.trim();
                if (gid != null && gid.isNotEmpty) {
                  context.push(
                    '${Routes.deliveryMap}?groupId=${Uri.encodeComponent(gid)}',
                  );
                  return;
                }
                Navigator.maybePop(context);
              },
            );
          }
          return const SizedBox.shrink();
        },
      ),
    );
  }

  Widget _buildOrderDetails(DeliveryOrder order) {
    final canProcessCurrentGroupItems = _hasActionableItemsForCurrentGroup(
      order,
    );

    final currencyFormat = NumberFormat.currency(
      locale: 'vi_VN',
      symbol: '₫',
      decimalDigits: 0,
    );
    final dateFormat = DateFormat('dd/MM/yyyy HH:mm');

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Order header card ─────────────────────────────────────────────
          _SectionCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        order.orderCode,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTypography.header2.copyWith(
                          fontFamily: 'DM Sans',
                          fontSize: 20,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    DeliveryOrderStatusBadge(status: order.status),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'Ngày đặt: ${dateFormat.format(order.orderDate)}',
                  style: AppTypography.bodyRegular1.copyWith(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 12),

          // ── Customer info ─────────────────────────────────────────────────
          _SectionCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _SectionTitle('Thông tin khách hàng'),
                const Divider(color: AppColors.cardBorder),
                DeliveryInfoRow(
                  icon: Icons.person_outline,
                  label: 'Tên',
                  value: order.customerName,
                ),
                Row(
                  children: [
                    SvgPicture.asset(AppIcons.phone, width: 20, height: 20),
                    const SizedBox(width: 12),
                    Text(
                      'SĐT: ',
                      style: AppTypography.bodyRegular1.copyWith(
                        color: AppColors.neutralMid,
                        fontSize: 13,
                      ),
                    ),
                    Expanded(
                      child: Text(
                        order.customerPhone,
                        style: AppTypography.bodyRegular1.copyWith(
                          fontWeight: FontWeight.w500,
                          fontSize: 13,
                          color: AppColors.neutralDark,
                        ),
                      ),
                    ),
                    GestureDetector(
                      onTap: () => _callCustomer(order.customerPhone),
                      child: Container(
                        width: 40,
                        height: 40,
                        decoration: const BoxDecoration(
                          color: AppColors.callActionBackground,
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: SvgPicture.asset(
                            AppIcons.phone,
                            width: 20,
                            height: 20,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 12),

          // ── Delivery address ──────────────────────────────────────────────
          _SectionCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _SectionTitle('Địa chỉ giao hàng'),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: order.isHomeDelivery
                            ? AppColors.accent.withValues(alpha: 0.1)
                            : AppColors.successGradientStart.withValues(
                                alpha: 0.1,
                              ),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        order.isHomeDelivery ? 'Giao tận nơi' : 'Nhận tại điểm',
                        style: AppTypography.bodyRegular1.copyWith(
                          fontSize: 12,
                          color: order.isHomeDelivery
                              ? AppColors.accent
                              : AppColors.successGradientEnd,
                        ),
                      ),
                    ),
                  ],
                ),
                const Divider(color: AppColors.cardBorder),
                if (order.isHomeDelivery)
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.cardSurface,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      children: [
                        SvgPicture.asset(
                          AppIcons.locationBlue,
                          width: 20,
                          height: 20,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Địa chỉ giao hàng',
                                style: AppTypography.header3.copyWith(
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                order.deliveryAddress ?? 'Chưa có địa chỉ',
                                style: AppTypography.header3.copyWith(
                                  color: AppColors.bodyOnSurface,
                                ),
                              ),
                            ],
                          ),
                        ),
                        GestureDetector(
                          onTap: () => _openMaps(
                            order.deliveryAddress ?? '',
                            lat: order.latitude,
                            lng: order.longitude,
                          ),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.directionsBlue,
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: Text(
                              'Chỉ đường',
                              style: AppTypography.header3.copyWith(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  )
                else ...[
                  Text(
                    order.pickupPointName ?? 'Điểm nhận hàng',
                    style: AppTypography.header3.copyWith(
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          order.pickupPointAddress ?? 'Chưa có địa chỉ',
                          style: AppTypography.bodyRegular1.copyWith(
                            fontSize: 13,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ),
                      GestureDetector(
                        onTap: () => _openMaps(
                          order.pickupPointAddress ??
                              order.pickupPointName ??
                              '',
                          lat: order.latitude,
                          lng: order.longitude,
                        ),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.directionsBlue,
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Text(
                            'Chỉ đường',
                            style: AppTypography.header3.copyWith(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
                if (order.deliveryNote != null &&
                    order.deliveryNote!.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  DeliveryNoteCard(note: order.deliveryNote!),
                ],
              ],
            ),
          ),

          const SizedBox(height: 12),

          // ── Meta chips ────────────────────────────────────────────────
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.cardSurface,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    children: [
                      SvgPicture.asset(AppIcons.clock, width: 20, height: 20),
                      const SizedBox(width: 8),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Khung giờ',
                            style: AppTypography.bodyRegular1.copyWith(
                              fontSize: 12,
                              color: AppColors.textSecondary,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '19:00 - 20:30',
                            style: AppTypography.header3.copyWith(
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.cardSurface,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    children: [
                      SvgPicture.asset(AppIcons.package, width: 20, height: 20),
                      const SizedBox(width: 8),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Điểm lấy',
                            style: AppTypography.bodyRegular1.copyWith(
                              fontSize: 12,
                              color: AppColors.textSecondary,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Điểm A - Quận 1',
                            style: AppTypography.header3.copyWith(
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // ── Order items ───────────────────────────────────────────────────
          _SectionCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _SectionTitle('Sản phẩm (${order.totalItems})'),
                const Divider(color: AppColors.cardBorder),
                ...order.items.map(
                  (item) => _buildItemRow(order, item, currencyFormat),
                ),
                const Divider(color: AppColors.cardBorder),

                // Subtotals
                _PriceRow(
                  label: 'Tổng tiền hàng:',
                  value: currencyFormat.format(order.totalAmount),
                  labelColor: AppColors.textSecondary,
                  valueColor: AppColors.textPrimary,
                ),
                const SizedBox(height: 4),
                _PriceRow(
                  label: 'Phí giao hàng:',
                  value: currencyFormat.format(order.deliveryFee),
                  labelColor: AppColors.textSecondary,
                  valueColor: AppColors.textPrimary,
                ),
                const Divider(color: AppColors.cardBorder),

                // Grand total — highlighted per spec
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [
                        AppColors.orderTotalGradientStart,
                        AppColors.orderTotalGradientEnd,
                      ],
                    ),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Tổng cộng',
                        style: AppTypography.header2.copyWith(
                          fontFamily: 'DM Sans',
                          fontSize: 16,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      Text(
                        currencyFormat.format(order.totalValue),
                        style: const TextStyle(
                          fontFamily: 'DM Sans',
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: AppColors.headerGradientEnd,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // ── Action buttons ────────────────────────────────────────────────
          if (canProcessCurrentGroupItems) ...[
            // QR confirm — success gradient per spec
            _SuccessGradientButton(
              onPressed: () => _openQrScan(order),
              icon: Icons.qr_code_scanner,
              label: 'Quét mã QR xác nhận',
            ),
            const SizedBox(height: 12),

            // Failure report — outlined, error color per spec
            AppDeliveryOutlinedButton(
              onPressed: () => _openFailureSheet(order),
              icon: Icons.cancel_outlined,
              label: 'Giao hàng thất bại',
              foregroundColor: AppColors.headerGradientEnd,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildItemRow(
    DeliveryOrder order,
    DeliveryOrderItem item,
    NumberFormat fmt,
  ) {
    final groupId = _resolveCurrentGroupIdForItems(order);
    final belongsToCurrentGroup = _isItemBelongsToGroup(item, groupId);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: AppColors.cardBorder, width: 1.18),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Container(
            width: 47.99,
            height: 47.99,
            decoration: BoxDecoration(
              color: AppColors.badgePendingBackground,
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(
              Icons.fastfood_outlined,
              size: 24,
              color: AppColors.badgePendingText,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.productName,
                  style: AppTypography.header3.copyWith(
                    fontFamily: 'DM Sans',
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                Text(
                  'Số lượng: ${item.quantity}',
                  style: AppTypography.bodyRegular1.copyWith(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Trạng thái:',
                  style: AppTypography.bodyRegular1.copyWith(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 4),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    _buildPackagingStatusBadge(item),
                    _buildItemDeliveryStatusBadge(item),
                    if (!belongsToCurrentGroup)
                      _buildMetaStatusBadge(
                        text: 'Khác nhóm giao',
                        color: AppColors.neutralMid,
                      ),
                  ],
                ),
              ],
            ),
          ),
          Text(
            fmt.format(item.subTotal),
            style: const TextStyle(
              fontFamily: 'DM Sans',
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: AppColors.headerGradientEnd,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPackagingStatusBadge(DeliveryOrderItem item) {
    if (item.isPackagingCompleted) {
      return _buildMetaStatusBadge(
        text: 'Đã đóng gói',
        color: AppColors.successGradientEnd,
      );
    }

    return _buildMetaStatusBadge(
      text: 'Chưa đóng gói',
      color: AppColors.accent,
    );
  }

  Widget _buildItemDeliveryStatusBadge(DeliveryOrderItem item) {
    final status = (item.deliveryStatus ?? '').trim().toLowerCase().replaceAll(
      '_',
      '',
    );

    switch (status) {
      case 'completed':
        return _buildMetaStatusBadge(
          text: 'Đã giao',
          color: AppColors.successGradientEnd,
        );
      case 'failed':
        return _buildMetaStatusBadge(
          text: 'Giao thất bại',
          color: AppColors.error,
        );
      case 'deliveredwaitconfirm':
        return _buildMetaStatusBadge(
          text: 'Chờ xác nhận',
          color: AppColors.statusInTransit,
        );
      case 'intransit':
      case 'pickedup':
        return _buildMetaStatusBadge(
          text: 'Đang vận chuyển',
          color: AppColors.statusDeliveryLeg,
        );
      default:
        return _buildMetaStatusBadge(
          text: 'Sẵn sàng giao',
          color: AppColors.primaryGradientStart,
        );
    }
  }

  Widget _buildMetaStatusBadge({required String text, required Color color}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        text,
        style: AppTypography.bodyRegular1.copyWith(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }

  Future<void> _callCustomer(String phone) async {
    final uri = Uri.parse('tel:$phone');
    if (await canLaunchUrl(uri)) await launchUrl(uri);
  }

  Future<void> _openMaps(String address, {double? lat, double? lng}) async {
    final trimmed = address.trim();
    late final Uri uri;
    if (lat != null && lng != null) {
      uri = Uri.parse(
        'https://www.google.com/maps/search/?api=1&query=$lat,$lng',
      );
    } else if (trimmed.isNotEmpty) {
      uri = Uri.parse(
        'https://www.google.com/maps/search/?api=1&query=${Uri.encodeComponent(trimmed)}',
      );
    } else {
      return;
    }
    try {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Không mở được bản đồ. Hãy cài Google Maps hoặc trình duyệt.',
          ),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  static String _normalizeForVerify(String x) =>
      x.toLowerCase().replaceAll(RegExp(r'\s+'), '');

  /// Chuỗi gửi BE là [order.orderCode] khi payload quét/nhập chứa đúng mã đơn.
  /// BE chỉ so với [Order.OrderCode], không so với orderId.
  String? _verificationCodeFromScan(String scanned, DeliveryOrder order) {
    final s = scanned.trim();
    final code = order.orderCode.trim();
    if (s.isEmpty || code.isEmpty) return null;
    final ns = _normalizeForVerify(s);
    final nc = _normalizeForVerify(code);
    if (ns == nc) return code;
    if (ns.contains(nc)) return code;
    return null;
  }

  List<String> _collectEligibleFailureOrderItemIds(DeliveryOrder order) {
    final groupId = _resolveCurrentGroupIdForItems(order);
    return order.items
        .where((item) {
          final itemGroupId = item.deliveryGroupId?.trim().toLowerCase();
          final inCurrentGroup =
              groupId == null || groupId.isEmpty || itemGroupId == groupId;
          return inCurrentGroup &&
              item.isPackagingCompleted &&
              !item.isDeliveryTerminalForFailure;
        })
        .map((item) => item.orderItemId.trim())
        .where((id) => id.isNotEmpty)
        .toList(growable: false);
  }

  bool _hasActionableItemsForCurrentGroup(DeliveryOrder order) {
    final groupId = _resolveCurrentGroupIdForItems(order);

    if (order.items.isNotEmpty) {
      return order.items.any(
        (item) =>
            _isItemBelongsToGroup(item, groupId) &&
            item.isPackagingCompleted &&
            !_isTerminalGroupItem(item),
      );
    }

    // Backward-compatible fallback when item-level payload is unavailable.
    return !order.isCompleted &&
        !order.isFailed &&
        order.status != DeliveryOrderStatus.deliveredWaitConfirm &&
        order.status != DeliveryOrderStatus.canceled &&
        order.status != DeliveryOrderStatus.refunded;
  }

  String? _resolveCurrentGroupIdForItems(DeliveryOrder order) {
    final routeGroupId = widget.groupId?.trim().toLowerCase();
    if (routeGroupId != null && routeGroupId.isNotEmpty) {
      return routeGroupId;
    }

    final orderGroupId = order.deliveryGroupId?.trim().toLowerCase();
    if (orderGroupId != null && orderGroupId.isNotEmpty) {
      return orderGroupId;
    }

    return null;
  }

  bool _isItemBelongsToGroup(DeliveryOrderItem item, String? groupId) {
    if (groupId == null || groupId.isEmpty) {
      return true;
    }

    final itemGroupId = item.deliveryGroupId?.trim().toLowerCase();
    if (itemGroupId == null || itemGroupId.isEmpty) {
      return false;
    }
    return itemGroupId == groupId;
  }

  bool _isTerminalGroupItem(DeliveryOrderItem item) {
    final status = (item.deliveryStatus ?? '').trim().toLowerCase().replaceAll(
      '_',
      '',
    );

    return status == 'completed' ||
        status == 'failed' ||
        status == 'deliveredwaitconfirm';
  }

  Future<void> _openQrScan(DeliveryOrder order) async {
    final qrCode = await showQrScanModal(context);
    if (!mounted || qrCode == null || qrCode.trim().isEmpty) return;

    if (order.orderCode.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Ứng dụng chưa có mã đơn (orderCode). Kéo xuống làm mới trang hoặc mở lại đơn.',
          ),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    final verification = _verificationCodeFromScan(qrCode, order);
    if (verification == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Mã vừa nhập không trùng mã đơn ${order.orderCode}. '
            'QR phải chứa đúng mã này (BE so khớp orderCode, không dùng orderId).',
          ),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    final picked = await _imagePicker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
    );
    if (!mounted) return;
    if (picked == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Cần ảnh chứng minh sau khi quét QR — upload proof-image là bắt buộc.',
          ),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    context.read<DeliveryBloc>().add(
      ConfirmDelivery(
        orderId: order.orderId,
        deliveryGroupId: order.deliveryGroupId,
        proofImagePath: picked.path,
        verificationCode: verification,
        notes: 'Xác nhận bằng QR',
      ),
    );
  }

  Future<void> _openFailureSheet(DeliveryOrder order) async {
    final eligibleOrderItemIds = _collectEligibleFailureOrderItemIds(order);
    if (eligibleOrderItemIds.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Đơn hiện không có dòng hàng đủ điều kiện để báo giao thất bại.',
          ),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    const reasons = [
      'Khách không nghe máy',
      'Khách hủy đơn',
      'Không tìm thấy địa chỉ',
      'Khách không có nhà',
      'Lý do khác',
    ];
    final result = await showDeliveryFailureSheet(context, reasons: reasons);
    if (!mounted || result == null) return;
    context.read<DeliveryBloc>().add(
      ReportDeliveryFailure(
        orderId: order.orderId,
        deliveryGroupId: order.deliveryGroupId,
        failureReason: result.reason,
        notes: result.notes,
        orderItemIds: eligibleOrderItemIds,
      ),
    );
  }
}

// ── Private helpers ──────────────────────────────────────────────────────────

class _SectionCard extends StatelessWidget {
  final Widget child;
  const _SectionCard({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
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
      child: child,
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String text;
  const _SectionTitle(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: AppTypography.header2.copyWith(
        fontFamily: 'DM Sans',
        fontSize: 16,
        color: AppColors.textPrimary,
      ),
    );
  }
}

class _PriceRow extends StatelessWidget {
  final String label;
  final String value;
  final Color labelColor;
  final Color valueColor;

  const _PriceRow({
    required this.label,
    required this.value,
    required this.labelColor,
    required this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: AppTypography.header3.copyWith(color: labelColor)),
        Text(value, style: AppTypography.header3.copyWith(color: valueColor)),
      ],
    );
  }
}

class _SuccessGradientButton extends StatelessWidget {
  final VoidCallback onPressed;
  final IconData icon;
  final String label;

  const _SuccessGradientButton({
    required this.onPressed,
    required this.icon,
    required this.label,
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
          borderRadius: BorderRadius.circular(16),
        ),
        child: Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(16),
          child: InkWell(
            onTap: onPressed,
            borderRadius: BorderRadius.circular(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, color: Colors.white, size: 20),
                const SizedBox(width: 8),
                Text(
                  label,
                  style: AppTypography.header3.copyWith(
                    fontSize: 16,
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
