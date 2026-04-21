import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../domain/entities/delivery_order.dart';
import 'status_badges.dart';

/// Delivery Order Card — matches Screen 3 Order Card spec.
class DeliveryOrderCard extends StatelessWidget {
  final DeliveryOrder order;
  final String? currentGroupId;
  final VoidCallback? onTap;
  final NumberFormat? currencyFormat;

  const DeliveryOrderCard({
    super.key,
    required this.order,
    this.currentGroupId,
    this.onTap,
    this.currencyFormat,
  });

  List<DeliveryOrderItem> _resolveGroupItems() {
    final groupId = currentGroupId?.trim().toLowerCase();
    if (groupId == null || groupId.isEmpty) {
      return const [];
    }

    return order.items
        .where((item) {
          final itemGroupId = item.deliveryGroupId?.trim().toLowerCase();
          return itemGroupId != null && itemGroupId == groupId;
        })
        .toList(growable: false);
  }

  int _countByStatuses(List<DeliveryOrderItem> items, Set<String> statuses) {
    return items.where((item) {
      final status = (item.deliveryStatus ?? '')
          .trim()
          .toLowerCase()
          .replaceAll('_', '');
      return statuses.contains(status);
    }).length;
  }

  /// Đơn có item thuộc (các) nhóm giao khác → là đơn đa-nhóm (multi-supermarket).
  /// Dùng để hiển thị hint giúp shipper hiểu vì sao order status chung chưa đóng
  /// sổ dù nhóm của họ đã xử lý xong.
  bool _hasItemsInOtherGroups() {
    final groupId = currentGroupId?.trim().toLowerCase();
    if (groupId == null || groupId.isEmpty) return false;

    return order.items.any((item) {
      final itemGroupId = item.deliveryGroupId?.trim().toLowerCase();
      return itemGroupId != null &&
          itemGroupId.isNotEmpty &&
          itemGroupId != groupId;
    });
  }

  /// Badge "theo nhóm": mô tả tiến độ của riêng nhóm shipper đang phụ trách.
  /// Khác với [DeliveryOrderStatusBadge] vốn lấy từ Order.Status (BE gộp tất cả
  /// nhóm/items), badge này chỉ nói về các item thuộc [currentGroupId].
  Widget? _buildGroupScopedBadge({
    required int totalItemsInGroup,
    required int completedCount,
    required int failedCount,
    required int waitConfirmCount,
    required int inTransitCount,
    required int actionableCount,
  }) {
    if (totalItemsInGroup == 0) return null;

    final terminalCount = completedCount + failedCount + waitConfirmCount;
    final allTerminal = terminalCount >= totalItemsInGroup;

    String text;
    Color color;
    if (allTerminal) {
      if (failedCount == 0) {
        text = 'Nhóm đã xong';
        color = AppColors.successGradientEnd;
      } else if (completedCount == 0 && waitConfirmCount == 0) {
        text = 'Nhóm thất bại';
        color = AppColors.error;
      } else {
        text = 'Nhóm đã xong (có lỗi)';
        color = AppColors.accent;
      }
    } else if (inTransitCount > 0) {
      text = 'Đang giao nhóm';
      color = AppColors.statusDeliveryLeg;
    } else if (actionableCount > 0) {
      text = 'Chờ xử lý nhóm';
      color = AppColors.headerGradientEnd;
    } else {
      text = 'Nhóm đang xử lý';
      color = AppColors.primaryGradientStart;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        text,
        style: AppTypography.bodyRegular1.copyWith(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: color,
        ),
      ),
    );
  }

  Widget _buildItemStatusChip({required String text, required Color color}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        text,
        style: AppTypography.bodyRegular1.copyWith(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: color,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final formatter =
        currencyFormat ??
        NumberFormat.currency(locale: 'vi_VN', symbol: '₫', decimalDigits: 0);
    final scopedItems = _resolveGroupItems();
    final totalItemsInGroup = scopedItems.length;
    final completedCount = _countByStatuses(scopedItems, {'completed'});
    final failedCount = _countByStatuses(scopedItems, {'failed'});
    final waitConfirmCount = _countByStatuses(scopedItems, {
      'deliveredwaitconfirm',
    });
    final inTransitCount = _countByStatuses(scopedItems, {
      'intransit',
      'pickedup',
    });
    final actionableCount = scopedItems
        .where((item) => item.isPackagingCompleted)
        .where((item) => !item.isDeliveryTerminalForFailure)
        .length;
    final hasItemsInOtherGroups = _hasItemsInOtherGroups();
    final groupScopedBadge = _buildGroupScopedBadge(
      totalItemsInGroup: totalItemsInGroup,
      completedCount: completedCount,
      failedCount: failedCount,
      waitConfirmCount: waitConfirmCount,
      inTransitCount: inTransitCount,
      actionableCount: actionableCount,
    );

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: AppColors.cardBorder, width: 1),
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 6,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 14, 14, 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Header: customer name + status badge ───────────────
                  // Khi có [currentGroupId], ưu tiên hiển thị group-scoped
                  // badge (tiến độ của chính nhóm shipper đang phụ trách).
                  // Order-level badge vẫn giữ ở dưới nhưng kích thước nhỏ hơn
                  // để shipper không bị nhầm rằng đơn "chưa xong" trong khi
                  // thực tế nhóm của họ đã hoàn tất.
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          order.customerName,
                          style: AppTypography.header2.copyWith(
                            fontFamily: 'DM Sans',
                            fontSize: 16,
                            color: AppColors.textPrimary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      if (groupScopedBadge != null)
                        groupScopedBadge
                      else
                        DeliveryOrderStatusBadge(
                          status: order.status,
                          compact: true,
                        ),
                    ],
                  ),
                  if (groupScopedBadge != null) ...[
                    const SizedBox(height: 4),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Text(
                          'Đơn: ',
                          style: AppTypography.bodyRegular1.copyWith(
                            fontSize: 10,
                            color: AppColors.textSecondary,
                          ),
                        ),
                        DeliveryOrderStatusBadge(
                          status: order.status,
                          compact: true,
                        ),
                      ],
                    ),
                  ],
                  const SizedBox(height: 6),

                  // ── Address ───────────────────────────────────────────
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.location_on_outlined,
                        size: 14,
                        color: AppColors.textSecondary,
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          order.destinationAddress,
                          style: AppTypography.bodyRegular1.copyWith(
                            fontSize: 12,
                            color: AppColors.textSecondary,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),

                  if (totalItemsInGroup > 0) ...[
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: [
                        _buildItemStatusChip(
                          text: 'Item nhóm: $totalItemsInGroup',
                          color: AppColors.neutralDark,
                        ),
                        _buildItemStatusChip(
                          text: 'Còn xử lý: $actionableCount',
                          color: AppColors.headerGradientEnd,
                        ),
                        _buildItemStatusChip(
                          text: 'Đã giao: $completedCount',
                          color: AppColors.successGradientEnd,
                        ),
                        if (waitConfirmCount > 0)
                          _buildItemStatusChip(
                            text: 'Chờ xác nhận: $waitConfirmCount',
                            color: AppColors.statusInTransit,
                          ),
                        if (inTransitCount > 0)
                          _buildItemStatusChip(
                            text: 'Đang giao: $inTransitCount',
                            color: AppColors.statusDeliveryLeg,
                          ),
                        if (failedCount > 0)
                          _buildItemStatusChip(
                            text: 'Thất bại: $failedCount',
                            color: AppColors.error,
                          ),
                      ],
                    ),
                    const SizedBox(height: 6),
                  ],

                  if (hasItemsInOtherGroups) ...[
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          Icons.info_outline,
                          size: 12,
                          color: AppColors.neutralMid,
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            'Đơn đa nhóm — còn món ở nhóm khác, '
                            'trạng thái đơn sẽ chốt khi các nhóm đều hoàn tất.',
                            style: AppTypography.bodyRegular1.copyWith(
                              fontSize: 11,
                              color: AppColors.neutralMid,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                  ],

                  // ── Meta row: phone + items count ─────────────────────
                  Row(
                    children: [
                      Icon(
                        Icons.phone_outlined,
                        size: 12,
                        color: AppColors.textSecondary,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        order.customerPhone,
                        style: AppTypography.bodyRegular1.copyWith(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Icon(
                        Icons.shopping_bag_outlined,
                        size: 12,
                        color: AppColors.textSecondary,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        hasItemsInOtherGroups && totalItemsInGroup > 0
                            ? '$totalItemsInGroup/${order.totalItems} món'
                            : '${order.totalItems} món',
                        style: AppTypography.bodyRegular1.copyWith(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const Spacer(),
                      Icon(
                        Icons.chevron_right,
                        size: 20,
                        color: AppColors.textSecondary,
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // ── Footer: order code + price ──────────────────────────────
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: const BoxDecoration(
                border: Border(top: BorderSide(color: AppColors.cardBorder)),
                borderRadius: BorderRadius.vertical(
                  bottom: Radius.circular(24),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    order.orderCode,
                    style: AppTypography.bodyRegular1.copyWith(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  Text(
                    formatter.format(order.totalValue),
                    style: const TextStyle(
                      fontFamily: 'DM Sans',
                      fontSize: 16,
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
    );
  }
}

/// Compact list-tile variant of the order card.
class DeliveryOrderCardCompact extends StatelessWidget {
  final DeliveryOrder order;
  final String? currentGroupId;
  final VoidCallback? onTap;

  const DeliveryOrderCardCompact({
    super.key,
    required this.order,
    this.currentGroupId,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final currencyFormat = NumberFormat.currency(
      locale: 'vi_VN',
      symbol: '₫',
      decimalDigits: 0,
    );

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: AppColors.cardBorder),
        borderRadius: BorderRadius.circular(16),
      ),
      child: ListTile(
        onTap: onTap,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                order.orderCode,
                style: AppTypography.header3.copyWith(
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
            DeliveryOrderStatusBadge(status: order.status, compact: true),
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
              order.customerName,
              style: AppTypography.header3.copyWith(
                fontSize: 13,
                color: AppColors.textPrimary,
              ),
            ),
            Text(
              order.destinationAddress,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTypography.bodyRegular1.copyWith(
                fontSize: 12,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
        trailing: Text(
          currencyFormat.format(order.totalValue),
          style: const TextStyle(
            fontFamily: 'DM Sans',
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: AppColors.headerGradientEnd,
          ),
        ),
      ),
    );
  }
}
