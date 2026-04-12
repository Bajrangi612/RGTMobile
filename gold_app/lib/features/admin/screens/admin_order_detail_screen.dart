import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/formatters.dart';
import '../../../widgets/gold_card.dart';
import '../../../widgets/gold_button.dart';
import '../../../widgets/status_badge.dart';
import '../../order/data/models/order_model.dart';
import '../../auth/data/models/user_model.dart';
import '../../../core/services/invoice_service.dart';
import '../providers/admin_provider.dart';

class AdminOrderDetailScreen extends ConsumerWidget {
  final Map<String, dynamic> order;
  const AdminOrderDetailScreen({super.key, required this.order});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final status = statusFromString(order['status'] ?? 'pending');
    final user = order['user'] != null ? UserModel.fromJson(order['user']) : null;
    final orderModel = OrderModel.fromJson(order);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('ORDER DETAILS', style: AppTextStyles.h4),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        iconTheme: IconThemeData(color: AppColors.royalGold),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            /// 📦 Order Header
            GoldCard(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      color: AppColors.royalGold.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Icon(Icons.shopping_bag_rounded, color: AppColors.royalGold, size: 30),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Order ID #${order['id'].toString().substring(0, 12).toUpperCase()}', 
                          style: AppTextStyles.labelLarge),
                        const SizedBox(height: 4),
                        Text(Formatters.dateTime(order['createdAt'].toString()),
                          style: AppTextStyles.caption.copyWith(color: AppColors.grey)),
                      ],
                    ),
                  ),
                  StatusBadge(status: status),
                ],
              ),
            ).animate().fadeIn().slideX(begin: -0.1),

            const SizedBox(height: 24),

            /// 👤 Customer Profile
            Text('CUSTOMER INFORMATION', style: AppTextStyles.labelMedium.copyWith(color: AppColors.grey)),
            const SizedBox(height: 12),
            GoldCard(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  _InfoRow(icon: Icons.person, label: 'Name', value: user?.name ?? 'Unknown'),
                  const Divider(height: 24),
                  _InfoRow(icon: Icons.phone, label: 'Phone', value: user?.phone ?? 'Unknown'),
                  const Divider(height: 24),
                  _InfoRow(icon: Icons.location_on, label: 'Customer Address', 
                    value: user?.address ?? 'Not provided'),
                  const Divider(height: 24),
                  _InfoRow(icon: Icons.calendar_month_rounded, label: 'Collection Countdown', 
                    value: Formatters.deliveryCountdown(order['deliveryDate'], status: order['status'])),
                ],
              ),
            ).animate(delay: 100.ms).fadeIn().slideX(begin: 0.1),

            const SizedBox(height: 24),

            /// 💰 Payment Details
            Text('PAYMENT SUMMARY', style: AppTextStyles.labelMedium.copyWith(color: AppColors.grey)),
            const SizedBox(height: 12),
            GoldCard(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                   _AmountRow(label: 'Gold Value', amount: (double.tryParse(order['amount']?.toString() ?? '0') ?? 0.0)),
                   _AmountRow(label: 'GST (3%)', amount: (double.tryParse(order['gst']?.toString() ?? '0') ?? 0.0)),
                   const Divider(height: 24),
                   Row(
                     mainAxisAlignment: MainAxisAlignment.spaceBetween,
                     children: [
                       Text('Total Paid', style: AppTextStyles.labelLarge),
                       Text(Formatters.currency(double.tryParse(order['total']?.toString() ?? '0') ?? 0.0),
                        style: AppTextStyles.h4.copyWith(color: AppColors.royalGold)),
                     ],
                   ),
                ],
              ),
            ).animate(delay: 200.ms).fadeIn(),

            const SizedBox(height: 32),

            /// ⏳ Order Timeline
            Text('ORDER TIMELINE (IST)', style: AppTextStyles.labelMedium.copyWith(color: AppColors.grey)),
            const SizedBox(height: 12),
            GoldCard(
              child: orderModel.statusHistory.isEmpty
                  ? Padding(
                      padding: const EdgeInsets.symmetric(vertical: 20),
                      child: Center(
                        child: Text('Logging fulfillment steps...', style: AppTextStyles.bodySmall),
                      ),
                    )
                  : Column(
                      children: orderModel.statusHistory
                          .where((h) => !['PAYMENT_PENDING', 'PAYMENT_SUCCESSFUL'].contains(h.status.toUpperCase()))
                          .toList()
                          ..sort((a, b) => b.createdAt.compareTo(a.createdAt))
                          ..map((history) {
                            final validHistory = orderModel.statusHistory.where((h) => !['PAYMENT_PENDING', 'PAYMENT_SUCCESSFUL'].contains(h.status.toUpperCase())).toList();
                            final isLast = history.createdAt == validHistory.last.createdAt;
                            final statusType = statusFromString(history.status);

                            return _TimelineStep(
                              title: StatusBadge(status: statusType).badgeLabel,
                              subtitle: history.notes ?? 'Status updated successfully.',
                              date: DateFormat('MMM dd').format(history.createdAt),
                              time: DateFormat('hh:mm:ss a').format(history.createdAt),
                              isCompleted: true,
                              isLast: isLast,
                              status: statusType,
                            );
                          }).toList(),
                    ),
            ).animate(delay: 250.ms).fadeIn(),

            const SizedBox(height: 32),

            /// 🚀 Action Center
            Text('FULFILLMENT COMMANDS', style: AppTextStyles.labelMedium.copyWith(color: AppColors.grey)),
            const SizedBox(height: 16),
            
            _FulfillmentActionCenter(order: order, onUpdate: (status) => _updateStatus(context, ref, status)),

            const SizedBox(height: 12),
            
            GoldButton(
              text: 'PREVIEW TAX INVOICE',
              isOutlined: true,
              icon: Icons.receipt_long_rounded,
              onPressed: () => InvoiceService.downloadInvoice(orderModel, user: user),
            ),

            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  void _updateStatus(BuildContext context, WidgetRef ref, String newStatus) {
    ref.read(adminProvider.notifier).updateOrderStatus(order['id'], newStatus);
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Order updated to ${newStatus.toUpperCase()}')),
    );
  }
}

class _FulfillmentActionCenter extends StatelessWidget {
  final Map<String, dynamic> order;
  final Function(String) onUpdate;

  const _FulfillmentActionCenter({required this.order, required this.onUpdate});

  @override
  Widget build(BuildContext context) {
    final status = order['status']?.toString().toUpperCase() ?? 'PENDING';

    return Column(
      children: [
        if (status == 'PAYMENT_PENDING' || status == 'CREATED')
          GoldButton(
            text: 'CONFIRM PAYMENT MANUALLY',
            icon: Icons.payments_rounded,
            onPressed: () => onUpdate('ORDER_CONFIRMED'),
          ),

        if (status == 'ORDER_CONFIRMED')
          GoldButton(
            text: 'START PROCESSING',
            icon: Icons.conveyor_belt, // Note: Use available icon
            onPressed: () => onUpdate('PROCESSING'),
          ),

        if (status == 'PROCESSING')
          GoldButton(
            text: 'SEND TO QUALITY CHECK',
            icon: Icons.fact_check_rounded,
            onPressed: () => onUpdate('QUALITY_CHECKING'),
          ),

        if (status == 'QUALITY_CHECKING')
          GoldButton(
            text: 'READY FOR PICKUP',
            icon: Icons.store_rounded,
            onPressed: () => onUpdate('READY_FOR_PICKUP'),
          ),

        if (status == 'READY_FOR_PICKUP' || status == 'READY')
          GoldButton(
            text: 'MARK AS COLLECTED',
            icon: Icons.check_circle_rounded,
            onPressed: () => onUpdate('PICKED_UP'),
          ),

        if (status == 'REFUND_REQUESTED')
          Row(
            children: [
              Expanded(
                child: GoldButton(
                  text: 'APPROVE REFUND',
                  color: AppColors.success,
                  onPressed: () => onUpdate('REFUNDED'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: GoldButton(
                  text: 'REJECT',
                  isOutlined: true,
                  onPressed: () => onUpdate('ORDER_CONFIRMED'),
                ),
              ),
            ],
          ),
      ],
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  const _InfoRow({required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 18, color: AppColors.royalGold),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: AppTextStyles.caption.copyWith(color: AppColors.grey)),
            const SizedBox(height: 2),
            Text(value, style: AppTextStyles.bodyMedium),
          ],
        ),
      ],
    );
  }
}

class _AmountRow extends StatelessWidget {
  final String label;
  final double amount;
  const _AmountRow({required this.label, required this.amount});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: AppTextStyles.caption.copyWith(color: AppColors.grey)),
          Text(Formatters.currency(amount), style: AppTextStyles.bodyMedium),
        ],
      ),
    );
  }
}

class _TimelineStep extends StatelessWidget {
  final String title;
  final String subtitle;
  final String date;
  final String time;
  final bool isCompleted;
  final bool isLast;
  final StatusType status;

  const _TimelineStep({
    required this.title,
    required this.subtitle,
    required this.date,
    required this.time,
    this.isCompleted = false,
    this.isLast = false,
    required this.status,
  });

  @override
  Widget build(BuildContext context) {
    final statusBadge = StatusBadge(status: status, small: true);
    final color = statusBadge.color;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Left Column: Date & Time
        SizedBox(
          width: 70,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(date, style: AppTextStyles.labelLarge.copyWith(fontSize: 11, color: AppColors.pureWhite)),
              Text(time, style: AppTextStyles.caption.copyWith(fontSize: 9)),
            ],
          ),
        ),
        
        const SizedBox(width: 16),

        // Middle Column: Line and Circle
        Column(
          children: [
            Container(
              width: 14,
              height: 14,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: color,
                boxShadow: [
                  BoxShadow(color: color.withValues(alpha: 0.4), blurRadius: 10),
                ],
              ),
              child: const Icon(Icons.check, size: 8, color: Colors.white),
            ),
            if (!isLast)
              Container(
                width: 2,
                height: 50,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [color, color.withValues(alpha: 0.1)],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
              ),
          ],
        ),
        
        const SizedBox(width: 16),

        // Right Column: Status info
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(bottom: 32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title, 
                  style: AppTextStyles.labelLarge.copyWith(
                    color: AppColors.royalGold, 
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                  )
                ),
                const SizedBox(height: 6),
                Text(
                  subtitle, 
                  style: AppTextStyles.bodySmall.copyWith(
                    fontSize: 11, 
                    color: AppColors.grey,
                    height: 1.4,
                  )
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
