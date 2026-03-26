import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../../core/constants/app_icons.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../widgets/qr_scan_modal.dart';

/// DeliveryStaff component matching the exact design provided
class DeliveryStaffPage extends StatelessWidget {
  const DeliveryStaffPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          Container(
            width: 389,
            height: 917,
            decoration: const BoxDecoration(color: Colors.white),
            child: Stack(
              children: [
                Positioned(
                  left: 0,
                  top: 0,
                  child: Container(
                    width: 389,
                    height: 915,
                    decoration: const BoxDecoration(color: Colors.white),
                    child: Stack(
                      children: [
                        // Header gradient section
                        Positioned(
                          left: 0,
                          top: 0,
                          child: Container(
                            width: 389.26,
                            height: 215.91,
                            padding: const EdgeInsets.only(
                              top: 47.99,
                              left: 24,
                              right: 24,
                            ),
                            decoration: const BoxDecoration(
                              gradient: LinearGradient(
                                colors: [AppColors.headerGradientStart, AppColors.headerGradientEnd],
                              ),
                            ),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Header row with back button
                                Row(
                                  children: [
                                    Container(
                                      width: 39.99,
                                      height: 39.99,
                                      decoration: BoxDecoration(
                                        color: Colors.white.withValues(alpha: 0.20),
                                        borderRadius: BorderRadius.circular(999),
                                      ),
                                      child: Center(
                                        child: SvgPicture.asset(
                                          AppIcons.backArrow,
                                          width: 24,
                                          height: 24,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 15.99),
                                    Text(
                                      'Chi tiết đơn hàng',
                                      style: AppTypography.header1.copyWith(
                                        fontSize: 20,
                                        color: Colors.white,
                                        letterSpacing: -0.60,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 15.99),
                                
                                // Order code card
                                Container(
                                  width: double.infinity,
                                  height: 87.94,
                                  padding: const EdgeInsets.only(
                                    top: 15.99,
                                    left: 15.99,
                                    right: 15.99,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.20),
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Opacity(
                                        opacity: 0.90,
                                        child: Text(
                                          'Mã đơn hàng',
                                          style: AppTypography.header3.copyWith(
                                            color: Colors.white,
                                            fontSize: 14,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(height: 3.99),
                                      Text(
                                        'ORD001',
                                        style: AppTypography.header1.copyWith(
                                          fontSize: 24,
                                          color: Colors.white,
                                          letterSpacing: -0.72,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),

                        // Customer info section
                        Positioned(
                          left: 0,
                          top: 215.91,
                          child: Container(
                            width: 389.26,
                            height: 281.02,
                            padding: const EdgeInsets.only(
                              top: 15.99,
                              left: 24,
                              right: 24,
                              bottom: 1.18,
                            ),
                            decoration: const BoxDecoration(
                              border: Border(
                                bottom: BorderSide(
                                  width: 1.18,
                                  color: AppColors.cardBorder,
                                ),
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Thông tin khách hàng',
                                  style: AppTypography.header3.copyWith(
                                    fontFamily: 'DM Sans',
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.textPrimary,
                                    letterSpacing: -0.42,
                                  ),
                                ),
                                const SizedBox(height: 12),

                                // Customer avatar and info
                                Row(
                                  children: [
                                    Container(
                                      width: 39.99,
                                      height: 39.99,
                                      decoration: const BoxDecoration(
                                        color: Color(0xFFF3F4F6),
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Center(
                                        child: Text(
                                          'N',
                                          style: TextStyle(
                                            color: Color(0xFF495565),
                                            fontSize: 16,
                                            fontFamily: 'Be Vietnam Pro',
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'Nguyễn Văn A',
                                            style: AppTypography.header2.copyWith(
                                              fontFamily: 'DM Sans',
                                              fontSize: 16,
                                              color: AppColors.textPrimary,
                                            ),
                                          ),
                                          Text(
                                            '0901234567',
                                            style: AppTypography.header3.copyWith(
                                              color: AppColors.textSecondary,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Container(
                                      width: 39.99,
                                      height: 39.99,
                                      decoration: const BoxDecoration(
                                        color: Color(0xFFDCFCE7),
                                        shape: BoxShape.circle,
                                      ),
                                      child: Center(
                                        child: SvgPicture.asset(
                                          AppIcons.phone,
                                          width: 19.98,
                                          height: 19.98,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),

                                // Address section
                                Container(
                                  width: double.infinity,
                                  height: 87.94,
                                  padding: const EdgeInsets.only(
                                    top: 12,
                                    left: 12,
                                    right: 12,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppColors.cardSurface,
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  child: Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      SvgPicture.asset(
                                        AppIcons.locationBlue,
                                        width: 19.98,
                                        height: 19.98,
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              'Địa chỉ giao hàng',
                                              style: AppTypography.header3.copyWith(
                                                fontWeight: FontWeight.w700,
                                                color: AppColors.textPrimary,
                                              ),
                                            ),
                                            const SizedBox(height: 3.99),
                                            Text(
                                              'Số 10 đối diện cầu Lekki phase 1, Khu đô thị Sangotedo',
                                              style: AppTypography.header3.copyWith(
                                                color: const Color(0xFF495565),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 12),

                                // Meta chips
                                Row(
                                  children: [
                                    Expanded(
                                      child: Container(
                                        height: 59.97,
                                        padding: const EdgeInsets.only(left: 12),
                                        decoration: BoxDecoration(
                                          color: AppColors.cardSurface,
                                          borderRadius: BorderRadius.circular(16),
                                        ),
                                        child: Row(
                                          children: [
                                            SvgPicture.asset(
                                              AppIcons.clock,
                                              width: 19.98,
                                              height: 19.98,
                                            ),
                                            const SizedBox(width: 7.99),
                                            Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              mainAxisAlignment: MainAxisAlignment.center,
                                              children: [
                                                Text(
                                                  'Khung giờ',
                                                  style: AppTypography.bodyRegular1.copyWith(
                                                    fontSize: 12,
                                                    color: AppColors.textSecondary,
                                                  ),
                                                ),
                                                const SizedBox(height: 2),
                                                Text(
                                                  '19:00 - 20:30',
                                                  style: AppTypography.header3.copyWith(
                                                    fontWeight: FontWeight.w700,
                                                    color: AppColors.textPrimary,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Container(
                                        height: 59.97,
                                        padding: const EdgeInsets.only(left: 12),
                                        decoration: BoxDecoration(
                                          color: AppColors.cardSurface,
                                          borderRadius: BorderRadius.circular(16),
                                        ),
                                        child: Row(
                                          children: [
                                            SvgPicture.asset(
                                              AppIcons.package,
                                              width: 19.98,
                                              height: 19.98,
                                            ),
                                            const SizedBox(width: 7.99),
                                            Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              mainAxisAlignment: MainAxisAlignment.center,
                                              children: [
                                                Text(
                                                  'Điểm lấy',
                                                  style: AppTypography.bodyRegular1.copyWith(
                                                    fontSize: 12,
                                                    color: AppColors.textSecondary,
                                                  ),
                                                ),
                                                const SizedBox(height: 2),
                                                Text(
                                                  'Điểm A - Quận 1',
                                                  style: AppTypography.header3.copyWith(
                                                    fontWeight: FontWeight.w700,
                                                    color: AppColors.textPrimary,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),

                        // Products section
                        Positioned(
                          left: 0,
                          top: 496.93,
                          child: Container(
                            width: 389.26,
                            height: 301.82,
                            padding: const EdgeInsets.only(
                              top: 15.99,
                              left: 24,
                              right: 24,
                              bottom: 1.18,
                            ),
                            decoration: const BoxDecoration(
                              border: Border(
                                bottom: BorderSide(
                                  width: 1.18,
                                  color: AppColors.cardBorder,
                                ),
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Danh sách sản phẩm',
                                  style: AppTypography.header3.copyWith(
                                    fontFamily: 'DM Sans',
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.textPrimary,
                                    letterSpacing: -0.42,
                                  ),
                                ),
                                const SizedBox(height: 12),

                                // Product items
                                Column(
                                  children: [
                                    _buildProductItem('Bánh mì gà', 'Số lượng: 2', '50.000đ'),
                                    const SizedBox(height: 12),
                                    _buildProductItem('Nước ngọt', 'Số lượng: 1', '15.000đ'),
                                  ],
                                ),
                                const SizedBox(height: 12),

                                // Total section
                                Container(
                                  width: double.infinity,
                                  height: 59.97,
                                  padding: const EdgeInsets.only(
                                    top: 15.99,
                                    left: 15.99,
                                    right: 15.99,
                                  ),
                                  decoration: const BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [Color(0xFFFFF7EC), Color(0xFFFEF2F2)],
                                    ),
                                    borderRadius: BorderRadius.all(Radius.circular(16)),
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        'Tổng cộng',
                                        style: AppTypography.header2.copyWith(
                                          fontFamily: 'DM Sans',
                                          fontSize: 16,
                                          color: AppColors.textPrimary,
                                        ),
                                      ),
                                      Text(
                                        '115.000đ',
                                        style: const TextStyle(
                                          color: AppColors.headerGradientEnd,
                                          fontSize: 20,
                                          fontFamily: 'DM Sans',
                                          fontWeight: FontWeight.w700,
                                        ),
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

                // QR Modal overlay
                Positioned(
                  left: 0,
                  top: 0,
                  child: GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      width: 389.26,
                      height: 916.96,
                      color: Colors.black.withValues(alpha: 0.90),
                      child: const Center(
                        child: SizedBox(
                          width: 341.27,
                          height: 778.99,
                          // QR Modal will be handled by showQrScanModal
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => showQrScanModal(context),
        backgroundColor: AppColors.primary,
        child: SvgPicture.asset(
          AppIcons.qrScanner,
          width: 24,
          height: 24,
        ),
      ),
    );
  }

  Widget _buildProductItem(String name, String quantity, String price) {
    return Container(
      width: double.infinity,
      height: 74.35,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: AppColors.cardBorder, width: 1.18),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Container(
            width: 47.99,
            height: 47.99,
            decoration: BoxDecoration(
              color: const Color(0xFFFFEDD4),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(
              Icons.fastfood_outlined,
              size: 24,
              color: Color(0xFFF44900),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  name,
                  style: AppTypography.header3.copyWith(
                    fontFamily: 'DM Sans',
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                Text(
                  quantity,
                  style: AppTypography.bodyRegular1.copyWith(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          Text(
            price,
            style: const TextStyle(
              color: AppColors.headerGradientEnd,
              fontSize: 14,
              fontFamily: 'DM Sans',
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}