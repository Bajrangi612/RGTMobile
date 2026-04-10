import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';
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
import '../../auth/providers/auth_provider.dart';
import 'sell_back_screen.dart';
import '../../../core/services/invoice_service.dart';
import '../../../widgets/live_countdown.dart';

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
                                  color: AppColors.royalGold.withValues(alpha: 0.1),
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
                          _DetailRow('Gold Price', Formatters.currency(order.goldPriceAtPurchase ?? 0)),
                          _DetailRow('Taxable Amount', Formatters.currency(order.amount)),
                          _DetailRow('GST (3%)', Formatters.currency(order.gstAmount)),
                          _DetailRow('Total Price', Formatters.currency(order.totalPrice), isBold: true),
                          _DetailRow('Payment', order.paymentMethod),
                          _DetailRow('Order Date', DateFormat('dd/MM/yyyy HH:mm').format(order.createdAt)),
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
                                Icon(Icons.store_rounded, color: AppColors.royalGold, size: 22),
                                SizedBox(width: 10),
                                Text('Collection Estimate', style: AppTextStyles.labelLarge),
                              ],
                            ),
                            SizedBox(height: 16),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                _CountdownBox(
                                  label: 'Remaining',
                                  child: order.deliveryDate != null 
                                    ? LiveCountdown(targetDate: order.deliveryDate!)
                                    : Text('Ready for Pickup', style: AppTextStyles.h4.copyWith(color: AppColors.deepBlack)),
                                ),
                              ],
                            ),
                            SizedBox(height: 12),
                            Center(
                              child: Text(
                                order.deliveryDate != null 
                                  ? 'Expected by ${DateFormat('dd/MM/yyyy').format(order.deliveryDate!)}'
                                  : 'Arranging handover...',
                                style: AppTextStyles.bodySmall,
                              ),
                            ),
                          ],
                        ),
                      ).animate(delay: 200.ms).fadeIn(duration: 400.ms),

                    SizedBox(height: 16),

                    // Status History Timeline
                    GoldCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('Order Timeline', style: AppTextStyles.labelLarge),
                              Icon(Icons.history_rounded, color: AppColors.royalGold, size: 20),
                            ],
                          ),
                          SizedBox(height: 24),
                          if (order.statusHistory.isEmpty)
                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: 20),
                              child: Center(
                                child: Text('Logging fulfillment steps...', style: AppTextStyles.bodySmall),
                              ),
                            )
                          else
                            ...order.statusHistory.asMap().entries.map((entry) {
                              final index = entry.key;
                              final history = entry.value;
                              final isLast = index == order.statusHistory.length - 1;
                              final statusType = statusFromString(history.status);
                              
                              return _TimelineStep(
                                title: statusType.name.toUpperCase().replaceAll('_', ' '),
                                subtitle: history.notes ?? 'Standard fulfillment step.',
                                date: DateFormat('MMM dd, hh:mm a').format(history.createdAt),
                                isCompleted: true,
                                isLast: isLast,
                                status: statusType,
                              );
                            }),
                        ],
                      ),
                    ).animate(delay: 300.ms).fadeIn(duration: 400.ms),
                  ],
                ),
              ),
            ),

            // Action Buttons
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
              child: Column(
                children: [
                  if (order.canCancel)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: TextButton.icon(
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
                                  style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
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
                        icon: Icon(Icons.cancel_outlined, color: Colors.redAccent.withValues(alpha: 0.7), size: 18),
                        label: Text('Cancel Order', style: AppTextStyles.bodySmall.copyWith(color: Colors.redAccent.withValues(alpha: 0.7))),
                      ),
                    ),
                  
                  if (order.canResell)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: GoldButton(
                        text: 'Sell Back Gold',
                        onPressed: () => Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) =>  SellBackScreen(order: order),
                          ),
                        ),
                        icon: Icons.sell_rounded,
                      ),
                    ),

                  if (order.invoiceUrl != null || !order.isCancelled)
                    GoldButton(
                      text: 'View Tax Invoice',
                      isOutlined: true,
                      onPressed: () {
                        if (order.invoiceUrl != null) {
                           // Open cloud invoice
                        } else {
                          InvoiceService.generateAndPreviewInvoice(
                            order,
                            user: ref.read(authProvider).user,
                          );
                        }
                      },
                      icon: Icons.receipt_long_rounded,
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<_ProgressStepData> _getProgressSteps() {
    final status = order.status.toUpperCase();
    final steps = <_ProgressStepData>[];

    // Always starts with Confirmed
    steps.add(_ProgressStepData(
      title: 'Confirmed',
      subtitle: Formatters.date(order.createdAt.toIso8601String()),
      isCompleted: true,
    ));

    if (status == 'CANCELLED') {
      steps.add(_ProgressStepData(
        title: 'Cancelled',
        subtitle: 'Order cancelled by user',
        isCompleted: true,
      ));
      steps.add(_ProgressStepData(
        title: 'Refund Initialized',
        subtitle: 'Processing refund',
        isCompleted: false, // Could be dynamic if backend provides refund status
      ));
      return steps;
    }

    if (status == 'RESOLD') {
      steps.add(_ProgressStepData(
        title: 'Ready',
        subtitle: 'Inventory check complete',
        isCompleted: true,
      ));
      steps.add(_ProgressStepData(
        title: 'Buyback',
        subtitle: 'Order successfully collected by store',
        isCompleted: true,
      ));
      return steps;
    }

    // Normal Flow
    steps.add(_ProgressStepData(
      title: 'Processing',
      subtitle: status == 'PAID' || status == 'READY' || status == 'PICKED' ? 'Complete' : 'In progress',
      isCompleted: status == 'PAID' || status == 'READY' || status == 'PICKED',
    ));

    steps.add(_ProgressStepData(
      title: 'Ready for Pickup',
      subtitle: status == 'READY' || status == 'PICKED' ? 'Ready' : 'Pending',
      isCompleted: status == 'READY' || status == 'PICKED',
    ));

    steps.add(_ProgressStepData(
      title: 'Collected',
      subtitle: status == 'PICKED' ? 'Handover Complete' : 'Awaiting Collection',
      isCompleted: status == 'PICKED',
    ));

    return steps;
  }
}

class _ProgressStepData {
  final String title;
  final String subtitle;
  final bool isCompleted;

  _ProgressStepData({
    required this.title,
    required this.subtitle,
    this.isCompleted = false,
  });
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

class _TimelineStep extends StatelessWidget {
  final String title;
  final String subtitle;
  final String date;
  final bool isCompleted;
  final bool isLast;
  final StatusType status;

  const _TimelineStep({
    required this.title,
    required this.subtitle,
    required this.date,
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
        Column(
          children: [
            Container(
              width: 12,
              height: 12,
              margin: const EdgeInsets.only(top: 4, left: 6, right: 6),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: color,
                boxShadow: [
                  BoxShadow(color: color.withValues(alpha: 0.4), blurRadius: 8),
                ],
              ),
            ),
            if (!isLast)
              Container(
                width: 1,
                height: 60,
                color: AppColors.glassBorder,
              ),
          ],
        ),
        SizedBox(width: 12),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(bottom: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(title, style: AppTextStyles.labelLarge.copyWith(color: AppColors.pureWhite, fontSize: 13)),
                    Text(date, style: AppTextStyles.caption.copyWith(fontSize: 10)),
                  ],
                ),
                SizedBox(height: 4),
                Text(subtitle, style: AppTextStyles.bodySmall.copyWith(fontSize: 11, color: AppColors.grey)),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _CountdownBox extends StatelessWidget {
  final String label;
  final Widget child;

  const _CountdownBox({required this.label, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      decoration: BoxDecoration(
        color: AppColors.royalGold,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.royalGold.withValues(alpha: 0.3),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            label.toUpperCase(),
            style: AppTextStyles.labelSmall.copyWith(
              color: AppColors.deepBlack.withValues(alpha: 0.6),
              fontWeight: FontWeight.bold,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 8),
          child,
        ],
      ),
    );
  }
}
