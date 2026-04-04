import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/utils/extensions.dart';
import '../../../widgets/gold_button.dart';
import '../../../widgets/gold_card.dart';
import '../../../widgets/gold_app_bar.dart';
import '../../../widgets/status_badge.dart';
import '../data/models/order_model.dart';
import '../providers/order_provider.dart';
import 'resell_screen.dart';
import '../../../core/services/invoice_service.dart';

class OrderDetailScreen extends ConsumerWidget {
  final OrderModel order;

  OrderDetailScreen({super.key, required this.order});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: AppColors.deepBlack,
      appBar: GoldAppBar(title: 'Order Details'),
      body: Container(
        decoration: BoxDecoration(gradient: AppColors.darkGradient),
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Order Header
                    GoldCard(
                      hasGoldBorder: true,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                width: 56,
                                height: 56,
                                decoration: BoxDecoration(
                                  color: AppColors.royalGold.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                child: Icon(
                                  Icons.monetization_on_rounded,
                                  color: AppColors.royalGold,
                                  size: 32,
                                ),
                              ),
                              SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(order.productName, style: AppTextStyles.h4),
                                    SizedBox(height: 4),
                                    Text('Order #${order.id}', style: AppTextStyles.caption),
                                  ],
                                ),
                              ),
                              StatusBadge(status: order.statusType),
                            ],
                          ),
                          SizedBox(height: 20),
                          _DetailRow('Weight', '${order.weight.toInt()} gram'),
                          _DetailRow('Price', Formatters.currency(order.price)),
                          _DetailRow('GST (3%)', Formatters.currency(order.gstAmount)),
                          _DetailRow('Total Price', Formatters.currency(order.totalPrice), isBold: true),
                          _DetailRow('Payment', order.paymentMethod),
                          _DetailRow('Order Date', Formatters.date(order.orderDate)),
                          if (order.referralCode != null && order.referralCode!.isNotEmpty)
                            _DetailRow('Referral', order.referralCode!),
                        ],
                      ),
                    ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.05),

                    SizedBox(height: 16),

                    // Delivery Countdown
                    if (order.isActive)
                      GoldCard(
                        hasGlow: true,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(Icons.local_shipping_rounded, color: AppColors.royalGold, size: 22),
                                SizedBox(width: 10),
                                Text('Delivery Estimate', style: AppTextStyles.labelLarge),
                              ],
                            ),
                            SizedBox(height: 16),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                _CountdownBox(
                                  value: Formatters.deliveryCountdown(order.estimatedDelivery),
                                  label: 'Remaining',
                                ),
                              ],
                            ),
                            SizedBox(height: 12),
                            Center(
                              child: Text(
                                'Expected by ${Formatters.date(order.estimatedDelivery)}',
                                style: AppTextStyles.bodySmall,
                              ),
                            ),
                          ],
                        ),
                      ).animate(delay: 200.ms).fadeIn(duration: 400.ms),

                    SizedBox(height: 16),

                    // Progress Stepper
                    GoldCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Order Progress', style: AppTextStyles.labelLarge),
                          SizedBox(height: 16),
                          _ProgressStep(
                            title: 'Confirmed',
                            subtitle: Formatters.date(order.orderDate),
                            isCompleted: true,
                            isFirst: true,
                          ),
                          _ProgressStep(
                            title: 'Processing',
                            subtitle: 'In progress',
                            isCompleted: order.status.toUpperCase() != 'CONFIRMED',
                          ),
                          _ProgressStep(
                            title: 'Shipped',
                            subtitle: order.status.toUpperCase() == 'SHIPPED' || order.isDelivered
                                ? 'On the way'
                                : 'Pending',
                            isCompleted: order.status.toUpperCase() == 'SHIPPED' || order.isDelivered,
                          ),
                          _ProgressStep(
                            title: 'Delivered',
                            subtitle: order.isDelivered
                                ? Formatters.date(order.deliveredDate!) : 'Estimated ${Formatters.date(order.estimatedDelivery)}',
                            isCompleted: order.isDelivered,
                            isLast: true,
                          ),
                        ],
                      ),
                    ).animate(delay: 300.ms).fadeIn(duration: 400.ms),
                  ],
                ),
              ),
            ),

            // Action Buttons
            if (order.canCancel || order.canResell)
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: AppColors.charcoal.withOpacity(0.95),
                  border: Border(top: BorderSide(color: AppColors.glassBorder)),
                ),
                child: SafeArea(
                  child: Row(
                    children: [
                      if (order.canCancel)
                        Expanded(
                          child: GoldButton(
                            text: 'Cancel',
                            isOutlined: true,
                            onPressed: () async {
                              final confirm = await showDialog<bool>(
                                context: context,
                                builder: (ctx) => AlertDialog(
                                  title: Text('Cancel Order?'),
                                  content: Text('This action cannot be undone. You will receive a full refund.'),
                                  actions: [
                                    TextButton(
                                      onPressed: () => Navigator.pop(ctx, false),
                                      child: Text('No'),
                                    ),
                                    ElevatedButton(
                                      onPressed: () => Navigator.pop(ctx, true),
                                      child: Text('Yes, Cancel'),
                                    ),
                                  ],
                                ),
                              ) ;
                              if (confirm == true) {
                                await ref.read(orderProvider.notifier).cancelOrder(order.id);
                                if (context.mounted) {
                                  context.showSuccessSnackBar('Order cancelled. Refund initiated.');
                                  Navigator.of(context).pop();
                                }
                              }
                            },
                            icon: Icons.cancel_outlined,
                          ),
                        ),
                      if (order.canCancel && order.canResell) SizedBox(width: 12),
                      if (order.canResell)
                        Expanded(
                          child: GoldButton(
                            text: 'Resell',
                            onPressed: () => Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) =>  ResellScreen(order: order),
                              ),
                            ),
                            icon: Icons.sell_rounded,
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            if (!order.isCancelled)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                child: GoldButton(
                  text: 'Download Invoice',
                  isOutlined: true,
                  onPressed: () => InvoiceService.generateAndPreviewInvoice(order),
                  icon: Icons.picture_as_pdf_rounded,
                ),
              ),
          ],
        ),
      ),
    ) ;
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;
  final bool isBold;

  const _DetailRow(this.label, this.value, {this.isBold = false});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: AppTextStyles.bodySmall),
          Text(
            value,
            style: isBold
                ? AppTextStyles.bodyMedium.copyWith(color: AppColors.royalGold, fontWeight: FontWeight.bold)
                : AppTextStyles.bodyMedium,
          ),
        ],
      ),
    );
  }
}

class _CountdownBox extends StatelessWidget {
  final String value;
  final String label;

  const _CountdownBox({required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      decoration: BoxDecoration(
        gradient: AppColors.goldGradient,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.royalGold.withOpacity(0.3),
            blurRadius: 16,
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            value,
            style: AppTextStyles.h2.copyWith(color: AppColors.deepBlack),
          ),
          Text(
            label,
            style: AppTextStyles.caption.copyWith(color: AppColors.deepBlack.withOpacity(0.7)),
          ),
        ],
      ),
    );
  }
}

class _ProgressStep extends StatelessWidget {
  final String title;
  final String subtitle;
  final bool isCompleted;
  final bool isFirst;
  final bool isLast;

  const _ProgressStep({
    required this.title,
    required this.subtitle,
    this.isCompleted = false,
    this.isFirst = false,
    this.isLast = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isCompleted ? AppColors.success.withOpacity(0.2) : AppColors.darkGrey.withOpacity(0.3),
                border: Border.all(
                  color: isCompleted ? AppColors.success : AppColors.darkGrey,
                  width: 2,
                ),
              ),
              child: isCompleted ? Icon(Icons.check, color: AppColors.success, size: 14) : null,
            ),
            if (!isLast)
              Container(width: 2, height: 36, color: isCompleted ? AppColors.success.withOpacity(0.5) : AppColors.darkGrey),
          ],
        ),
        SizedBox(width: 12),
        Padding(
          padding: const EdgeInsets.only(top: 2, bottom: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: AppTextStyles.labelLarge.copyWith(color: isCompleted ? AppColors.pureWhite : AppColors.grey)),
              Text(subtitle, style: AppTextStyles.caption),
            ],
          ),
        ),
      ],
    );
  }
}
