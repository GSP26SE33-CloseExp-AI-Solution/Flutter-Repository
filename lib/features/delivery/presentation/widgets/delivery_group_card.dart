import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../domain/entities/delivery_group.dart';

/// Reusable Delivery Group Card Widget
class DeliveryGroupCard extends StatelessWidget {
  final DeliveryGroupSummary group;
  final VoidCallback? onTap;
  final VoidCallback? onAccept;
  final VoidCallback? onStart;
  final VoidCallback? onComplete;
  final bool showAcceptButton;

  const DeliveryGroupCard({
    super.key,
    required this.group,
    this.onTap,
    this.onAccept,
    this.onStart,
    this.onComplete,
    this.showAcceptButton = true,
  });

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('dd/MM');

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      group.groupCode,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                  _buildStatusBadge(group.status),
                ],
              ),

              const Divider(height: 16),

              // Info Rows
              _buildInfoRow(
                Icons.calendar_today,
                dateFormat.format(group.deliveryDate),
              ),
              _buildInfoRow(Icons.access_time, group.timeSlotDisplay),
              _buildInfoRow(Icons.location_on, group.deliveryArea),
              _buildInfoRow(Icons.local_shipping, group.deliveryType),

              const Divider(height: 16),

              // Stats Row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildStatItem('Tổng', group.totalOrders, Colors.blue),
                  _buildStatItem('Xong', group.completedOrders, Colors.green),
                  _buildStatItem('Còn', group.pendingOrders, Colors.orange),
                ],
              ),

              // Progress Bar
              const SizedBox(height: 12),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: group.totalOrders > 0
                      ? group.completedOrders / group.totalOrders
                      : 0,
                  backgroundColor: Colors.grey[200],
                  valueColor: AlwaysStoppedAnimation<Color>(
                    group.completedOrders == group.totalOrders
                        ? Colors.green
                        : Colors.blue,
                  ),
                  minHeight: 6,
                ),
              ),

              // Action Buttons
              if (showAcceptButton && group.isAvailable && onAccept != null) ...[
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: onAccept,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('Nhận đơn'),
                  ),
                ),
              ],

              if (group.isAssigned && onStart != null) ...[
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: onStart,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('Bắt đầu giao'),
                  ),
                ),
              ],

              if (group.isInProgress &&
                  group.pendingOrders == 0 &&
                  onComplete != null) ...[
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: onComplete,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('Hoàn thành'),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusBadge(DeliveryGroupStatus status) {
    Color color;
    switch (status) {
      case DeliveryGroupStatus.pending:
        color = Colors.blue;
      case DeliveryGroupStatus.assigned:
        color = Colors.orange;
      case DeliveryGroupStatus.inTransit:
        color = Colors.purple;
      case DeliveryGroupStatus.completed:
        color = Colors.green;
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

  Widget _buildStatItem(String label, int value, Color color) {
    return Column(
      children: [
        Text(
          value.toString(),
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: TextStyle(fontSize: 12, color: Colors.grey[600]),
        ),
      ],
    );
  }
}
