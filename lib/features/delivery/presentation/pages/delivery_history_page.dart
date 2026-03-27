import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../domain/entities/delivery_order.dart';
import '../bloc/delivery_bloc.dart';
import '../bloc/delivery_event.dart';
import '../bloc/delivery_state.dart';
import '../widgets/widgets.dart';

/// Delivery History Page - shows completed delivery records
class DeliveryHistoryPage extends StatefulWidget {
  const DeliveryHistoryPage({super.key});

  @override
  State<DeliveryHistoryPage> createState() => _DeliveryHistoryPageState();
}

class _DeliveryHistoryPageState extends State<DeliveryHistoryPage> {
  final ScrollController _scrollController = ScrollController();
  DateTime? _fromDate;
  DateTime? _toDate;
  String? _statusFilter;

  @override
  void initState() {
    super.initState();
    _loadHistory();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  // BUG: Không thấy api cho filter được áp dụng
  void _loadHistory({bool refresh = false}) {
    context.read<DeliveryBloc>().add(
      LoadDeliveryHistory(
        refresh: refresh,
        fromDate: _fromDate,
        toDate: _toDate,
        status: _statusFilter,
      ),
    );
  }

  void _onScroll() {
    if (_isBottom) {
      final state = context.read<DeliveryBloc>().state;
      if (state is DeliveryHistoryLoaded &&
          state.hasNextPage &&
          !state.isLoadingMore) {
        context.read<DeliveryBloc>().add(
          LoadDeliveryHistory(
            page: state.currentPage + 1,
            fromDate: _fromDate,
            toDate: _toDate,
            status: _statusFilter,
          ),
        );
      }
    }
  }

  bool get _isBottom {
    if (!_scrollController.hasClients) return false;
    final maxScroll = _scrollController.position.maxScrollExtent;
    final currentScroll = _scrollController.offset;
    return currentScroll >= (maxScroll * 0.9);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: GradientAppBar(
        title: 'Lịch sử giao hàng',
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            color: AppColors.neutralLight,
            onPressed: _showFilterDialog,
            tooltip: 'Bộ lọc',
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            color: AppColors.neutralLight,
            onPressed: () => _loadHistory(refresh: true),
            tooltip: 'Làm mới',
          ),
        ],
      ),
      body: BlocBuilder<DeliveryBloc, DeliveryState>(
        builder: (context, state) {
          if (state is DeliveryLoading) {
            return const DeliveryLoadingState(message: 'Đang tải lịch sử...');
          }

          if (state is DeliveryHistoryLoaded) {
            if (state.isEmpty) {
              return DeliveryEmptyState(
                icon: Icons.history,
                title: 'Chưa có lịch sử giao hàng',
                subtitle: 'Lịch sử sẽ hiển thị sau khi bạn hoàn thành đơn giao',
                actionLabel: 'Làm mới',
                onAction: () => _loadHistory(refresh: true),
              );
            }
            return _buildHistoryList(state);
          }

          if (state is DeliveryError) {
            return DeliveryErrorState(
              message: state.message,
              onRetry: () => _loadHistory(refresh: true),
            );
          }

          return const SizedBox.shrink();
        },
      ),
    );
  }

  Widget _buildHistoryList(DeliveryHistoryLoaded state) {
    return RefreshIndicator(
      color: AppColors.headerGradientEnd,
      onRefresh: () async {
        _loadHistory(refresh: true);
      },
      child: Column(
        children: [
          // Filter chips
          if (_fromDate != null || _toDate != null || _statusFilter != null)
            _buildActiveFilters(),

          // Summary
          Container(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Tổng cộng: ${state.totalCount} bản ghi',
                  style: AppTypography.header3.copyWith(
                    fontWeight: FontWeight.w500,
                    color: AppColors.textPrimary,
                  ),
                ),
                Text(
                  'Trang ${state.currentPage}/${state.totalPages}',
                  style: AppTypography.bodyRegular1.copyWith(
                    color: AppColors.textSecondary,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),

          // List
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: state.records.length + (state.isLoadingMore ? 1 : 0),
              itemBuilder: (context, index) {
                if (index == state.records.length) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(16),
                      child: CircularProgressIndicator(
                        color: AppColors.primary,
                      ),
                    ),
                  );
                }
                return _buildHistoryCard(state.records[index]);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActiveFilters() {
    final dateFormat = DateFormat('dd/MM/yyyy');
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Wrap(
        spacing: 8,
        children: [
          if (_fromDate != null)
            Chip(
              label: Text('Từ: ${dateFormat.format(_fromDate!)}'),
              onDeleted: () {
                setState(() => _fromDate = null);
                _loadHistory(refresh: true);
              },
            ),
          if (_toDate != null)
            Chip(
              label: Text('Đến: ${dateFormat.format(_toDate!)}'),
              onDeleted: () {
                setState(() => _toDate = null);
                _loadHistory(refresh: true);
              },
            ),
          if (_statusFilter != null)
            Chip(
              label: Text(_getStatusDisplayName(_statusFilter!)),
              onDeleted: () {
                setState(() => _statusFilter = null);
                _loadHistory(refresh: true);
              },
            ),
        ],
      ),
    );
  }

  Widget _buildHistoryCard(DeliveryRecord record) {
    final dateFormat = DateFormat('dd/MM/yyyy HH:mm');

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                record.orderCode,
                style: AppTypography.header2.copyWith(
                  fontFamily: 'DM Sans',
                  fontSize: 16,
                  color: AppColors.textPrimary,
                ),
              ),
              DeliveryRecordStatusBadge(status: record.status),
            ],
          ),
          const Divider(height: 16, color: AppColors.cardBorder),
          if (record.deliveredAt != null)
            DeliveryInfoRowSimple(
              icon: Icons.access_time,
              text: dateFormat.format(record.deliveredAt!),
            ),
          DeliveryInfoRowSimple(
            icon: Icons.person,
            text: record.deliveryStaffName,
          ),
          if (record.failureReason != null && record.failureReason!.isNotEmpty)
            DeliveryNoteCard(
              note: record.failureReason!,
              icon: Icons.warning,
              backgroundColor: AppColors.error.withValues(alpha: 0.1),
              borderColor: AppColors.error.withValues(alpha: 0.3),
              textColor: AppColors.error,
            ),
        ],
      ),
    );
  }

  void _showFilterDialog() {
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text('Bộ lọc', style: AppTypography.header2),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Từ ngày:', style: AppTypography.header3),
                const SizedBox(height: 8),
                OutlinedButton.icon(
                  onPressed: () => _selectFromDate(context, setDialogState),
                  icon: const Icon(Icons.calendar_today),
                  label: Text(
                    _fromDate != null
                        ? DateFormat('dd/MM/yyyy').format(_fromDate!)
                        : 'Chọn ngày',
                  ),
                ),
                const SizedBox(height: 16),
                Text('Đến ngày:', style: AppTypography.header3),
                const SizedBox(height: 8),
                OutlinedButton.icon(
                  onPressed: () => _selectToDate(context, setDialogState),
                  icon: const Icon(Icons.calendar_today),
                  label: Text(
                    _toDate != null
                        ? DateFormat('dd/MM/yyyy').format(_toDate!)
                        : 'Chọn ngày',
                  ),
                ),
                const SizedBox(height: 16),
                Text('Trạng thái:', style: AppTypography.header3),
                const SizedBox(height: 8),
                DropdownButton<String?>(
                  dropdownColor: AppColors.neutralLight,
                  borderRadius: BorderRadius.circular(10),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  value: _statusFilter,
                  isExpanded: true,
                  hint: const Text('Tất cả'),
                  items: const [
                    DropdownMenuItem(value: null, child: Text('Tất cả')),
                    DropdownMenuItem(
                      value: 'Completed',
                      child: Text('Hoàn thành'),
                    ),
                    DropdownMenuItem(
                      value: 'Delivered_Wait_Confirm',
                      child: Text('Chờ xác nhận'),
                    ),
                    DropdownMenuItem(value: 'Failed', child: Text('Thất bại')),
                  ],
                  onChanged: (value) {
                    // Update state in both dialog and the main page
                    setDialogState(() => _statusFilter = value);
                    setState(() => _statusFilter = value);
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                setDialogState(() {
                  _fromDate = null;
                  _toDate = null;
                  _statusFilter = null;
                });
                setState(() {
                  _fromDate = null;
                  _toDate = null;
                  _statusFilter = null;
                });
                Navigator.pop(context);
                _loadHistory(refresh: true);
              },
              child: Text(
                'Xóa bộ lọc',
                style: AppTypography.subHeader.copyWith(
                  color: AppColors.neutralMid,
                ),
              ),
            ),
            AppGradientButton(
              onPressed: () {
                Navigator.pop(context);
                _loadHistory(refresh: true);
              },
              child: SizedBox(
                width: double.infinity,
                height: 50,
                child: Center(
                  child: Text(
                    'Áp dụng',
                    style: AppTypography.subHeader.copyWith(
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _selectFromDate(
    BuildContext dialogContext,
    StateSetter setDialogState,
  ) async {
    final date = await showDatePicker(
      context: dialogContext,
      initialDate: _fromDate ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (date != null) {
      setDialogState(() => _fromDate = date);
      setState(() => _fromDate = date);
    }
  }

  Future<void> _selectToDate(
    BuildContext dialogContext,
    StateSetter setDialogState,
  ) async {
    final date = await showDatePicker(
      context: dialogContext,
      initialDate: _toDate ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (date != null) {
      setDialogState(() => _toDate = date);
      setState(() => _toDate = date);
    }
  }

  String _getStatusDisplayName(String status) {
    switch (status) {
      case 'Completed':
        return 'Hoàn thành';
      case 'Delivered_Wait_Confirm':
        return 'Chờ xác nhận';
      case 'Failed':
        return 'Thất bại';
      default:
        return status;
    }
  }
}
