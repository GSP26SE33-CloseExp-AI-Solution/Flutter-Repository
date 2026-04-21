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
                      DeliveryOrderStatusBadge(
                        status: order.status,
                        compact: true,
                      ),
                    ],
                  ),
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
                        '${order.totalItems} món',
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
