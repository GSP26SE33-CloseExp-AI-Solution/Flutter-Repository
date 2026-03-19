import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';

/// Screen 5 — QR Scan Modal
Future<String?> showQrScanModal(BuildContext context) {
  final codeController = TextEditingController();

  return showDialog<String?>(
    context: context,
    barrierDismissible: true,
    builder: (context) => Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // ── Modal header — gradient per spec ────────────────────────────
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(16, 16, 8, 16),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppColors.headerGradientStart,
                  AppColors.headerGradientEnd,
                ],
              ),
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Quét mã QR',
                        style: AppTypography.header2.copyWith(
                          fontFamily: 'DM Sans',
                          fontSize: 20,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Hướng camera vào mã QR để xác nhận',
                        style: AppTypography.header3.copyWith(
                          color: Colors.white.withValues(alpha: 0.9),
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    shape: BoxShape.circle,
                  ),
                  child: IconButton(
                    padding: EdgeInsets.zero,
                    icon: const Icon(Icons.close, color: Colors.white, size: 18),
                    onPressed: () => Navigator.pop(context),
                  ),
                ),
              ],
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // ── Camera viewfinder ──────────────────────────────────────
                Container(
                  height: 220,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: const Color(0xFF101828),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.3),
                      width: 3.55,
                    ),
                  ),
                  child: Stack(
                    children: [
                      // Corner accents (QR frame corners)
                      ..._buildQrCorners(),
                      Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.qr_code_scanner,
                              size: 40,
                              color: Colors.white.withValues(alpha: 0.75),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Hướng camera vào mã QR',
                              style: AppTypography.header3.copyWith(
                                color: Colors.white.withValues(alpha: 0.75),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),

                // ── Simulate QR scan — success gradient ────────────────────
                SizedBox(
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
                    child: TextButton(
                      onPressed: () =>
                          Navigator.pop(context, 'MOCK_QR_CODE'),
                      child: Text(
                        'Mô phỏng quét QR',
                        style: AppTypography.subHeader.copyWith(
                          color: Colors.white,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // ── Manual entry ──────────────────────────────────────────
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Hoặc nhập mã thủ công',
                    style: AppTypography.header3.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const SizedBox(height: 8),

                TextField(
                  controller: codeController,
                  decoration: InputDecoration(
                    hintText: 'Nhập mã',
                    hintStyle: AppTypography.header3.copyWith(
                      color: AppColors.textPrimary.withValues(alpha: 0.5),
                      fontSize: 16,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide:
                          const BorderSide(color: Color(0xFFD0D5DB)),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide:
                          const BorderSide(color: Color(0xFFD0D5DB)),
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                // ── Confirm button — reactive via ValueListenableBuilder ───
                // Spec: disabled (#D1D5DC) when empty; active (gradient) when filled
                ValueListenableBuilder<TextEditingValue>(
                  valueListenable: codeController,
                  builder: (context, value, _) {
                    final hasCode = value.text.trim().isNotEmpty;
                    return SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: hasCode
                              ? const LinearGradient(
                                  colors: [
                                    AppColors.successGradientStart,
                                    AppColors.successGradientEnd,
                                  ],
                                )
                              : null,
                          color: hasCode ? null : const Color(0xFFD1D5DC),
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
                            borderRadius: BorderRadius.circular(16),
                            child: Center(
                              child: Text(
                                'Xác nhận mã',
                                style: AppTypography.subHeader.copyWith(
                                  color: Colors.white,
                                  fontSize: 16,
                                ),
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
          ),
        ],
      ),
    ),
  );
}

List<Widget> _buildQrCorners() {
  const c = Color(0xFF05DF72);
  const size = 20.0;
  const thick = 3.5;
  const pad = 20.0;
  return [
    // Top-left
    Positioned(
      top: pad,
      left: pad,
      child: _Corner(color: c, size: size, thick: thick, top: true, left: true),
    ),
    // Top-right
    Positioned(
      top: pad,
      right: pad,
      child:
          _Corner(color: c, size: size, thick: thick, top: true, left: false),
    ),
    // Bottom-left
    Positioned(
      bottom: pad,
      left: pad,
      child:
          _Corner(color: c, size: size, thick: thick, top: false, left: true),
    ),
    // Bottom-right
    Positioned(
      bottom: pad,
      right: pad,
      child:
          _Corner(color: c, size: size, thick: thick, top: false, left: false),
    ),
  ];
}

class _Corner extends StatelessWidget {
  final Color color;
  final double size;
  final double thick;
  final bool top;
  final bool left;

  const _Corner({
    required this.color,
    required this.size,
    required this.thick,
    required this.top,
    required this.left,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _CornerPainter(
          color: color,
          thick: thick,
          top: top,
          left: left,
        ),
      ),
    );
  }
}

class _CornerPainter extends CustomPainter {
  final Color color;
  final double thick;
  final bool top;
  final bool left;

  const _CornerPainter({
    required this.color,
    required this.thick,
    required this.top,
    required this.left,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = thick
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final path = Path();
    if (top && left) {
      path.moveTo(0, size.height);
      path.lineTo(0, 0);
      path.lineTo(size.width, 0);
    } else if (top && !left) {
      path.moveTo(0, 0);
      path.lineTo(size.width, 0);
      path.lineTo(size.width, size.height);
    } else if (!top && left) {
      path.moveTo(0, 0);
      path.lineTo(0, size.height);
      path.lineTo(size.width, size.height);
    } else {
      path.moveTo(0, size.height);
      path.lineTo(size.width, size.height);
      path.lineTo(size.width, 0);
    }
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(_CornerPainter oldDelegate) => false;
}
