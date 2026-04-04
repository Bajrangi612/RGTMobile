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
import '../providers/order_provider.dart';
import '../data/models/order_model.dart';
import 'order_detail_screen.dart';

class OrdersScreen extends ConsumerStatefulWidget {
  OrdersScreen({super.key}) ;

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

    return Container(
      decoration: BoxDecoration(gradient: AppColors.darkGradient),
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
              child: Text('My Orders', style: AppTextStyles.h2),
            ).animate().fadeIn(duration: 300.ms),

            SizedBox(height: 4),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Text(
                'Track and manage your gold orders',
                style: AppTextStyles.bodySmall,
              ),
            ).animate().fadeIn(delay: 100.ms),

            SizedBox(height: 20),

            Expanded(
              child: orderState.isLoading
                  ? ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      itemCount: 3,
                      itemBuilder: (_, __) => Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: ShimmerLoader.orderCard(),
                      ),
                    ) : orderState.orders.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.receipt_long_rounded,
                                size: 64,
                                color: AppColors.darkGrey,
                              ),
                              SizedBox(height: 16),
                              Text('No orders yet', style: AppTextStyles.h4.copyWith(color: AppColors.grey)),
                              SizedBox(height: 8),
                              Text(
                                'Start investing in gold coins',
                                style: AppTextStyles.bodySmall,
                              ),
                            ],
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 24),
                          itemCount: orderState.orders.length,
                          itemBuilder: (context, index) {
                            final order = orderState.orders[index];
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
                        ),
            ),
          ],
        ),
      ),
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
                color: AppColors.royalGold.withOpacity(0.1),
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
                  Text(order.productName, style: AppTextStyles.labelLarge),
                  SizedBox(height: 4),
                  Text(
                    Formatters.date(order.orderDate),
                    style: AppTextStyles.caption,
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  Formatters.currency(order.price),
                  style: AppTextStyles.priceTag.copyWith(fontSize: 15),
                ),
                SizedBox(height: 6),
                 StatusBadge(status: order.statusType, small: true),
              ],
            ),
          ],
        ),
      ),
    ) ;
  }
}
