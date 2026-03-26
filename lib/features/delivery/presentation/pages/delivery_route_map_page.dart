import 'package:flutter/material.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';
import '../../../../core/constants/mapbox_config.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';

/// Screen 2: Map View.
///
/// Uses Mapbox when access token is provided via --dart-define.
class DeliveryRouteMapPage extends StatelessWidget {
  const DeliveryRouteMapPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(child: _buildMapLayer()),

          // Gradient overlay (top)
          Positioned(
            left: 0,
            right: 0,
            top: 0,
            height: 180,
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.black54, Colors.transparent],
                ),
              ),
            ),
          ),

          // Floating AppBar
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  Material(
                    color: Colors.white,
                    shape: const CircleBorder(),
                    elevation: 3,
                    child: IconButton(
                      icon: const Icon(
                        Icons.arrow_back,
                        size: 24,
                      ),
                      color: AppColors.neutralDark,
                      onPressed: () => Navigator.pop(context),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Lộ trình giao hàng',
                    style: AppTypography.header2.copyWith(
                      fontSize: 20,
                      letterSpacing: -0.60,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Bottom panel placeholder
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                border: Border(top: BorderSide(color: Color(0xFFF2F4F6))),
              ),
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Chọn lộ trình',
                    style: AppTypography.header3.copyWith(
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF0A0A0A),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: _RouteOption(
                          title: 'Tối ưu',
                          subtitle: '— km • — phút',
                          isActive: true,
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: _RouteOption(
                          title: 'Nhanh nhất',
                          subtitle: '— km • — phút',
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [
                            AppColors.headerGradientStart,
                            AppColors.headerGradientEnd,
                          ],
                        ),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: TextButton.icon(
                        onPressed: () {
                          if (!MapboxConfig.isConfigured) {
                            _showMissingTokenHint(context);
                            return;
                          }
                        },
                        icon: const Icon(Icons.play_arrow, color: Colors.white),
                        label: Text(
                          'Bắt đầu giao hàng',
                          style: AppTypography.subHeader.copyWith(
                            color: Colors.white,
                            fontSize: 16,
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
    );
  }

  Widget _buildMapLayer() {
    if (MapboxConfig.isConfigured) {
      return MapWidget(key: const ValueKey('delivery-mapbox-map'));
    }

    return Container(
      color: const Color(0xFFE5E7EB),
      alignment: Alignment.center,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 420),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.cardBorder),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Mapbox chưa được cấu hình',
              style: AppTypography.subHeader.copyWith(
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Thêm token bằng --dart-define=MAPBOX_ACCESS_TOKEN=pk.xxx rồi chạy lại app.',
              style: AppTypography.bodyRegular1.copyWith(
                color: AppColors.textSecondary,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showMissingTokenHint(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Chưa có MAPBOX_ACCESS_TOKEN. Vui lòng cấu hình token để dùng bản đồ.',
        ),
      ),
    );
  }
}

class _RouteOption extends StatelessWidget {
  final String title;
  final String subtitle;
  final bool isActive;

  const _RouteOption({
    required this.title,
    required this.subtitle,
    this.isActive = false,
  });

  @override
  Widget build(BuildContext context) {
    final borderColor = isActive
        ? AppColors.headerGradientEnd
        : const Color(0xFFE5E7EB);
    final bgColor = isActive ? const Color(0xFFFEF2F2) : Colors.white;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor),
      ),
      child: Row(
        children: [
          Icon(
            Icons.alt_route,
            size: 16,
            color: isActive
                ? AppColors.headerGradientEnd
                : const Color(0xFF697282),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTypography.header3.copyWith(
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF0A0A0A),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: AppTypography.bodyRegular1.copyWith(
                    fontSize: 12,
                    color: const Color(0xFF697282),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
