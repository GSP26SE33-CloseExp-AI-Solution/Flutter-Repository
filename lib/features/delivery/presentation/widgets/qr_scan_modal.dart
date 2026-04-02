import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../../../../core/constants/app_icons.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';

/// True when [MobileScanner] có plugin native (Android / iOS / macOS / Web).
bool _supportsLiveQrScanner() {
  if (kIsWeb) return true;
  return switch (defaultTargetPlatform) {
    TargetPlatform.android ||
    TargetPlatform.iOS ||
    TargetPlatform.macOS => true,
    _ => false,
  };
}

/// Screen 5 — QR Scan Modal: camera thật + nhập tay (Forms theme).
Future<String?> showQrScanModal(BuildContext context) {
  return showDialog<String?>(
    context: context,
    barrierDismissible: true,
    barrierColor: Colors.black.withValues(alpha: 0.90),
    builder: (context) {
      final mediaQuery = MediaQuery.of(context);
      final dialogWidth = mediaQuery.size.width > 365.27
          ? 341.27
          : mediaQuery.size.width - 24;
      final dialogHeight = mediaQuery.size.height > 810
          ? 778.99
          : mediaQuery.size.height -
                mediaQuery.padding.vertical -
                mediaQuery.viewInsets.vertical -
                16;

      return Center(
        child: Material(
          type: MaterialType.transparency,
          child: _QrScanModalContent(
            dialogWidth: dialogWidth,
            dialogHeight: dialogHeight,
          ),
        ),
      );
    },
  );
}

class _QrScanModalContent extends StatefulWidget {
  const _QrScanModalContent({
    required this.dialogWidth,
    required this.dialogHeight,
  });

  final double dialogWidth;
  final double dialogHeight;

  @override
  State<_QrScanModalContent> createState() => _QrScanModalContentState();
}

class _QrScanModalContentState extends State<_QrScanModalContent> {
  late final TextEditingController _codeController;
  MobileScannerController? _scannerController;
  bool _handled = false;

  @override
  void initState() {
    super.initState();
    _codeController = TextEditingController();
    if (_supportsLiveQrScanner()) {
      _scannerController = MobileScannerController(
        detectionSpeed: DetectionSpeed.noDuplicates,
        facing: CameraFacing.back,
        formats: const [BarcodeFormat.qrCode],
      );
    }
  }

  @override
  void dispose() {
    _codeController.dispose();
    _scannerController?.dispose();
    super.dispose();
  }

  void _onBarcodeDetected(BarcodeCapture capture) {
    if (!mounted || _handled) return;
    for (final barcode in capture.barcodes) {
      final raw = barcode.rawValue?.trim();
      if (raw != null && raw.isNotEmpty) {
        _handled = true;
        Navigator.of(context).pop(raw);
        return;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final live = _supportsLiveQrScanner();

    return SizedBox(
      width: widget.dialogWidth,
      height: widget.dialogHeight,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: ColoredBox(
          color: Colors.white,
          child: Column(
            children: [
              _buildHeader(context),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(24, 24, 24, 24),
                  child: Column(
                    children: [
                      _buildViewfinderSection(context, live: live),
                      const SizedBox(height: 24),
                      _buildManualSection(context),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 107.95,
      padding: const EdgeInsets.only(top: 24, left: 24, right: 24),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.headerGradientStart, AppColors.headerGradientEnd],
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
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildViewfinderSection(BuildContext context, {required bool live}) {
    return Column(
      spacing: 15.99,
      children: [
        SizedBox(
          width: double.infinity,
          height: 293.28,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: live && _scannerController != null
                ? _buildLiveScanner()
                : _buildPlaceholderScanner(),
          ),
        ),
        if (!live)
          _buildMockScanButton(context)
        else
          Text(
            'Camera đang bật — đưa mã QR vào khung xanh',
            textAlign: TextAlign.center,
            style: AppTypography.header3.copyWith(
              color: AppColors.textSecondary,
              fontSize: 12,
            ),
          ),
      ],
    );
  }

  Widget _buildLiveScanner() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final w = constraints.maxWidth;
        final h = constraints.maxHeight;
        final side = (w * 0.55).clamp(120.0, 220.0);
        final left = (w - side) / 2;
        final top = (h - side) / 2.15;
        final scanRect = Rect.fromLTWH(left, top, side, side);

        return Stack(
          fit: StackFit.expand,
          children: [
            MobileScanner(
              controller: _scannerController,
              onDetect: _onBarcodeDetected,
              fit: BoxFit.cover,
              scanWindow: kIsWeb ? null : scanRect,
              errorBuilder: (context, error) => _ScannerErrorView(error: error),
            ),
            IgnorePointer(
              child: Stack(
                fit: StackFit.expand,
                children: [
                  _ViewfinderFrameOverlay(frameRect: scanRect),
                  Positioned(
                    left: 0,
                    right: 0,
                    bottom: 12,
                    child: Opacity(
                      opacity: 0.75,
                      child: Text(
                        'Hướng camera vào mã QR',
                        textAlign: TextAlign.center,
                        style: AppTypography.header3.copyWith(
                          color: Colors.white,
                          fontSize: 13,
                          shadows: const [
                            Shadow(blurRadius: 8, color: Colors.black54),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildPlaceholderScanner() {
    return ColoredBox(
      color: const Color(0xFF101828),
      child: Stack(
        children: [
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
                    'Thiết bị không hỗ trợ camera trực tiếp',
                    textAlign: TextAlign.center,
                    style: AppTypography.header3.copyWith(
                      color: Colors.white,
                      fontSize: 13,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Positioned(
            left: 47.99,
            top: 47.99,
            child: SizedBox(
              width: 197.29,
              height: 197.29,
              child: _StaticViewfinderCorners(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMockScanButton(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 47.97,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.successGradientStart,
            AppColors.successGradientEnd,
          ],
        ),
        borderRadius: BorderRadius.all(Radius.circular(16)),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: () => Navigator.pop(context, 'MOCK_QR_CODE'),
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
    );
  }

  Widget _buildManualSection(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.only(top: 25.18),
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: Color(0xFFE5E7EB), width: 1.18)),
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
              SizedBox(
                width: double.infinity,
                height: 50,
                child: TextField(
                  controller: _codeController,
                  style: AppTypography.bodyRegular1.copyWith(
                    fontSize: 14,
                    fontWeight: FontWeight.w400,
                    color: AppColors.neutralDark,
                    height: 1.37,
                  ),
                  decoration: InputDecoration(
                    hintText: 'Nhập mã QR',
                  ).applyDefaults(Theme.of(context).inputDecorationTheme),
                ),
              ),
              ValueListenableBuilder<TextEditingValue>(
                valueListenable: _codeController,
                builder: (context, value, _) {
                  final hasCode = value.text.trim().isNotEmpty;
                  return Container(
                    width: double.infinity,
                    height: 47.97,
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
                                _codeController.text.trim(),
                              )
                            : null,
                        borderRadius: BorderRadius.circular(16),
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
    );
  }
}

/// Viền trắng + góc xanh theo layout spec, căn theo [frameRect].
class _ViewfinderFrameOverlay extends StatelessWidget {
  const _ViewfinderFrameOverlay({required this.frameRect});

  final Rect frameRect;

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        Positioned(
          left: frameRect.left,
          top: frameRect.top,
          width: frameRect.width,
          height: frameRect.height,
          child: _StaticViewfinderCorners(),
        ),
      ],
    );
  }
}

/// Góc xanh + viền trắng (cùng kích thước tương đối như bản tĩnh).
class _StaticViewfinderCorners extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Container(
          decoration: BoxDecoration(
            border: Border.all(color: Colors.white, width: 3.55),
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        Positioned(
          left: 3.55,
          top: 3.55,
          child: Container(
            width: 31.98,
            height: 31.98,
            decoration: const BoxDecoration(
              border: Border(
                left: BorderSide(color: Color(0xFF05DF72), width: 3.55),
                top: BorderSide(color: Color(0xFF05DF72), width: 3.55),
              ),
              borderRadius: BorderRadius.only(topLeft: Radius.circular(14)),
            ),
          ),
        ),
        Positioned(
          right: 3.55,
          top: 3.55,
          child: Container(
            width: 31.98,
            height: 31.98,
            decoration: const BoxDecoration(
              border: Border(
                right: BorderSide(color: Color(0xFF05DF72), width: 3.55),
                top: BorderSide(color: Color(0xFF05DF72), width: 3.55),
              ),
              borderRadius: BorderRadius.only(topRight: Radius.circular(14)),
            ),
          ),
        ),
        Positioned(
          left: 3.55,
          bottom: 3.55,
          child: Container(
            width: 31.98,
            height: 31.98,
            decoration: const BoxDecoration(
              border: Border(
                left: BorderSide(color: Color(0xFF05DF72), width: 3.55),
                bottom: BorderSide(color: Color(0xFF05DF72), width: 3.55),
              ),
              borderRadius: BorderRadius.only(bottomLeft: Radius.circular(14)),
            ),
          ),
        ),
        Positioned(
          right: 3.55,
          bottom: 3.55,
          child: Container(
            width: 31.98,
            height: 31.98,
            decoration: const BoxDecoration(
              border: Border(
                right: BorderSide(color: Color(0xFF05DF72), width: 3.55),
                bottom: BorderSide(color: Color(0xFF05DF72), width: 3.55),
              ),
              borderRadius: BorderRadius.only(bottomRight: Radius.circular(14)),
            ),
          ),
        ),
      ],
    );
  }
}

class _ScannerErrorView extends StatelessWidget {
  const _ScannerErrorView({required this.error});

  final MobileScannerException error;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: const Color(0xFF101828),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.videocam_off_outlined,
                color: Colors.white.withValues(alpha: 0.8),
                size: 40,
              ),
              const SizedBox(height: 12),
              Text(
                'Không mở được camera.\nVui lòng cấp quyền hoặc nhập mã thủ công bên dưới.',
                textAlign: TextAlign.center,
                style: AppTypography.header3.copyWith(
                  color: Colors.white,
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                error.errorDetails?.message ?? error.errorCode.name,
                textAlign: TextAlign.center,
                style: AppTypography.bodyRegular1.copyWith(
                  fontSize: 11,
                  color: Colors.white54,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
