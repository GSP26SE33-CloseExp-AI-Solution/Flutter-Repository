import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';

/// Common reusable widgets for Delivery feature

// ============== GRADIENT APP BAR ==============

/// Reusable gradient AppBar used across all delivery screens.
/// Implements [PreferredSizeWidget] so it can be used directly as `appBar:`.
class GradientAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final String? subtitle;
  final List<Widget>? actions;
  final bool centerTitle;
  final Widget? leading;

  const GradientAppBar({
    super.key,
    required this.title,
    this.subtitle,
    this.actions,
    this.centerTitle = true,
    this.leading,
  });

  @override
  Size get preferredSize =>
      Size.fromHeight(subtitle != null ? kToolbarHeight + 20 : kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: Colors.transparent,
      foregroundColor: AppColors.onPrimary,
      centerTitle: centerTitle,
      elevation: 0,
      systemOverlayStyle: SystemUiOverlayStyle.light,
      leading: leading,
      actions: actions,
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
      title: subtitle != null
          ? Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                  title,
                  style: AppTypography.header1.copyWith(
                    fontSize: 20,
                    color: AppColors.onPrimary,
                    letterSpacing: -0.60,
                  ),
                ),
                Text(
                  subtitle!,
                  style: AppTypography.header3.copyWith(
                    color: AppColors.onPrimary.withValues(alpha: 0.9),
                  ),
                ),
              ],
            )
          : Text(
              title,
              style: AppTypography.header1.copyWith(
                fontSize: 20,
                color: AppColors.onPrimary,
                letterSpacing: -0.60,
              ),
            ),
    );
  }
}

// ============== GRADIENT BUTTON ==============

/// Full-width primary gradient button — matches Design System primary button spec.
/// Automatically shows disabled styling when [onPressed] is null.
class AppGradientButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final Widget child;
  final double height;
  final double borderRadius;
  final Gradient? enabledGradient;
  final List<BoxShadow>? enabledBoxShadow;

  const AppGradientButton({
    super.key,
    required this.onPressed,
    required this.child,
    this.height = 50,
    this.borderRadius = 20,
    this.enabledGradient,
    this.enabledBoxShadow,
  });

  @override
  Widget build(BuildContext context) {
    final isDisabled = onPressed == null;
    return SizedBox(
      height: height,
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: isDisabled
              ? null
              : (enabledGradient ??
                    const LinearGradient(
                      colors: [
                        AppColors.primaryGradientStart,
                        AppColors.primaryGradientEnd,
                      ],
                    )),
          color: isDisabled ? AppColors.neutralLight : null,
          borderRadius: BorderRadius.circular(borderRadius),
          boxShadow: isDisabled
              ? null
              : (enabledBoxShadow ??
                    [
                      BoxShadow(
                        color: AppColors.primaryButtonShadow.withValues(
                          alpha: 0.10,
                        ),
                        blurRadius: 30,
                        offset: const Offset(0, 10),
                      ),
                    ]),
        ),
        child: Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(borderRadius),
          child: InkWell(
            onTap: onPressed,
            borderRadius: BorderRadius.circular(borderRadius),
            child: Center(child: child),
          ),
        ),
      ),
    );
  }
}

// ============== OUTLINED ACTION BUTTON (full width) ==============

/// Nút viền full-width (icon + label) theo Design System — đủ chiều cao / padding cho chữ dài.
class AppDeliveryOutlinedButton extends StatelessWidget {
  const AppDeliveryOutlinedButton({
    super.key,
    required this.onPressed,
    required this.icon,
    required this.label,
    required this.foregroundColor,
    this.borderRadius = 16,
    this.minHeight = 52,
  });

  final VoidCallback? onPressed;
  final IconData icon;
  final String label;
  final Color foregroundColor;
  final double borderRadius;
  final double minHeight;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon, size: 22),
        label: Text(
          label,
          textAlign: TextAlign.center,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        style: OutlinedButton.styleFrom(
          minimumSize: Size.fromHeight(minHeight),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          foregroundColor: foregroundColor,
          side: BorderSide(color: foregroundColor),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(borderRadius),
          ),
          textStyle: AppTypography.header3.copyWith(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            height: 1.25,
          ),
        ),
      ),
    );
  }
}

// ============== INFO ROW ==============

/// Info row with icon, label and value
class DeliveryInfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Widget? trailing;

  const DeliveryInfoRow({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(icon, size: 20, color: AppColors.neutralMid),
          const SizedBox(width: 12),
          Text(
            '$label: ',
            style: AppTypography.bodyRegular1.copyWith(
              color: AppColors.neutralMid,
              fontSize: 13,
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: AppTypography.bodyRegular1.copyWith(
                fontWeight: FontWeight.w500,
                fontSize: 13,
                color: AppColors.neutralDark,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (trailing != null) trailing!,
        ],
      ),
    );
  }
}

/// Simple info row with icon and text only (no label)
class DeliveryInfoRowSimple extends StatelessWidget {
  final IconData icon;
  final String text;
  final int? maxLines;

  const DeliveryInfoRowSimple({
    super.key,
    required this.icon,
    required this.text,
    this.maxLines,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 16, color: AppColors.neutralMid),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: AppTypography.bodyRegular1.copyWith(
                fontSize: 13,
                color: AppColors.neutralDark,
              ),
              maxLines: maxLines,
              overflow: maxLines != null ? TextOverflow.ellipsis : null,
            ),
          ),
        ],
      ),
    );
  }
}

/// Info row with action button
class DeliveryInfoRowWithAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final VoidCallback onAction;
  final IconData actionIcon;
  final Color? actionColor;

  const DeliveryInfoRowWithAction({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
    required this.onAction,
    required this.actionIcon,
    this.actionColor,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(icon, size: 20, color: AppColors.neutralMid),
          const SizedBox(width: 12),
          Text(
            '$label: ',
            style: AppTypography.bodyRegular1.copyWith(
              color: AppColors.neutralMid,
              fontSize: 13,
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: AppTypography.bodyRegular1.copyWith(
                fontWeight: FontWeight.w500,
                fontSize: 13,
                color: AppColors.neutralDark,
              ),
            ),
          ),
          IconButton(
            icon: Icon(actionIcon, color: actionColor ?? AppColors.accent),
            onPressed: onAction,
            iconSize: 20,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
        ],
      ),
    );
  }
}

// ============== STAT ITEM ==============

/// Statistics item with value and label
class DeliveryStatItem extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  final double valueFontSize;

  const DeliveryStatItem({
    super.key,
    required this.label,
    required this.value,
    required this.color,
    this.valueFontSize = 24,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontFamily: 'DM Sans',
            fontSize: valueFontSize,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: AppTypography.bodyRegular1.copyWith(
            color: AppColors.neutralMid,
          ),
        ),
      ],
    );
  }
}

// ============== EMPTY STATE ==============

/// Empty state widget with icon, title, subtitle and optional action
class DeliveryEmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final String? actionLabel;
  final VoidCallback? onAction;

  const DeliveryEmptyState({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight - 32),
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(icon, size: 80, color: AppColors.neutralMid),
                  const SizedBox(height: 16),
                  Text(
                    title,
                    style: AppTypography.subHeader.copyWith(
                      color: AppColors.neutralMid,
                    ),
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 8),
                    Text(
                      subtitle!,
                      style: AppTypography.header3.copyWith(
                        color: AppColors.neutralMid,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                  if (actionLabel != null && onAction != null) ...[
                    const SizedBox(height: 40),
                    Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: (MediaQuery.sizeOf(context).width * 0.06)
                            .clamp(16.0, 32.0),
                      ),
                      child: AppGradientButton(
                        onPressed: onAction,
                        child: SizedBox(
                          width: double.infinity,
                          child: Center(
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.refresh,
                                  color: AppColors.neutralLight,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  actionLabel!,
                                  style: AppTypography.subHeader.copyWith(
                                    color: AppColors.neutralLight,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

// ============== ERROR STATE ==============

/// Error state widget with icon, message and retry action
class DeliveryErrorState extends StatelessWidget {
  final String message;
  final VoidCallback? onRetry;
  final String? secondaryActionLabel;
  final VoidCallback? onSecondaryAction;

  const DeliveryErrorState({
    super.key,
    required this.message,
    this.onRetry,
    this.secondaryActionLabel,
    this.onSecondaryAction,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            size: 64,
            color: AppColors.error.withValues(alpha: 0.7),
          ),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Text(
              message,
              textAlign: TextAlign.center,
              style: AppTypography.header3.copyWith(
                color: AppColors.neutralDark,
              ),
            ),
          ),
          if (onRetry != null) ...[
            const SizedBox(height: 16),
            ElevatedButton(onPressed: onRetry, child: const Text('Thử lại')),
          ],
          if (secondaryActionLabel != null && onSecondaryAction != null) ...[
            const SizedBox(height: 12),
            OutlinedButton(
              onPressed: onSecondaryAction,
              child: Text(secondaryActionLabel!),
            ),
          ],
        ],
      ),
    );
  }
}

// ============== LOADING STATE ==============

/// Loading state widget with indicator and optional message
class DeliveryLoadingState extends StatelessWidget {
  final String? message;

  const DeliveryLoadingState({super.key, this.message});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(),
          if (message != null) ...[
            const SizedBox(height: 16),
            Text(
              message!,
              style: AppTypography.bodyRegular1.copyWith(
                color: AppColors.neutralMid,
                fontSize: 13,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ============== SECTION HEADER ==============

/// Section header with title and optional action
class DeliverySectionHeader extends StatelessWidget {
  final String title;
  final String? actionLabel;
  final VoidCallback? onAction;

  const DeliverySectionHeader({
    super.key,
    required this.title,
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(title, style: AppTypography.subHeader),
        if (actionLabel != null && onAction != null)
          TextButton(
            onPressed: onAction,
            child: Text(
              actionLabel!,
              style: AppTypography.bodyRegular1.copyWith(
                color: AppColors.accent,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
      ],
    );
  }
}

// ============== NOTE CARD ==============

/// Note card for displaying notes/remarks
class DeliveryNoteCard extends StatelessWidget {
  final String note;
  final Color? backgroundColor;
  final Color? borderColor;
  final Color? textColor;
  final FontStyle? fontStyle;
  final IconData icon;
  final Color? iconColor;

  const DeliveryNoteCard({
    super.key,
    required this.note,
    this.backgroundColor,
    this.borderColor,
    this.textColor,
    this.fontStyle,
    this.icon = Icons.note,
    this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: backgroundColor ?? AppColors.deliveryNoteBackground,
        border: Border.all(
          color:
              borderColor ??
              AppColors.primaryGradientStart.withValues(alpha: 0.4),
        ),
        borderRadius: BorderRadius.circular(8),
      ),
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          Icon(icon, color: iconColor ?? AppColors.primaryGradientStart),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              note,
              style: AppTypography.header3.copyWith(
                color: textColor ?? AppColors.neutralDark,
                fontStyle: fontStyle ?? FontStyle.italic,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ============== CONFIRMATION DIALOG ==============

/// Show confirmation dialog with title, content and actions.
///
/// Avoids [AppGradientButton] in [AlertDialog.actions] (overflow on narrow screens).
Future<bool?> showDeliveryConfirmDialog({
  required BuildContext context,
  required String title,
  required String content,
  String confirmLabel = 'Xác nhận',
  String cancelLabel = 'Hủy',
  Color? confirmColor,
}) {
  final resolvedConfirmColor = confirmColor ?? AppColors.primaryGradientEnd;

  return showDialog<bool>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: Text(title, style: AppTypography.header2),
      content: SingleChildScrollView(
        child: Text(content, style: AppTypography.header3),
      ),
      actionsOverflowButtonSpacing: 8,
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(dialogContext, false),
          child: Text(
            cancelLabel,
            style: AppTypography.subHeader.copyWith(
              color: AppColors.neutralMid,
            ),
          ),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(dialogContext, true),
          style: FilledButton.styleFrom(
            backgroundColor: resolvedConfirmColor,
            foregroundColor: AppColors.onPrimary,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: Text(
            confirmLabel,
            style: AppTypography.subHeader.copyWith(
              color: AppColors.onPrimary,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    ),
  );
}
