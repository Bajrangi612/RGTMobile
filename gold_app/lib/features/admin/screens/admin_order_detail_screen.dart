import 'package:flutter/material.dart';
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
                    value: Formatters.deliveryCountdown(order['deliveryDate'])),
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
