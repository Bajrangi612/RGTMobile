import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/formatters.dart';
import '../../../widgets/gold_card.dart';
import '../../../widgets/gold_app_bar.dart';
import '../../../widgets/status_badge.dart';
import '../../../widgets/shimmer_loader.dart';
import '../../../widgets/live_countdown.dart';
import '../providers/order_provider.dart';
import '../data/models/order_model.dart';
import 'order_detail_screen.dart';

class OrdersScreen extends ConsumerStatefulWidget {
  final bool onlyEligible;
  const OrdersScreen({super.key, this.onlyEligible = false}) ;

  @override
  ConsumerState<OrdersScreen> createState() => _OrdersScreenState();
}

class _OrdersScreenState extends ConsumerState<OrdersScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(orderProvider.notifier).loadOrders();
    });
  }

  @override
  Widget build(BuildContext context) {
    final orderState = ref.watch(orderProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Container(
        decoration: BoxDecoration(gradient: AppColors.darkGradient),
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
              child: Row(
                children: [
                  if (Navigator.of(context).canPop())
                    IconButton(
                      icon: Icon(Icons.arrow_back_ios, color: AppColors.pureWhite, size: 20),
                      onPressed: () => Navigator.pop(context),
                    ),
                  Text(
                    widget.onlyEligible ? 'Buyback Eligible' : 'My Orders',
                    style: AppTextStyles.h2,
                  ),
                ],
              ),
            ).animate().fadeIn(duration: 300.ms),

            SizedBox(height: 4),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Text(
                widget.onlyEligible 
                  ? 'Select an item to sell back to Royal Gold'
                  : 'Track and manage your gold orders',
                style: AppTextStyles.bodySmall,
              ),
            ).animate().fadeIn(delay: 100.ms),

            SizedBox(height: 20),

            Expanded(
              child: RefreshIndicator(
                onRefresh: () => ref.read(orderProvider.notifier).loadOrders(),
                color: AppColors.royalGold,
                backgroundColor: AppColors.surface,
                child: _buildBody(ref, orderState),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

  Widget _buildBody(WidgetRef ref, dynamic orderState) {
    if (orderState.isLoading && orderState.orders.isEmpty) {
      return ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        itemCount: 3,
        itemBuilder: (_, __) => Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: ShimmerLoader.orderCard(),
        ),
      );
    }

    if (orderState.error != null) {
      return Center(
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 48, color: Colors.redAccent),
              const SizedBox(height: 16),
              Text(
                'Failed to load orders',
                style: AppTextStyles.h4.copyWith(color: Colors.white),
              ),
              const SizedBox(height: 8),
              Text(
                orderState.error!,
                style: AppTextStyles.bodySmall,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () => ref.read(orderProvider.notifier).loadOrders(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.royalGold,
                  foregroundColor: Colors.black,
                ),
                child: const Text('RETRY'),
              ),
            ],
          ),
        ),
      );
    }

    final displayOrders = widget.onlyEligible
        ? orderState.orders.where((o) => o.status.toUpperCase() == 'READY_FOR_PICKUP').toList()
        : orderState.orders;

    if (displayOrders.isEmpty) {
      return Center(
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                widget.onlyEligible ? Icons.sell_rounded : Icons.receipt_long_rounded,
                size: 64,
                color: AppColors.darkGrey,
              ).animate().scale(duration: 500.ms),
              const SizedBox(height: 16),
              Text(
                widget.onlyEligible ? 'No eligible orders' : 'No orders yet',
                style: AppTextStyles.h4.copyWith(color: AppColors.grey),
              ),
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 40),
                child: Text(
                  widget.onlyEligible
                      ? 'Orders must be "READY FOR PICKUP" to be eligible for the buyback program.'
                      : 'Start collecting gold coins',
                  style: AppTextStyles.bodySmall,
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 24),
      itemCount: displayOrders.length,
      itemBuilder: (context, index) {
        final order = displayOrders[index];
        return _OrderCard(
          order: order,
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => OrderDetailScreen(order: order),
            ),
          ),
        ).animate(delay: (200 + index * 100).ms)
            .fadeIn(duration: 400.ms)
            .slideX(begin: 0.05);
      },
    );
  }
}

class _OrderCard extends StatelessWidget {
  final OrderModel order;
  final VoidCallback onTap;

  const _OrderCard({required this.order, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: GoldCard(
        onTap: onTap,
        hasGoldBorder: order.isActive,
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: AppColors.royalGold.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.monetization_on_rounded, color: AppColors.royalGold, size: 24),
                  Text(
                    '${order.weight.toStringAsFixed(1)}g',
                    style: AppTextStyles.caption.copyWith(
                      color: AppColors.royalGold,
                      fontWeight: FontWeight.w700,
                      fontSize: 9,
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    order.productName, 
                    style: AppTextStyles.labelLarge,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  Wrap(
                    crossAxisAlignment: WrapCrossAlignment.center,
                    spacing: 8,
                    runSpacing: 4,
                    children: [
                      Text(
                        'Qty: ${order.quantity} | ${Formatters.date(order.orderDate)}',
                        style: AppTextStyles.caption.copyWith(fontSize: 10),
                      ),
                      if (order.deliveryDate != null || order.isActive) ...[
                        Container(
                          width: 3,
                          height: 3,
                          decoration: const BoxDecoration(shape: BoxShape.circle, color: Colors.white24),
                        ),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.timer_outlined, color: AppColors.royalGold.withValues(alpha: 0.6), size: 10),
                            const SizedBox(width: 4),
                            Builder(
                              builder: (context) {
                                final status = order.status.toUpperCase();
                                final isFinalStatus = ['READY_FOR_PICKUP', 'READY', 'DELIVERED', 'PICKED_UP', 'ORDER_CANCELLED', 'CANCELLED', 'SOLD_BACK', 'BUYBACK', 'RESOLD', 'PAYMENT_SETTLED', 'BUYBACK_PENDING', 'SELL_BACK_APPLIED', 'BUYBACK_APPROVED'].contains(status);
                                
                                if (isFinalStatus) {
                                  return Text(
                                    Formatters.deliveryCountdown(order.deliveryDate, status: order.status).toUpperCase(),
                                    style: AppTextStyles.caption.copyWith(color: AppColors.royalGold, fontWeight: FontWeight.bold, fontSize: 9),
                                  );
                                }
                                
                                if (order.deliveryDate != null) {
                                  return Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      LiveCountdown(
                                        targetDate: order.deliveryDate!,
                                        style: AppTextStyles.caption.copyWith(
                                          color: AppColors.royalGold,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 9,
                                        ),
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        '| Delivery on time',
                                        style: AppTextStyles.caption.copyWith(color: AppColors.success, fontSize: 8, fontWeight: FontWeight.bold),
                                      ),
                                    ],
                                  );
                                }
                                
                                return const SizedBox.shrink();
                              },
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  Formatters.currency(order.totalPrice),
                  style: AppTextStyles.priceTag.copyWith(fontSize: 14),
                ),
                Text(
                  '(Incl. GST)',
                  style: AppTextStyles.caption.copyWith(fontSize: 7, color: AppColors.success),
                ),
                const SizedBox(height: 8),
                StatusBadge(status: order.statusType, small: true),
              ],
            ),
          ],
        ),
      ),
    ) ;
  }
}
