import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../../core/constants/app_icons.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';

/// Screen 5 — QR Scan Modal matching exact design from provided image
Future<String?> showQrScanModal(BuildContext context) {
  final codeController = TextEditingController();

  return showDialog<String?>(
    context: context,
    barrierDismissible: true,
    barrierColor: Colors.black.withValues(alpha: 0.90),
    builder: (context) => Center(
      child: Material(
        type: MaterialType.transparency,
        child: Container(
          width: 341.27,
          height: 778.99,
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
          ),
          child: Column(
            children: [
              // ── Header section ──────────────────────────────────────────
              Container(
                width: double.infinity,
                height: 107.95,
                padding: const EdgeInsets.only(top: 24, left: 24, right: 24),
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppColors.headerGradientStart,
                      AppColors.headerGradientEnd,
                    ],
                  ),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  spacing: 7.99,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Quét mã QR',
                          style: AppTypography.header1.copyWith(
                            fontSize: 20,
                            color: Colors.white,
                            letterSpacing: -0.60,
                          ),
                        ),
                        GestureDetector(
                          onTap: () => Navigator.pop(context),
                          child: Container(
                            width: 31.98,
                            height: 31.98,
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.20),
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: Center(
                              child: SvgPicture.asset(
                                AppIcons.close,
                                width: 19.98,
                                height: 19.98,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    Opacity(
                      opacity: 0.90,
                      child: Text(
                        'Quét mã QR từ đơn hàng của khách hàng',
                        style: AppTypography.header3.copyWith(
                          color: Colors.white,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // ── Content section ─────────────────────────────────────────
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(top: 24, left: 24, right: 24),
                  child: Column(
                    children: [
                      // Camera viewfinder section
                      Column(
                        spacing: 15.99,
                        children: [
                          Container(
                            width: double.infinity,
                            height: 293.28,
                            clipBehavior: Clip.antiAlias,
                            decoration: BoxDecoration(
                              color: const Color(0xFF101828),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Stack(
                              children: [
                                // QR scanner icon in center
                                Center(
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Opacity(
                                        opacity: 0.50,
                                        child: SvgPicture.asset(
                                          AppIcons.qrScanner,
                                          width: 63.98,
                                          height: 63.98,
                                        ),
                                      ),
                                      const SizedBox(height: 11.98),
                                      Opacity(
                                        opacity: 0.75,
                                        child: Text(
                                          'Hướng camera vào mã QR',
                                          textAlign: TextAlign.center,
                                          style: AppTypography.header3.copyWith(
                                            color: Colors.white,
                                            fontSize: 14,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),

                                // QR viewfinder frame
                                Positioned(
                                  left: 47.99,
                                  top: 47.99,
                                  child: Container(
                                    width: 197.29,
                                    height: 197.29,
                                    decoration: BoxDecoration(
                                      border: Border.all(
                                        color: Colors.white,
                                        width: 3.55,
                                      ),
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                    child: Stack(
                                      children: [
                                        // Top-left corner
                                        Positioned(
                                          left: 3.55,
                                          top: 3.55,
                                          child: Container(
                                            width: 31.98,
                                            height: 31.98,
                                            decoration: const BoxDecoration(
                                              border: Border(
                                                left: BorderSide(
                                                  color: Color(0xFF05DF72),
                                                  width: 3.55,
                                                ),
                                                top: BorderSide(
                                                  color: Color(0xFF05DF72),
                                                  width: 3.55,
                                                ),
                                              ),
                                              borderRadius: BorderRadius.only(
                                                topLeft: Radius.circular(14),
                                              ),
                                            ),
                                          ),
                                        ),
                                        // Top-right corner
                                        Positioned(
                                          right: 3.55,
                                          top: 3.55,
                                          child: Container(
                                            width: 31.98,
                                            height: 31.98,
                                            decoration: const BoxDecoration(
                                              border: Border(
                                                right: BorderSide(
                                                  color: Color(0xFF05DF72),
                                                  width: 3.55,
                                                ),
                                                top: BorderSide(
                                                  color: Color(0xFF05DF72),
                                                  width: 3.55,
                                                ),
                                              ),
                                              borderRadius: BorderRadius.only(
                                                topRight: Radius.circular(14),
                                              ),
                                            ),
                                          ),
                                        ),
                                        // Bottom-left corner
                                        Positioned(
                                          left: 3.55,
                                          bottom: 3.55,
                                          child: Container(
                                            width: 31.98,
                                            height: 31.98,
                                            decoration: const BoxDecoration(
                                              border: Border(
                                                left: BorderSide(
                                                  color: Color(0xFF05DF72),
                                                  width: 3.55,
                                                ),
                                                bottom: BorderSide(
                                                  color: Color(0xFF05DF72),
                                                  width: 3.55,
                                                ),
                                              ),
                                              borderRadius: BorderRadius.only(
                                                bottomLeft: Radius.circular(14),
                                              ),
                                            ),
                                          ),
                                        ),
                                        // Bottom-right corner
                                        Positioned(
                                          right: 3.55,
                                          bottom: 3.55,
                                          child: Container(
                                            width: 31.98,
                                            height: 31.98,
                                            decoration: const BoxDecoration(
                                              border: Border(
                                                right: BorderSide(
                                                  color: Color(0xFF05DF72),
                                                  width: 3.55,
                                                ),
                                                bottom: BorderSide(
                                                  color: Color(0xFF05DF72),
                                                  width: 3.55,
                                                ),
                                              ),
                                              borderRadius: BorderRadius.only(
                                                bottomRight: Radius.circular(
                                                  14,
                                                ),
                                              ),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),

                          // XXX: Remove this button after testing
                          Container(
                            width: double.infinity,
                            height: 47.97,
                            decoration: const BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  AppColors.successGradientStart,
                                  AppColors.successGradientEnd,
                                ],
                              ),
                              borderRadius: BorderRadius.all(
                                Radius.circular(16),
                              ),
                            ),
                            child: Material(
                              color: Colors.transparent,
                              borderRadius: BorderRadius.circular(16),
                              child: InkWell(
                                onTap: () =>
                                    Navigator.pop(context, 'MOCK_QR_CODE'),
                                borderRadius: BorderRadius.circular(16),
                                child: const Center(
                                  child: Text(
                                    'Mô phỏng quét QR',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 16,
                                      fontFamily: 'Be Vietnam Pro',
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 24),

                      // Manual input section
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.only(top: 25.18),
                        decoration: const BoxDecoration(
                          border: Border(
                            top: BorderSide(
                              color: Color(0xFFE5E7EB),
                              width: 1.18,
                            ),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          spacing: 12,
                          children: [
                            Text(
                              'Hoặc nhập mã thủ công',
                              style: AppTypography.header3.copyWith(
                                fontWeight: FontWeight.w700,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            Column(
                              spacing: 12,
                              children: [
                                // Input field — DesignSystem Forms + AppTheme.inputDecorationTheme
                                SizedBox(
                                  width: double.infinity,
                                  height: 50,
                                  child: TextField(
                                    controller: codeController,
                                    style: AppTypography.bodyRegular1.copyWith(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w400,
                                      color: AppColors.neutralDark,
                                      height: 1.37,
                                    ),
                                    decoration:
                                        InputDecoration(
                                          hintText: 'Nhập mã QR',
                                        ).applyDefaults(
                                          Theme.of(
                                            context,
                                          ).inputDecorationTheme,
                                        ),
                                  ),
                                ),

                                // Confirm button with reactive state
                                ValueListenableBuilder<TextEditingValue>(
                                  valueListenable: codeController,
                                  builder: (context, value, _) {
                                    final hasCode = value.text
                                        .trim()
                                        .isNotEmpty;
                                    return Container(
                                      width: double.infinity,
                                      height: 47.97,
                                      decoration: BoxDecoration(
                                        gradient: hasCode
                                            ? const LinearGradient(
                                                colors: [
                                                  AppColors
                                                      .successGradientStart,
                                                  AppColors.successGradientEnd,
                                                ],
                                              )
                                            : null,
                                        color: hasCode
                                            ? null
                                            : const Color(0xFFD1D5DC),
                                        borderRadius: BorderRadius.circular(16),
                                      ),
                                      child: Material(
                                        color: Colors.transparent,
                                        borderRadius: BorderRadius.circular(16),
                                        child: InkWell(
                                          onTap: hasCode
                                              ? () => Navigator.pop(
                                                  context,
                                                  codeController.text.trim(),
                                                )
                                              : null,
                                          borderRadius: BorderRadius.circular(
                                            16,
                                          ),
                                          child: const Center(
                                            child: Text(
                                              'Xác nhận mã',
                                              textAlign: TextAlign.center,
                                              style: TextStyle(
                                                color: Colors.white,
                                                fontSize: 16,
                                                fontFamily: 'Be Vietnam Pro',
                                                fontWeight: FontWeight.w700,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  ).whenComplete(codeController.dispose);
}
