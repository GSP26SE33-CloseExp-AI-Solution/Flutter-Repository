import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../domain/entities/delivery_group.dart';
import '../../domain/entities/delivery_order.dart';

/// Status badge widgets for Delivery feature

// ── Base status badge ─────────────────────────────────────────────────────

class StatusBadge extends StatelessWidget {
  final String text;
  final Color color;
  final double fontSize;
  final EdgeInsets padding;
  final double borderRadius;
  final bool hasBorder;

  const StatusBadge({
    super.key,
    required this.text,
    required this.color,
    this.fontSize = 12,
    this.padding = const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
    this.borderRadius = 16,
    this.hasBorder = true,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(borderRadius),
        border: hasBorder ? Border.all(color: color) : null,
      ),
      child: Text(
        text,
        style: AppTypography.bodyRegular1.copyWith(
          fontSize: fontSize,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }
}

// ── Status color helpers ──────────────────────────────────────────────────

/// Semantic color for each delivery group status.
Color getGroupStatusColor(DeliveryGroupStatus status) {
  switch (status) {
    case DeliveryGroupStatus.pending:
      return AppColors.accent;
    case DeliveryGroupStatus.assigned:
      return AppColors.primaryGradientStart;
    case DeliveryGroupStatus.inTransit:
      return const Color(0xFF7C3AED); // purple — in-transit
    case DeliveryGroupStatus.completed:
      return AppColors.successGradientStart;
  }
}

/// Semantic color for each delivery order status.
Color getOrderStatusColor(DeliveryOrderStatus status) {
  switch (status) {
    case DeliveryOrderStatus.pending:
    case DeliveryOrderStatus.paidProcessing:
      return AppColors.primaryGradientStart; // orange
    case DeliveryOrderStatus.readyToShip:
      return AppColors.accent; // teal/green
    case DeliveryOrderStatus.deliveredWaitConfirm:
      return const Color(0xFF7C3AED); // purple
    case DeliveryOrderStatus.completed:
      return AppColors.successGradientStart; // green
    case DeliveryOrderStatus.failed:
      return AppColors.error; // primary red
    case DeliveryOrderStatus.canceled:
    case DeliveryOrderStatus.refunded:
      return AppColors.neutralMid; // grey
  }
}

// ── Group status badge ────────────────────────────────────────────────────

class DeliveryGroupStatusBadge extends StatelessWidget {
  final DeliveryGroupStatus status;
  final bool compact;

  const DeliveryGroupStatusBadge({
    super.key,
    required this.status,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    return StatusBadge(
      text: status.displayName,
      color: getGroupStatusColor(status),
      padding: compact
          ? const EdgeInsets.symmetric(horizontal: 8, vertical: 4)
          : const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      fontSize: compact ? 11 : 12,
    );
  }
}

// ── Order status badge ────────────────────────────────────────────────────

class DeliveryOrderStatusBadge extends StatelessWidget {
  final DeliveryOrderStatus status;
  final bool compact;

  const DeliveryOrderStatusBadge({
    super.key,
    required this.status,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    return StatusBadge(
      text: status.displayName,
      color: getOrderStatusColor(status),
      padding: compact
          ? const EdgeInsets.symmetric(horizontal: 8, vertical: 4)
          : const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      fontSize: compact ? 11 : 12,
      borderRadius: 10,
      hasBorder: false,
    );
  }
}

// ── Delivery record status badge ──────────────────────────────────────────

class DeliveryRecordStatusBadge extends StatelessWidget {
  final DeliveryOrderStatus status;

  const DeliveryRecordStatusBadge({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    return StatusBadge(
      text: status.displayName,
      color: getOrderStatusColor(status),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      fontSize: 11,
      borderRadius: 8,
      hasBorder: false,
    );
  }
}
