import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';
import 'package:gold_app/core/theme/app_colors.dart';
import 'package:gold_app/core/theme/app_text_styles.dart';
import 'package:gold_app/core/utils/formatters.dart';
import 'package:gold_app/core/utils/extensions.dart';
import 'package:gold_app/widgets/gold_button.dart';
import 'package:gold_app/widgets/gold_card.dart';
import 'package:gold_app/widgets/gold_app_bar.dart';
import 'package:gold_app/widgets/status_badge.dart';
import 'package:gold_app/features/order/data/models/order_model.dart';
import 'package:gold_app/features/order/providers/order_provider.dart';
import 'package:gold_app/features/auth/providers/auth_provider.dart';
import 'package:gold_app/features/order/screens/sell_back_screen.dart';
import 'package:gold_app/core/services/invoice_service.dart';
import 'package:gold_app/widgets/live_countdown.dart';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:open_filex/open_filex.dart';
import 'package:url_launcher/url_launcher.dart';

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
                          Container(
                            padding: const EdgeInsets.all(24),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.03),
                              borderRadius: BorderRadius.circular(24),
                              border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
                            ),
                            child: Column(
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                     Column(
                                       crossAxisAlignment: CrossAxisAlignment.start,
                                       children: [
                                         Text(
                                           'PRICING BREAKDOWN', 
                                           style: AppTextStyles.labelMedium.copyWith(
                                             color: AppColors.royalGold,
                                             letterSpacing: 1.5,
                                             fontWeight: FontWeight.bold,
                                           )
                                         ),
                                         const SizedBox(height: 4),
                                         Text('Precision Audit Values', style: AppTextStyles.caption.copyWith(fontSize: 10, color: AppColors.grey)),
                                       ],
                                     ),
                                     StatusBadge(status: order.statusType),
                                  ],
                                ),
                                const SizedBox(height: 24),
                                _DetailRow(
                                  label: 'Market Gold Value', 
                                  value: Formatters.currency(double.tryParse(order.pricingNotes['pricingMarket'] ?? '0') ?? 0),
                                  icon: Icons.show_chart_rounded,
                                ),
                                _DetailRow(
                                  label: 'Portfolio Discount', 
                                  value: '- ${Formatters.currency(double.tryParse(order.pricingNotes['pricingDiscount'] ?? '0') ?? 0)}',
                                  icon: Icons.local_offer_rounded,
                                  valueColor: Colors.greenAccent,
                                ),
                                _DetailRow(
                                  label: 'Gold GST (IGST/CGST)', 
                                  value: Formatters.currency(double.tryParse(order.pricingNotes['pricingGoldGst'] ?? '0') ?? 0),
                                  icon: Icons.account_balance_rounded,
                                ),
                                _DetailRow(
                                  label: 'Making Charge', 
                                  value: Formatters.currency(double.tryParse(order.pricingNotes['pricingMaking'] ?? '0') ?? 0),
                                  icon: Icons.architecture_rounded,
                                ),
                                _DetailRow(
                                  label: 'GST on Making', 
                                  value: Formatters.currency(double.tryParse(order.pricingNotes['pricingMakingGst'] ?? '0') ?? 0),
                                  icon: Icons.receipt_long_rounded,
                                ),
                                Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 16),
                                  child: Divider(color: AppColors.grey.withValues(alpha: 0.2), height: 1),
                                ),
                                _DetailRow(
                                  label: 'Final Payable Total', 
                                  value: Formatters.currency(order.totalPrice), 
                                  isBold: true,
                                  icon: Icons.payments_rounded,
                                ),
                              ],
                            ),
                          ).animate().fadeIn(duration: 600.ms).slideY(begin: 0.1),
                          const SizedBox(height: 24),
                          
                          // Technical Specs
                          _DetailRow(label: 'Net Weight', value: '${order.weight.toStringAsFixed(3)} gram', icon: Icons.scale_rounded),
                          _DetailRow(label: 'Payment Method', value: order.paymentMethod, icon: Icons.credit_card_rounded),
                          _DetailRow(label: 'Transaction Date', value: DateFormat('dd MMM yyyy • HH:mm').format(order.createdAt), icon: Icons.calendar_today_rounded),
                          if (order.referralCode != null && order.referralCode!.isNotEmpty)
                            _DetailRow(label: 'Referral', value: order.referralCode!),
                        ],
                      ),
                    ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.05),

                    SizedBox(height: 16),

                    // Delivery View
                    if (order.isActive && !order.isDelivered && order.status.toUpperCase() != 'READY_FOR_PICKUP') ...[
                      GoldCard(
                        hasGlow: true,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(Icons.timer_rounded, color: AppColors.royalGold, size: 22),
                                SizedBox(width: 10),
                                Text('Delivery Estimate', style: AppTextStyles.labelLarge),
                              ],
                            ),
                            SizedBox(height: 16),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                _CountdownBox(
                                  label: 'Remaining',
                                  dateString: order.deliveryDate != null 
                                      ? DateFormat('EEEE, MMM dd').format(order.deliveryDate!)
                                      : null,
                                  child: ['READY_FOR_PICKUP', 'READY', 'DELIVERED', 'PICKED_UP', 'ORDER_CANCELLED', 'CANCELLED', 'SOLD_BACK', 'BUYBACK', 'RESOLD', 'PAYMENT_SETTLED', 'BUYBACK_PENDING', 'SELL_BACK_APPLIED', 'BUYBACK_APPROVED'].contains(order.status.toUpperCase()) 
                                    ? Text(Formatters.deliveryCountdown(order.deliveryDate, status: order.status).toUpperCase(), style: AppTextStyles.h3.copyWith(color: AppColors.charcoal, fontWeight: FontWeight.bold))
                                    : (order.deliveryDate != null 
                                      ? LiveCountdown(targetDate: order.deliveryDate!, style: AppTextStyles.h3.copyWith(color: AppColors.charcoal, fontWeight: FontWeight.bold))
                                      : const SizedBox.shrink()),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ).animate(delay: 200.ms).fadeIn(duration: 400.ms),
                      SizedBox(height: 16),

                      // Customer Address Information
                      GoldCard(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(Icons.location_on_rounded, color: AppColors.royalGold, size: 22),
                                SizedBox(width: 10),
                                Text('Delivery Information', style: AppTextStyles.labelLarge),
                              ],
                            ),
                            SizedBox(height: 16),
                            Text(
                              order.customerName ?? ref.read(authProvider).user?.name ?? 'Customer Name',
                              style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.bold),
                            ),
                            SizedBox(height: 4),
                            Text(
                              order.customerAddress ?? ref.read(authProvider).user?.address ?? 'No address provided',
                              style: AppTextStyles.bodySmall.copyWith(color: AppColors.grey),
                            ),
                          ],
                        ),
                      ).animate(delay: 250.ms).fadeIn(duration: 400.ms),
                    ],

                    SizedBox(height: 16),

                    // Status History Timeline
                    GoldCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('Order Timeline (IST)', style: AppTextStyles.labelLarge),
                              Icon(Icons.history_rounded, color: AppColors.royalGold, size: 20),
                            ],
                          ),
                          const SizedBox(height: 24),
                          if (order.statusHistory.isEmpty)
                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: 20),
                              child: Center(
                                child: Text('Logging fulfillment steps...', style: AppTextStyles.bodySmall),
                              ),
                            )
                          else
                            ...(order.statusHistory
                                .where((h) => !['PAYMENT_PENDING', 'PAYMENT_SUCCESSFUL'].contains(h.status.toUpperCase()))
                                .toList()..sort((a, b) => b.createdAt.compareTo(a.createdAt)))
                                .asMap()
                                .entries.map((entry) {

                              final index = entry.key;
                              final history = entry.value;
                              final validHistory = order.statusHistory.where((h) => !['PAYMENT_PENDING', 'PAYMENT_SUCCESSFUL'].contains(h.status.toUpperCase())).toList();
                              final isLast = index == (validHistory.length - 1);
                              final statusType = statusFromString(history.status);
                              
                              String title = StatusBadge(status: statusType).badgeLabel;

                              return _TimelineStep(
                                title: title,
                                subtitle: history.notes ?? 'Status updated successfully.',
                                date: DateFormat('MMM dd').format(history.createdAt),
                                time: DateFormat('hh:mm:ss a').format(history.createdAt),
                                isCompleted: true,
                                isLast: isLast,
                                status: statusType,
                              ).animate(delay: (index * 150).ms).fadeIn(duration: 400.ms).slideX(begin: 0.1, curve: Curves.easeOutQuad);
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
                  if (order.status.toUpperCase() == 'BUYBACK_PENDING')
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: GoldButton(
                        text: 'Cancel Buyback Request',
                        color: Colors.orange,
                        isOutlined: true,
                        onPressed: () async {
                          final confirm = await showDialog<bool>(
                            context: context,
                            builder: (ctx) => AlertDialog(
                              backgroundColor: AppColors.cardDark,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                              title: Text('Cancel Buyback?', style: AppTextStyles.h4),
                              content: const Text('Do you want to cancel your sell-back request and keep your gold?'),
                              actions: [
                                TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('NO')),
                                GoldButton(text: 'YES, CANCEL', height: 36, onPressed: () => Navigator.pop(ctx, true)),
                              ],
                            ),
                          );
                          if (confirm == true) {
                            await ref.read(orderProvider.notifier).cancelBuyback(order.id);
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Buyback request cancelled.')));
                            }
                          }
                        },
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

                  Row(
                    children: [
                      if (order.canCancel) 
                        Expanded(
                          child: GoldButton(
                            text: 'Cancel',
                            isOutlined: true,
                            color: Colors.redAccent,
                            onPressed: () async {
                              final confirm = await showDialog<bool>(
                                context: context,
                                builder: (ctx) => AlertDialog(
                                  backgroundColor: AppColors.cardDark,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(20),
                                    side: BorderSide(color: AppColors.royalGold.withValues(alpha: 0.3)),
                                  ),
                                  title: Text('Cancel Order?', style: AppTextStyles.h4),
                                  content: Text(
                                    'This action cannot be undone. You will receive a full refund in your wallet.',
                                    style: AppTextStyles.bodyMedium,
                                  ),
                                  actions: [
                                    TextButton(
                                      onPressed: () => Navigator.pop(ctx, false),
                                      child: Text('NO', style: TextStyle(color: AppColors.grey)),
                                    ),
                                    GoldButton(
                                      text: 'YES, CANCEL',
                                      height: 36,
                                      onPressed: () => Navigator.pop(ctx, true),
                                    ),
                                  ],
                                ),
                              ) ;
                              if (confirm == true) {
                                await ref.read(orderProvider.notifier).cancelOrder(order.id);
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('Order cancelled successfully.'),
                                      behavior: SnackBarBehavior.floating,
                                    ),
                                  );
                                  Navigator.of(context).pop();
                                }
                              }
                            },
                          ),
                        ),
                      
                      if (order.canCancel) const SizedBox(width: 12),

                      Expanded(
                        child: GoldButton(
                          text: order.invoiceUrl != null ? 'Download Invoice' : 'View Invoice',
                          onPressed: () async {
                            if (order.invoiceUrl != null) {
                              try {
                                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Downloading Invoice...'), duration: Duration(seconds: 1)));
                                final dir = await getApplicationDocumentsDirectory();
                                final filePath = '${dir.path}/invoice_${order.id}.pdf';
                                await Dio().download(order.invoiceUrl!, filePath);
                                await OpenFilex.open(filePath);
                              } catch (e) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Download Failed.', style: TextStyle(color: Colors.white)), backgroundColor: Colors.red),
                                );
                              }
                            } else {
                              InvoiceService.generateAndPreviewInvoice(
                                order,
                                user: ref.read(authProvider).user,
                              );
                            }
                          },
                          icon: order.invoiceUrl != null ? Icons.download_rounded : Icons.receipt_long_rounded,
                        ),
                      ),
                    ],
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
  final IconData? icon;
  final Color? valueColor;

  const _DetailRow({
    required this.label, 
    required this.value, 
    this.isBold = false,
    this.icon,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              if (icon != null) ...[
                Icon(icon, color: isBold ? AppColors.royalGold : AppColors.grey, size: 16),
                const SizedBox(width: 10),
              ],
              Text(
                label, 
                style: AppTextStyles.bodySmall.copyWith(
                  color: isBold ? AppColors.pureWhite : AppColors.offWhite,
                  fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
                )
              ),
            ],
          ),
          Text(
            value,
            style: TextStyle(
              color: valueColor ?? (isBold ? AppColors.royalGold : AppColors.pureWhite),
              fontSize: isBold ? 16 : 14,
              fontWeight: isBold ? FontWeight.w900 : FontWeight.w600,
              fontFamily: isBold ? null : 'monospace',
            ),
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

class _CountdownBox extends StatelessWidget {
  final String label;
  final Widget child;
  final String? dateString;

  const _CountdownBox({required this.label, required this.child, this.dateString});

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
              color: AppColors.charcoal.withValues(alpha: 0.6),
              fontWeight: FontWeight.bold,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 8),
          child,
          if (dateString != null) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.deepBlack.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                dateString!,
                style: AppTextStyles.caption.copyWith(
                  color: AppColors.charcoal,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
