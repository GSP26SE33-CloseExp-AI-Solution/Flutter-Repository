import 'package:flutter/material.dart';

/// App color system — synced with DesignSystem.mkd + Sceen.mkd
class AppColors {
  AppColors._();

  // ── Primary ───────────────────────────────────────────────────────────────
  static const primary = Color(0xFF1B5E20);
  static const primaryGradientStart = Color(0xFF1B5E20);
  static const primaryGradientEnd = Color(0xFF2E7D32);
  static const accent = Color(0xFF2E7D32);

  // ── Header gradient — screen headers, AppBar overlays, featured sections ──
  static const headerGradientStart = Color(0xFF1B5E20);
  static const headerGradientEnd = Color(0xFF2E7D32);

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

  /// Text/icons on primary or dark surfaces
  static const onPrimary = Color(0xFFFFFFFF);

  /// Input label and hint colors
  static const inputLabel = Color(0xFF3C3C3C);
  static const inputHint = Color(0xFFA9ABAE);

  // ── Surface ───────────────────────────────────────────────────────────────
  static const surfaceWhite = Color(0xFFFCFCFC);
  static const background = Color(0xFFF7F7FB);

  /// Card/item border
  static const cardBorder = Color(0xFFF2F4F6);

  /// Info chips, stat boxes background
  static const cardSurface = Color(0xFFF9FAFB);

  /// Avatar circle background on profile-like screens
  static const avatarBackground = Color(0xFFF3F4F6);

  /// Highlight background for unread notification cards
  static const notificationUnreadBackground = Color(0xFFF2F8FF);

  /// Background for notification metadata chips
  static const notificationMetaChipBackground = Color(0xFFF5F7FB);

  /// Overlay + shadow helpers
  static const scrimStrong = Color(0xE6000000);
  static const shadowLight = Color(0x0F000000);
  static const shadowSoft = Color(0x14000000);
  static const shadowMedium = Color(0x1A000000);

  // ── Semantic ──────────────────────────────────────────────────────────────
  static const error = Color(0xFFE53935);

  /// Delivery status semantic: in-transit group / waiting confirm order
  static const statusInTransit = Color(0xFF7C3AED);

  /// Delivery status semantic: picked-up and in-transit delivery leg
  static const statusDeliveryLeg = Color(0xFF2563EB);

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

  /// Map: shipper + route styling
  static const mapShipperMarker = Color(0xFF1D4ED8);
  static const mapPickupLegLine = Color(0xFF1D4ED8);
  static const mapDeliveryLegLine = Color(0xFFE53935);
  static const mapStopMarker = Color(0xFFE53935);
  static const mapPickupMarker = Color(0xFFF59E0B);
  static const mapStopText = Color(0xFFFFFFFF);
  static const mapStopTextHalo = Color(0xFF000000);
  static const mapWarningBackground = Color(0xFFFFECB3);
  static const mapWarningText = Color(0xFFF57C00);
  static const mapWarningTextStrong = Color(0xFFEF6C00);
  static const mapSuccessStrong = Color(0xFF059669);

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
  static const primaryButtonShadow = Color(0xFF1B5E20);

  /// Delivery note default surface
  static const deliveryNoteBackground = Color(0xFFFFFBEB);
}
