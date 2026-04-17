import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../domain/entities/delivery_group.dart';
import 'common_widgets.dart';
import 'status_badges.dart';

/// Delivery Group Card — matches Screen 1 Order Card spec.
class DeliveryGroupCard extends StatelessWidget {
  final DeliveryGroupSummary group;
  final VoidCallback? onTap;
  final VoidCallback? onAccept;
  final VoidCallback? onStart;
  final VoidCallback? onComplete;
  final bool showAcceptButton;
  final double? distanceKm;

  const DeliveryGroupCard({
    super.key,
    required this.group,
    this.onTap,
    this.onAccept,
    this.onStart,
    this.onComplete,
    this.showAcceptButton = true,
    this.distanceKm,
  });

  @override
  Widget build(BuildContext context) {
    final displayDistanceKm = distanceKm ?? group.distanceFromCurrentKm;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: AppColors.cardBorder, width: 1.18),
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.10),
              blurRadius: 6,
              offset: const Offset(0, 4),
            ),
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Header row
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Gradient icon box
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [
                              AppColors.headerGradientStart,
                              AppColors.headerGradientEnd,
                            ],
                          ),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: const Icon(
                          Icons.local_shipping,
                          color: Colors.white,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 12),

                      // Group code + status badges
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              group.groupCode,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: AppTypography.header2.copyWith(
                                fontFamily: 'DM Sans',
                                fontSize: 18,
                                color: AppColors.textPrimary,
                                letterSpacing: -0.54,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Wrap(
                              spacing: 6,
                              runSpacing: 6,
                              children: [
                                _Pill(
                                  text: '${group.totalOrders} đơn hàng',
                                  background: AppColors.badgeUrgentBackground,
                                  textColor: AppColors.badgeUrgentText,
                                ),
                                if (group.pendingOrders > 0)
                                  _Pill(
                                    text: '${group.pendingOrders} chờ giao',
                                    background:
                                        AppColors.badgePendingBackground,
                                    textColor: AppColors.badgePendingText,
                                  ),
                                if (displayDistanceKm != null)
                                  _Pill(
                                    text: _distanceLabel(displayDistanceKm),
                                    background: AppColors.successGradientStart
                                        .withValues(alpha: 0.12),
                                    textColor: AppColors.successGradientEnd,
                                  ),
                                if (group.priorityScore != null)
                                  _Pill(
                                    text:
                                        'Ưu tiên ${group.priorityScore!.toStringAsFixed(0)}',
                                    background: AppColors.headerGradientStart
                                        .withValues(alpha: 0.12),
                                    textColor: AppColors.headerGradientEnd,
                                  ),
                              ],
                            ),
                            if (group.priorityReasons.isNotEmpty) ...[
                              const SizedBox(height: 6),
                              Text(
                                'Lý do: ${group.priorityReasons.take(2).join(', ')}',
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: AppTypography.bodyRegular1.copyWith(
                                  fontSize: 12,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),

                      const Icon(
                        Icons.chevron_right,
                        size: 24,
                        color: AppColors.textSecondary,
                      ),
                    ],
                  ),

                  const SizedBox(height: 12),

                  // ── Info chips
                  Row(
                    children: [
                      Expanded(
                        child: _InfoChip(
                          label: 'Khu vực',
                          value: group.deliveryArea,
                          valueFontSize: 14,
                          bold: false,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _InfoChip(
                          label: 'Khung giờ',
                          value: group.timeSlotDisplay,
                          valueFontSize: 14,
                          bold: true,
                        ),
                      ),
                    ],
                  ),

                  // ── Completed progress
                  if (group.totalOrders > 0) ...[
                    const SizedBox(height: 12),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: group.completedOrders / group.totalOrders,
                        backgroundColor: AppColors.cardBorder,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          group.completedOrders == group.totalOrders
                              ? AppColors.successGradientStart
                              : AppColors.headerGradientEnd,
                        ),
                        minHeight: 6,
                      ),
                    ),
                  ],

                  // ── Action buttons
                  if (showAcceptButton &&
                      group.isAvailable &&
                      onAccept != null) ...[
                    const SizedBox(height: 12),
                    AppGradientButton(
                      onPressed: onAccept,
                      child: Text(
                        'Nhận đơn',
                        style: AppTypography.header3.copyWith(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          letterSpacing: -0.14,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],

                  if (group.isAssigned && onStart != null) ...[
                    const SizedBox(height: 12),
                    _SuccessGradientButton(
                      onPressed: onStart!,
                      label: 'Bắt đầu giao',
                    ),
                  ],  
                  // FIXME: Fix the Progress line
                  if (group.isInProgress &&
                      group.pendingOrders == 0 &&
                      onComplete != null) ...[
                    const SizedBox(height: 12),
                    AppGradientButton(
                      onPressed: onComplete,
                      child: Text(
                        'Hoàn thành',
                        style: AppTypography.header3.copyWith(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          letterSpacing: -0.14,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),

            // ── Footer
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: const BoxDecoration(
                border: Border(top: BorderSide(color: Color(0xFFE5E7EB))),
                borderRadius: BorderRadius.vertical(
                  bottom: Radius.circular(24),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Align(
                    alignment: Alignment.centerLeft,
                    child: DeliveryGroupStatusBadge(
                      status: group.status,
                      compact: true,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Nhấn để xem chi tiết đơn hàng',
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    softWrap: true,
                    style: AppTypography.header3.copyWith(
                      color: AppColors.textSecondary,
                      fontSize: 12,
                      height: 1.35,
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

String _distanceLabel(double distanceKm) {
  if (distanceKm < 1) {
    return '${(distanceKm * 1000).round()} m';
  }
  if (distanceKm < 10) {
    return '${distanceKm.toStringAsFixed(1)} km';
  }
  return '${distanceKm.round()} km';
}

// ── Private helpers

class _Pill extends StatelessWidget {
  final String text;
  final Color background;
  final Color textColor;

  const _Pill({
    required this.text,
    required this.background,
    required this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        text,
        style: AppTypography.bodyRegular1.copyWith(
          fontWeight: FontWeight.w700,
          fontSize: 12,
          color: textColor,
        ),
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  final String label;
  final String value;
  final double valueFontSize;
  final bool bold;

  const _InfoChip({
    required this.label,
    required this.value,
    this.valueFontSize = 16,
    this.bold = true,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.cardSurface,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: AppTypography.bodyRegular1.copyWith(
              fontSize: 12,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: TextStyle(
              fontFamily: 'DM Sans',
              fontSize: valueFontSize,
              fontWeight: bold ? FontWeight.w700 : FontWeight.w400,
              color: AppColors.textPrimary,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

class _SuccessGradientButton extends StatelessWidget {
  final VoidCallback onPressed;
  final String label;

  const _SuccessGradientButton({required this.onPressed, required this.label});

  @override
  Widget build(BuildContext context) {
    return AppGradientButton(
      onPressed: onPressed,
      height: 50,
      borderRadius: 20,
      enabledGradient: const LinearGradient(
        colors: [AppColors.successGradientStart, AppColors.successGradientEnd],
      ),
      enabledBoxShadow: const [],
      child: Text(
        label,
        style: AppTypography.header3.copyWith(
          fontSize: 14,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.14,
          color: Colors.white,
        ),
      ),
    );
  }
}
