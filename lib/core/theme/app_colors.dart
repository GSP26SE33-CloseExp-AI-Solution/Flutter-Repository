import 'package:flutter/material.dart';

/// App color system — synced with DesignSystem.mkd + Sceen.mkd
class AppColors {
  AppColors._();

  // ── Primary ───────────────────────────────────────────────────────────────
  static const primary = Color(0xFFFE554A);
  static const primaryGradientStart = Color(0xFFF9881F);
  static const primaryGradientEnd = Color(0xFFFF774C);
  static const accent = Color(0xFF0B735F);

  // ── Header gradient — screen headers, AppBar overlays, featured sections ──
  static const headerGradientStart = Color(0xFFFF6800);
  static const headerGradientEnd = Color(0xFFFA2B36);

  // ── Success gradient — QR confirm, delivery success states ────────────────
  static const successGradientStart = Color(0xFF00C850);
  static const successGradientEnd = Color(0xFF00A63D);

  // ── Neutral ───────────────────────────────────────────────────────────────
  static const neutralDark = Color(0xFF2A3037);
  static const neutralMid = Color(0xFFC6C9CC);
  static const neutralLight = Color(0xFFDFE2E5);

  // ── Text ──────────────────────────────────────────────────────────────────
  /// Near-black for card titles, bold primary text
  static const textPrimary = Color(0xFF0A0A0A);
  /// Muted grey for labels, secondary info
  static const textSecondary = Color(0xFF697282);

  // ── Surface ───────────────────────────────────────────────────────────────
  static const surfaceWhite = Color(0xFFFCFCFC);
  static const background = Color(0xFFF7F7FB);
  /// Card/item border
  static const cardBorder = Color(0xFFF2F4F6);
  /// Info chips, stat boxes background
  static const cardSurface = Color(0xFFF9FAFB);

  // ── Semantic ──────────────────────────────────────────────────────────────
  static const error = primary;

  // ── Delivery / screen tokens (Sceen.mkd) ─────────────────────────────────
  /// Strong dividers, footer borders, map placeholder background
  static const dividerStrong = Color(0xFFE5E7EB);
  /// Disabled filled controls (manual QR confirm, sheet CTAs when inactive)
  static const disabledControlFill = Color(0xFFD1D5DC);
  /// Dropdown / manual input border (delivery sheets)
  static const inputBorderStrong = Color(0xFFD0D5DB);
  /// QR camera viewfinder background
  static const qrViewfinderBackground = Color(0xFF101828);
  /// QR frame corner accent on white border
  static const qrCornerAccent = Color(0xFF05DF72);
  /// Pill: total orders (urgent tone)
  static const badgeUrgentBackground = Color(0xFFFFE2E2);
  static const badgeUrgentText = Color(0xFFE7000B);
  /// Pill: pending delivery
  static const badgePendingBackground = Color(0xFFFFEDD4);
  static const badgePendingText = Color(0xFFF44900);
  /// Map route option — selected panel background
  static const routeOptionActiveBackground = Color(0xFFFEF2F2);
  /// “Chỉ đường” and map CTAs
  static const directionsBlue = Color(0xFF2B7FFF);
  /// Address / body text on light cards
  static const bodyOnSurface = Color(0xFF495565);
  /// Customer row — call action circle
  static const callActionBackground = Color(0xFFDCFCE7);
  /// Order total banner (gradient)
  static const orderTotalGradientStart = Color(0xFFFFF7EC);
  static const orderTotalGradientEnd = Color(0xFFFEF2F2);
  /// Failure sheet — warning callout
  static const warningNoticeBackground = Color(0xFFFEFCE8);
  static const warningNoticeBorder = Color(0xFFFFDF20);
  static const warningNoticeText = Color(0xFF884A00);
  /// Primary button shadow (DesignSystem.mkd)
  static const primaryButtonShadow = Color(0xFFC94210);
  /// Delivery note default surface
  static const deliveryNoteBackground = Color(0xFFFFFBEB);
}
