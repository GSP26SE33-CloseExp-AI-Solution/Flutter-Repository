import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../../domain/entities/delivery_order.dart';
import '../bloc/delivery_bloc.dart';
import '../bloc/delivery_event.dart';
import '../bloc/delivery_state.dart';

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

  void _loadHistory({bool refresh = false}) {
    context.read<DeliveryBloc>().add(LoadDeliveryHistory(
          refresh: refresh,
          fromDate: _fromDate,
          toDate: _toDate,
          status: _statusFilter,
        ));
  }

  void _onScroll() {
    if (_isBottom) {
      final state = context.read<DeliveryBloc>().state;
      if (state is DeliveryHistoryLoaded &&
          state.hasNextPage &&
          !state.isLoadingMore) {
        context.read<DeliveryBloc>().add(LoadDeliveryHistory(
              page: state.currentPage + 1,
              fromDate: _fromDate,
              toDate: _toDate,
              status: _statusFilter,
            ));
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
      appBar: AppBar(
        title: const Text('Lịch sử giao hàng'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: _showFilterDialog,
            tooltip: 'Bộ lọc',
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => _loadHistory(refresh: true),
            tooltip: 'Làm mới',
          ),
        ],
      ),
      body: BlocBuilder<DeliveryBloc, DeliveryState>(
        builder: (context, state) {
          if (state is DeliveryLoading) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Đang tải lịch sử...'),
                ],
              ),
            );
          }

          if (state is DeliveryHistoryLoaded) {
            if (state.isEmpty) {
              return _buildEmptyState();
            }
            return _buildHistoryList(state);
          }

          if (state is DeliveryError) {
            return _buildErrorState(state.message);
          }

          return const SizedBox.shrink();
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.history, size: 80, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            'Chưa có lịch sử giao hàng',
            style: TextStyle(fontSize: 18, color: Colors.grey[600]),
          ),
          const SizedBox(height: 8),
          Text(
            'Lịch sử sẽ hiển thị sau khi bạn hoàn thành đơn giao',
            style: TextStyle(color: Colors.grey[500]),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () => _loadHistory(refresh: true),
            icon: const Icon(Icons.refresh),
            label: const Text('Làm mới'),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 80, color: Colors.red[300]),
          const SizedBox(height: 16),
          Text(
            message,
            style: TextStyle(fontSize: 16, color: Colors.grey[600]),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () => _loadHistory(refresh: true),
            icon: const Icon(Icons.refresh),
            label: const Text('Thử lại'),
          ),
        ],
      ),
    );
  }

  Widget _buildHistoryList(DeliveryHistoryLoaded state) {
    return RefreshIndicator(
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
                  style: const TextStyle(fontWeight: FontWeight.w500),
                ),
                Text(
                  'Trang ${state.currentPage}/${state.totalPages}',
                  style: TextStyle(color: Colors.grey[600]),
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
                      child: CircularProgressIndicator(),
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

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  record.orderCode,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                _buildStatusBadge(record.status),
              ],
            ),
            const Divider(height: 16),
            if (record.deliveredAt != null)
              _buildInfoRow(
                Icons.access_time,
                dateFormat.format(record.deliveredAt!),
              ),
            _buildInfoRow(Icons.person, record.deliveryStaffName),
            if (record.failureReason != null && record.failureReason!.isNotEmpty)
              Container(
                margin: const EdgeInsets.only(top: 8),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red[200]!),
                ),
                child: Row(
                  children: [
                    Icon(Icons.warning, color: Colors.red[700], size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        record.failureReason!,
                        style: TextStyle(color: Colors.red[700]),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 16, color: Colors.grey[600]),
          const SizedBox(width: 8),
          Text(text, style: TextStyle(color: Colors.grey[700])),
        ],
      ),
    );
  }

  Widget _buildStatusBadge(DeliveryOrderStatus status) {
    Color color;
    switch (status) {
      case DeliveryOrderStatus.completed:
        color = Colors.green;
      case DeliveryOrderStatus.failed:
        color = Colors.red;
      case DeliveryOrderStatus.deliveredWaitConfirm:
        color = Colors.purple;
      default:
        color = Colors.grey;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color),
      ),
      child: Text(
        status.displayName,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  void _showFilterDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Bộ lọc'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Từ ngày:'),
              const SizedBox(height: 8),
              OutlinedButton.icon(
                onPressed: () => _selectFromDate(context),
                icon: const Icon(Icons.calendar_today),
                label: Text(_fromDate != null
                    ? DateFormat('dd/MM/yyyy').format(_fromDate!)
                    : 'Chọn ngày'),
              ),
              const SizedBox(height: 16),
              const Text('Đến ngày:'),
              const SizedBox(height: 8),
              OutlinedButton.icon(
                onPressed: () => _selectToDate(context),
                icon: const Icon(Icons.calendar_today),
                label: Text(_toDate != null
                    ? DateFormat('dd/MM/yyyy').format(_toDate!)
                    : 'Chọn ngày'),
              ),
              const SizedBox(height: 16),
              const Text('Trạng thái:'),
              const SizedBox(height: 8),
              DropdownButton<String?>(
                value: _statusFilter,
                isExpanded: true,
                hint: const Text('Tất cả'),
                items: const [
                  DropdownMenuItem(value: null, child: Text('Tất cả')),
                  DropdownMenuItem(value: 'Completed', child: Text('Hoàn thành')),
                  DropdownMenuItem(
                      value: 'Delivered_Wait_Confirm', child: Text('Chờ xác nhận')),
                  DropdownMenuItem(value: 'Failed', child: Text('Thất bại')),
                ],
                onChanged: (value) {
                  setState(() => _statusFilter = value);
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              setState(() {
                _fromDate = null;
                _toDate = null;
                _statusFilter = null;
              });
              Navigator.pop(context);
              _loadHistory(refresh: true);
            },
            child: const Text('Xóa bộ lọc'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _loadHistory(refresh: true);
            },
            child: const Text('Áp dụng'),
          ),
        ],
      ),
    );
  }

  Future<void> _selectFromDate(BuildContext dialogContext) async {
    final date = await showDatePicker(
      context: dialogContext,
      initialDate: _fromDate ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (date != null) {
      setState(() => _fromDate = date);
    }
  }

  Future<void> _selectToDate(BuildContext dialogContext) async {
    final date = await showDatePicker(
      context: dialogContext,
      initialDate: _toDate ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (date != null) {
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
