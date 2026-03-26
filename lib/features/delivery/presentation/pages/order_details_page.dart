import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/constants/app_icons.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../domain/entities/delivery_order.dart';
import '../bloc/delivery_bloc.dart';
import '../bloc/delivery_event.dart';
import '../bloc/delivery_state.dart';
import '../widgets/delivery_failure_sheet.dart';
import '../widgets/qr_scan_modal.dart';
import '../widgets/widgets.dart';

/// Screen 4 — Order Details: individual order for delivery.
class OrderDetailsPage extends StatefulWidget {
  final String orderId;

  const OrderDetailsPage({super.key, required this.orderId});

  @override
  State<OrderDetailsPage> createState() => _OrderDetailsPageState();
}

class _OrderDetailsPageState extends State<OrderDetailsPage> {
  final _imagePicker = ImagePicker();
  String? _selectedProofImagePath;

  @override
  void initState() {
    super.initState();
    _loadOrderDetails();
  }

  void _loadOrderDetails() {
    context.read<DeliveryBloc>().add(LoadOrderDetails(orderId: widget.orderId));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const GradientAppBar(title: 'Chi tiết đơn hàng'),
      body: BlocConsumer<DeliveryBloc, DeliveryState>(
        listener: (context, state) {
          if (state is DeliveryConfirmed) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Đã xác nhận giao hàng thành công'),
                backgroundColor: AppColors.successGradientEnd,
              ),
            );
            Navigator.pop(context);
          } else if (state is DeliveryFailureReported) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Đã báo cáo giao hàng thất bại'),
                backgroundColor: AppColors.headerGradientEnd,
              ),
            );
            Navigator.pop(context);
          } else if (state is DeliveryError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: AppColors.error,
              ),
            );
          } else if (state is DeliveryActionError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: AppColors.error,
              ),
            );
            _loadOrderDetails();
          }
        },
        builder: (context, state) {
          if (state is DeliveryLoading) {
            return const DeliveryLoadingState(message: 'Đang tải chi tiết đơn hàng...');
          }
          if (state is OrderDetailsLoaded) return _buildOrderDetails(state.order);
          if (state is DeliveryError) {
            return DeliveryErrorState(message: state.message, onRetry: _loadOrderDetails);
          }
          return const SizedBox.shrink();
        },
      ),
    );
  }

  Widget _buildOrderDetails(DeliveryOrder order) {
    final currencyFormat =
        NumberFormat.currency(locale: 'vi_VN', symbol: '₫', decimalDigits: 0);
    final dateFormat = DateFormat('dd/MM/yyyy HH:mm');

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Order header card ─────────────────────────────────────────────
          _SectionCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      order.orderCode,
                      style: AppTypography.header2.copyWith(
                        fontFamily: 'DM Sans',
                        fontSize: 20,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    DeliveryOrderStatusBadge(status: order.status),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'Ngày đặt: ${dateFormat.format(order.orderDate)}',
                  style: AppTypography.bodyRegular1.copyWith(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 12),

          // ── Customer info ─────────────────────────────────────────────────
          _SectionCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _SectionTitle('Thông tin khách hàng'),
                const Divider(color: AppColors.cardBorder),
                DeliveryInfoRow(
                  icon: Icons.person_outline,
                  label: 'Tên',
                  value: order.customerName,
                ),
                Row(
                  children: [
                    SvgPicture.asset(
                      AppIcons.phone,
                      width: 20,
                      height: 20,
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'SĐT: ',
                      style: AppTypography.bodyRegular1.copyWith(
                        color: AppColors.neutralMid,
                        fontSize: 13,
                      ),
                    ),
                    Expanded(
                      child: Text(
                        order.customerPhone,
                        style: AppTypography.bodyRegular1.copyWith(
                          fontWeight: FontWeight.w500,
                          fontSize: 13,
                          color: AppColors.neutralDark,
                        ),
                      ),
                    ),
                    GestureDetector(
                      onTap: () => _callCustomer(order.customerPhone),
                      child: Container(
                        width: 40,
                        height: 40,
                        decoration: const BoxDecoration(
                          color: Color(0xFFDCFCE7),
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: SvgPicture.asset(
                            AppIcons.phone,
                            width: 20,
                            height: 20,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 12),

          // ── Delivery address ──────────────────────────────────────────────
          _SectionCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _SectionTitle('Địa chỉ giao hàng'),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: order.isHomeDelivery
                            ? AppColors.accent.withValues(alpha: 0.1)
                            : AppColors.successGradientStart
                                .withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        order.isHomeDelivery ? 'Giao tận nơi' : 'Nhận tại điểm',
                        style: AppTypography.bodyRegular1.copyWith(
                          fontSize: 12,
                          color: order.isHomeDelivery
                              ? AppColors.accent
                              : AppColors.successGradientEnd,
                        ),
                      ),
                    ),
                  ],
                ),
                const Divider(color: AppColors.cardBorder),
                if (order.isHomeDelivery)
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.cardSurface,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      children: [
                        SvgPicture.asset(
                          AppIcons.locationBlue,
                          width: 20,
                          height: 20,
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
                              const SizedBox(height: 4),
                              Text(
                                order.deliveryAddress ?? 'Chưa có địa chỉ',
                                style: AppTypography.header3.copyWith(
                                  color: const Color(0xFF495565),
                                ),
                              ),
                            ],
                          ),
                        ),
                        GestureDetector(
                          onTap: () => _openMaps(order.deliveryAddress ?? ''),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFF2B7FFF),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: Text(
                              'Chỉ đường',
                              style: AppTypography.header3.copyWith(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  )
                else ...[
                  Text(
                    order.pickupPointName ?? 'Điểm nhận hàng',
                    style: AppTypography.header3.copyWith(
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          order.pickupPointAddress ?? 'Chưa có địa chỉ',
                          style: AppTypography.bodyRegular1.copyWith(
                            fontSize: 13,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ),
                      GestureDetector(
                        onTap: () =>
                            _openMaps(order.pickupPointAddress ?? ''),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFF2B7FFF),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Text(
                            'Chỉ đường',
                            style: AppTypography.header3.copyWith(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
                if (order.deliveryNote != null &&
                    order.deliveryNote!.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  DeliveryNoteCard(note: order.deliveryNote!),
                ],
              ],
            ),
          ),

          const SizedBox(height: 12),

          // ── Meta chips ────────────────────────────────────────────────
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.cardSurface,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    children: [
                      SvgPicture.asset(
                        AppIcons.clock,
                        width: 20,
                        height: 20,
                      ),
                      const SizedBox(width: 8),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
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
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.cardSurface,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    children: [
                      SvgPicture.asset(
                        AppIcons.package,
                        width: 20,
                        height: 20,
                      ),
                      const SizedBox(width: 8),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
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

          const SizedBox(height: 12),

          // ── Order items ───────────────────────────────────────────────────
          _SectionCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _SectionTitle('Sản phẩm (${order.totalItems})'),
                const Divider(color: AppColors.cardBorder),
                ...order.items
                    .map((item) => _buildItemRow(item, currencyFormat)),
                const Divider(color: AppColors.cardBorder),

                // Subtotals
                _PriceRow(
                  label: 'Tổng tiền hàng:',
                  value: currencyFormat.format(order.totalAmount),
                  labelColor: AppColors.textSecondary,
                  valueColor: AppColors.textPrimary,
                ),
                const SizedBox(height: 4),
                _PriceRow(
                  label: 'Phí giao hàng:',
                  value: currencyFormat.format(order.deliveryFee),
                  labelColor: AppColors.textSecondary,
                  valueColor: AppColors.textPrimary,
                ),
                const Divider(color: AppColors.cardBorder),

                // Grand total — highlighted per spec
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFFFFF7EC), Color(0xFFFEF2F2)],
                    ),
                    borderRadius: BorderRadius.circular(16),
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
                        currencyFormat.format(order.totalValue),
                        style: const TextStyle(
                          fontFamily: 'DM Sans',
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: AppColors.headerGradientEnd,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // ── Action buttons ────────────────────────────────────────────────
          if (order.canConfirm) ...[
            // QR confirm — success gradient per spec
            _SuccessGradientButton(
              onPressed: () => _openQrScan(order),
              icon: Icons.qr_code_scanner,
              label: 'Quét mã QR xác nhận',
            ),
            const SizedBox(height: 12),

            // Failure report — outlined, error color per spec
            SizedBox(
              width: double.infinity,
              height: 50,
              child: OutlinedButton.icon(
                onPressed: () => _openFailureSheet(order),
                icon: const Icon(Icons.cancel_outlined),
                label: const Text('Giao hàng thất bại'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.headerGradientEnd,
                  side: const BorderSide(color: AppColors.headerGradientEnd),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  textStyle: AppTypography.header3.copyWith(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),

            // Manual confirm — outlined, accent color
            SizedBox(
              width: double.infinity,
              height: 50,
              child: OutlinedButton.icon(
                onPressed: () => _showConfirmDialog(order),
                icon: const Icon(Icons.check_circle_outline),
                label: const Text('Xác nhận đã giao (không QR)'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.accent,
                  side: const BorderSide(color: AppColors.accent),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  textStyle: AppTypography.header3.copyWith(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildItemRow(DeliveryOrderItem item, NumberFormat fmt) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
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
              children: [
                Text(
                  item.productName,
                  style: AppTypography.header3.copyWith(
                    fontFamily: 'DM Sans',
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                Text(
                  'Số lượng: ${item.quantity}',
                  style: AppTypography.bodyRegular1.copyWith(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          Text(
            fmt.format(item.subTotal),
            style: const TextStyle(
              fontFamily: 'DM Sans',
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: AppColors.headerGradientEnd,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _callCustomer(String phone) async {
    final uri = Uri.parse('tel:$phone');
    if (await canLaunchUrl(uri)) await launchUrl(uri);
  }

  Future<void> _openMaps(String address) async {
    final uri = Uri.parse(
      'https://maps.google.com/?q=${Uri.encodeComponent(address)}',
    );
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  void _showConfirmDialog(DeliveryOrder order) {
    String? localSelectedPath = _selectedProofImagePath;
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text('Xác nhận giao hàng', style: AppTypography.header2),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Xác nhận đã giao thành công đơn "${order.orderCode}" cho ${order.customerName}?',
                  style: AppTypography.header3,
                ),
                const SizedBox(height: 16),
                Text(
                  'Ảnh bằng chứng (tùy chọn)',
                  style: AppTypography.header3.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        localSelectedPath == null
                            ? 'Chưa chọn ảnh'
                            : File(localSelectedPath!).path.split('/').last,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTypography.bodyRegular1.copyWith(
                          fontSize: 13,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    OutlinedButton.icon(
                      onPressed: () async {
                        final picked = await _imagePicker.pickImage(
                          source: ImageSource.gallery,
                          imageQuality: 85,
                        );
                        if (picked != null) {
                          setDialogState(
                            () => localSelectedPath = picked.path,
                          );
                        }
                      },
                      icon: const Icon(Icons.photo_library),
                      label: const Text('Chọn'),
                    ),
                    if (localSelectedPath != null) ...[
                      const SizedBox(width: 8),
                      IconButton(
                        tooltip: 'Bỏ chọn',
                        onPressed: () =>
                            setDialogState(() => localSelectedPath = null),
                        icon: const Icon(Icons.close),
                        color: AppColors.error,
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                'Hủy',
                style: AppTypography.subHeader.copyWith(
                  color: AppColors.neutralMid,
                ),
              ),
            ),
            DecoratedBox(
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [
                    AppColors.successGradientStart,
                    AppColors.successGradientEnd,
                  ],
                ),
                borderRadius: BorderRadius.circular(8),
              ),
              child: TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  _selectedProofImagePath = localSelectedPath;
                  context.read<DeliveryBloc>().add(
                    ConfirmDelivery(
                      orderId: order.orderId,
                      proofImagePath: localSelectedPath,
                    ),
                  );
                },
                child: Text(
                  'Xác nhận',
                  style: AppTypography.subHeader.copyWith(
                    color: Colors.white,
                    fontSize: 14,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _openQrScan(DeliveryOrder order) async {
    final qrCode = await showQrScanModal(context);
    if (!mounted || qrCode == null || qrCode.trim().isEmpty) return;
    context.read<DeliveryBloc>().add(
      ConfirmDelivery(orderId: order.orderId, notes: 'QR:$qrCode'),
    );
  }

  Future<void> _openFailureSheet(DeliveryOrder order) async {
    const reasons = [
      'Khách không nghe máy',
      'Khách hủy đơn',
      'Không tìm thấy địa chỉ',
      'Khách không có nhà',
      'Lý do khác',
    ];
    final result = await showDeliveryFailureSheet(context, reasons: reasons);
    if (!mounted || result == null) return;
    context.read<DeliveryBloc>().add(
      ReportDeliveryFailure(
        orderId: order.orderId,
        failureReason: result.reason,
        notes: result.notes,
      ),
    );
  }
}

// ── Private helpers ──────────────────────────────────────────────────────────

class _SectionCard extends StatelessWidget {
  final Widget child;
  const _SectionCard({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: AppColors.cardBorder),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: child,
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String text;
  const _SectionTitle(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: AppTypography.header2.copyWith(
        fontFamily: 'DM Sans',
        fontSize: 16,
        color: AppColors.textPrimary,
      ),
    );
  }
}

class _PriceRow extends StatelessWidget {
  final String label;
  final String value;
  final Color labelColor;
  final Color valueColor;

  const _PriceRow({
    required this.label,
    required this.value,
    required this.labelColor,
    required this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: AppTypography.header3.copyWith(color: labelColor),
        ),
        Text(
          value,
          style: AppTypography.header3.copyWith(color: valueColor),
        ),
      ],
    );
  }
}

class _SuccessGradientButton extends StatelessWidget {
  final VoidCallback onPressed;
  final IconData icon;
  final String label;

  const _SuccessGradientButton({
    required this.onPressed,
    required this.icon,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [AppColors.successGradientStart, AppColors.successGradientEnd],
          ),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(16),
          child: InkWell(
            onTap: onPressed,
            borderRadius: BorderRadius.circular(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, color: Colors.white, size: 20),
                const SizedBox(width: 8),
                Text(
                  label,
                  style: AppTypography.header3.copyWith(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
