import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../domain/entities/delivery_order.dart';
import '../bloc/delivery_bloc.dart';
import '../bloc/delivery_event.dart';
import '../bloc/delivery_state.dart';

/// Order Details Page - shows individual order details for delivery
class OrderDetailsPage extends StatefulWidget {
  final String orderId;

  const OrderDetailsPage({super.key, required this.orderId});

  @override
  State<OrderDetailsPage> createState() => _OrderDetailsPageState();
}

class _OrderDetailsPageState extends State<OrderDetailsPage> {
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
      appBar: AppBar(
        title: const Text('Chi tiết đơn hàng'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: BlocConsumer<DeliveryBloc, DeliveryState>(
        listener: (context, state) {
          if (state is DeliveryConfirmed) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Đã xác nhận giao hàng thành công'),
                backgroundColor: Colors.green,
              ),
            );
            Navigator.pop(context);
          } else if (state is DeliveryFailureReported) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Đã báo cáo giao hàng thất bại'),
                backgroundColor: Colors.orange,
              ),
            );
            Navigator.pop(context);
          } else if (state is DeliveryError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: Colors.red,
              ),
            );
          }
        },
        builder: (context, state) {
          if (state is DeliveryLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state is OrderDetailsLoaded) {
            return _buildOrderDetails(state.order);
          }

          if (state is DeliveryError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, size: 64, color: Colors.red[300]),
                  const SizedBox(height: 16),
                  Text(state.message),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _loadOrderDetails,
                    child: const Text('Thử lại'),
                  ),
                ],
              ),
            );
          }

          return const SizedBox.shrink();
        },
      ),
    );
  }

  Widget _buildOrderDetails(DeliveryOrder order) {
    final currencyFormat = NumberFormat.currency(locale: 'vi_VN', symbol: '₫');
    final dateFormat = DateFormat('dd/MM/yyyy HH:mm');

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Order Header
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        order.orderCode,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      _buildStatusBadge(order.status),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Ngày đặt: ${dateFormat.format(order.orderDate)}',
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Customer Info
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Thông tin khách hàng',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  const Divider(),
                  _buildInfoRow(Icons.person, 'Tên', order.customerName),
                  _buildInfoRowWithAction(
                    Icons.phone,
                    'SĐT',
                    order.customerPhone,
                    () => _callCustomer(order.customerPhone),
                    Icons.call,
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Delivery Address
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Địa chỉ giao hàng',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: order.isHomeDelivery
                              ? Colors.blue[50]
                              : Colors.green[50],
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          order.isHomeDelivery ? 'Giao tận nơi' : 'Nhận tại điểm',
                          style: TextStyle(
                            fontSize: 12,
                            color: order.isHomeDelivery
                                ? Colors.blue
                                : Colors.green,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const Divider(),
                  if (order.isHomeDelivery) ...[
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            order.deliveryAddress ?? 'Chưa có địa chỉ',
                            style: const TextStyle(fontSize: 15),
                          ),
                        ),
                        IconButton(
                          onPressed: () =>
                              _openMaps(order.deliveryAddress ?? ''),
                          icon: const Icon(Icons.directions, color: Colors.blue),
                          tooltip: 'Mở bản đồ',
                        ),
                      ],
                    ),
                  ] else ...[
                    Text(
                      order.pickupPointName ?? 'Điểm nhận hàng',
                      style: const TextStyle(
                        fontWeight: FontWeight.w500,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            order.pickupPointAddress ?? 'Chưa có địa chỉ',
                            style: TextStyle(color: Colors.grey[600]),
                          ),
                        ),
                        IconButton(
                          onPressed: () =>
                              _openMaps(order.pickupPointAddress ?? ''),
                          icon: const Icon(Icons.directions, color: Colors.blue),
                          tooltip: 'Mở bản đồ',
                        ),
                      ],
                    ),
                  ],
                  if (order.deliveryNote != null &&
                      order.deliveryNote!.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.yellow[50],
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.yellow[700]!),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.note, color: Colors.yellow[800], size: 20),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              order.deliveryNote!,
                              style: const TextStyle(fontStyle: FontStyle.italic),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Order Items
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Sản phẩm (${order.totalItems})',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const Divider(),
                  ...order.items.map((item) => _buildItemRow(item, currencyFormat)),
                  const Divider(),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Tổng tiền hàng:'),
                      Text(currencyFormat.format(order.totalAmount)),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Phí giao hàng:'),
                      Text(currencyFormat.format(order.deliveryFee)),
                    ],
                  ),
                  const Divider(),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Tổng cộng:',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      Text(
                        currencyFormat.format(order.totalValue),
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                          color: Colors.blue,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 24),

          // Action Buttons
          if (order.canConfirm) ...[
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => _showConfirmDialog(order),
                icon: const Icon(Icons.check_circle),
                label: const Text('Xác nhận đã giao'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.all(16),
                ),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => _showFailureDialog(order),
                icon: const Icon(Icons.cancel),
                label: const Text('Báo cáo thất bại'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.red,
                  side: const BorderSide(color: Colors.red),
                  padding: const EdgeInsets.all(16),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStatusBadge(DeliveryOrderStatus status) {
    Color color;
    switch (status) {
      case DeliveryOrderStatus.pending:
      case DeliveryOrderStatus.paidProcessing:
        color = Colors.orange;
      case DeliveryOrderStatus.readyToShip:
        color = Colors.blue;
      case DeliveryOrderStatus.deliveredWaitConfirm:
        color = Colors.purple;
      case DeliveryOrderStatus.completed:
        color = Colors.green;
      case DeliveryOrderStatus.failed:
        color = Colors.red;
      case DeliveryOrderStatus.canceled:
      case DeliveryOrderStatus.refunded:
        color = Colors.grey;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color),
      ),
      child: Text(
        status.displayName,
        style: TextStyle(color: color, fontWeight: FontWeight.w600),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.grey[600]),
          const SizedBox(width: 12),
          Text('$label: ', style: TextStyle(color: Colors.grey[600])),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRowWithAction(
    IconData icon,
    String label,
    String value,
    VoidCallback onAction,
    IconData actionIcon,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.grey[600]),
          const SizedBox(width: 12),
          Text('$label: ', style: TextStyle(color: Colors.grey[600])),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
          IconButton(
            onPressed: onAction,
            icon: Icon(actionIcon, color: Colors.green),
            tooltip: 'Gọi điện',
          ),
        ],
      ),
    );
  }

  Widget _buildItemRow(DeliveryOrderItem item, NumberFormat currencyFormat) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: Text(item.productName),
          ),
          Expanded(
            flex: 1,
            child: Text(
              'x${item.quantity}',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey[600]),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              currencyFormat.format(item.subTotal),
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _callCustomer(String phone) async {
    final uri = Uri.parse('tel:$phone');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  Future<void> _openMaps(String address) async {
    final encodedAddress = Uri.encodeComponent(address);
    final uri = Uri.parse('https://maps.google.com/?q=$encodedAddress');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  void _showConfirmDialog(DeliveryOrder order) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xác nhận giao hàng'),
        content: Text(
          'Xác nhận đã giao thành công đơn hàng "${order.orderCode}" cho khách hàng ${order.customerName}?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              context.read<DeliveryBloc>().add(
                    ConfirmDelivery(orderId: order.orderId),
                  );
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            child: const Text('Xác nhận'),
          ),
        ],
      ),
    );
  }

  void _showFailureDialog(DeliveryOrder order) {
    final reasons = [
      'Khách không nhận hàng',
      'Không liên lạc được khách',
      'Địa chỉ không chính xác',
      'Khách đổi ý / hủy đơn',
      'Hàng hư hỏng',
      'Lý do khác',
    ];

    String? selectedReason;
    final notesController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Báo cáo giao thất bại'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Chọn lý do thất bại:'),
                const SizedBox(height: 8),
                ...reasons.map(
                  (reason) => RadioListTile<String>(
                    value: reason,
                    groupValue: selectedReason,
                    title: Text(reason, style: const TextStyle(fontSize: 14)),
                    onChanged: (value) => setState(() => selectedReason = value),
                    contentPadding: EdgeInsets.zero,
                    dense: true,
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: notesController,
                  decoration: const InputDecoration(
                    labelText: 'Ghi chú thêm (tùy chọn)',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 2,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Hủy'),
            ),
            ElevatedButton(
              onPressed: selectedReason == null
                  ? null
                  : () {
                      Navigator.pop(context);
                      context.read<DeliveryBloc>().add(
                            ReportDeliveryFailure(
                              orderId: order.orderId,
                              failureReason: selectedReason!,
                              notes: notesController.text.isEmpty
                                  ? null
                                  : notesController.text,
                            ),
                          );
                    },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              child: const Text('Báo cáo'),
            ),
          ],
        ),
      ),
    );
  }
}
