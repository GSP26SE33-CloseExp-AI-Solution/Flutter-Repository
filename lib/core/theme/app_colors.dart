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
}
