import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/formatters.dart';
import '../../../widgets/gold_card.dart';
import '../../../widgets/status_badge.dart';
import '../providers/admin_provider.dart';

class AdminOrderManager extends ConsumerWidget {
  const AdminOrderManager({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final adminState = ref.watch(adminProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('Order Management', style: AppTextStyles.h4),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        iconTheme: IconThemeData(color: AppColors.royalGold),
        actions: [
          IconButton(
            icon: Icon(Icons.filter_list, color: AppColors.royalGold),
            onPressed: () {},
          ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(color: AppColors.background),
        child: Column(
          children: [
            /// 📊 Order Summary Bar
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  _OrderSummaryTile(
                    label: 'Pending',
                    count: adminState.allOrders.where((o) => o['status'] == 'pending').length,
                    color: AppColors.royalGold,
                  ),
                  const SizedBox(width: 10),
                  _OrderSummaryTile(
                    label: 'Processing',
                    count: adminState.allOrders.where((o) => o['status'] == 'processing').length,
                    color: Colors.blueAccent,
                  ),
                  const SizedBox(width: 10),
                  _OrderSummaryTile(
                    label: 'Shipped',
                    count: adminState.allOrders.where((o) => o['status'] == 'shipped').length,
                    color: Colors.purpleAccent,
                  ),
                ],
              ),
            ),

            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: adminState.allOrders.length,
                itemBuilder: (context, index) {
                  final order = adminState.allOrders[index];
                  final status = statusFromString(order['status'] ?? 'pending');
                  
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: GoldCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          /// 📦 Order Header (Slip Look)
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: AppColors.pureWhite.withOpacity(0.03),
                              borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                            ),
                            child: Row(
                              children: [
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('ORDER #${order['id']}', style: AppTextStyles.labelLarge.copyWith(letterSpacing: 1)),
                                    const SizedBox(height: 4),
                                    Text(
                                      order['date'] ?? 'Just now',
                                      style: AppTextStyles.caption.copyWith(color: AppColors.grey),
                                    ),
                                  ],
                                ),
                                const Spacer(),
                                StatusBadge(status: status, small: true),
                              ],
                            ),
                          ),

                          Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                /// 👤 Customer Info
                                Row(
                                  children: [
                                    Icon(Icons.person_pin_outlined, size: 16, color: AppColors.royalGold),
                                    const SizedBox(width: 8),
                                    Text(
                                      'Customer: ${order['customerName'] ?? 'John Doe'}',
                                      style: AppTextStyles.bodySmall.copyWith(color: AppColors.offWhite),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),

                                /// 💰 Pricing Info
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text('Total Amount', style: AppTextStyles.caption),
                                    Text(
                                      Formatters.currency(order['total'] ?? 0),
                                      style: AppTextStyles.labelLarge.copyWith(color: AppColors.royalGold),
                                    ),
                                  ],
                                ),

                                const SizedBox(height: 20),
                                Divider(height: 1, color: AppColors.pureWhite.withOpacity(0.1)),
                                const SizedBox(height: 12),

                                /// 🚀 Quick Actions
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    _ActionChip(
                                      label: 'Update Status',
                                      icon: Icons.edit_road_outlined,
                                      onPressed: () => _showStatusUpdateMenu(context, ref, order['id']),
                                    ),
                                    _ActionChip(
                                      label: 'View Label',
                                      icon: Icons.print_outlined,
                                      onPressed: () {},
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ).animate(delay: (index * 50).ms).fadeIn().slideY(begin: 0.1);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showStatusUpdateMenu(BuildContext context, WidgetRef ref, String orderId) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Update Order Status', style: AppTextStyles.h4),
            const SizedBox(height: 24),
            _StatusMenuItem(
              label: 'Processing',
              icon: Icons.sync,
              onTap: () {
                ref.read(adminProvider.notifier).updateOrderStatus(orderId, 'processing');
                Navigator.pop(context);
              },
            ),
            _StatusMenuItem(
              label: 'Shipped',
              icon: Icons.local_shipping,
              onTap: () {
                ref.read(adminProvider.notifier).updateOrderStatus(orderId, 'shipped');
                Navigator.pop(context);
              },
            ),
            _StatusMenuItem(
              label: 'Delivered',
              icon: Icons.check_circle,
              onTap: () {
                ref.read(adminProvider.notifier).updateOrderStatus(orderId, 'delivered');
                Navigator.pop(context);
              },
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}

class _OrderSummaryTile extends StatelessWidget {
  final String label;
  final int count;
  final Color color;
  const _OrderSummaryTile({required this.label, required this.count, required this.color});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GoldCard(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Column(
          children: [
            Text('$count', style: AppTextStyles.h4.copyWith(color: color)),
            const SizedBox(height: 4),
            Text(label, style: TextStyle(color: AppColors.pureWhite.withOpacity(0.6), fontSize: 8, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }
}

class _ActionChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onPressed;
  const _ActionChip({required this.label, required this.icon, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          border: Border.all(color: AppColors.pureWhite.withOpacity(0.1)),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(icon, size: 14, color: AppColors.royalGold),
            const SizedBox(width: 8),
            Text(label, style: AppTextStyles.caption.copyWith(fontSize: 10)),
          ],
        ),
      ),
    );
  }
}

class _StatusMenuItem extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;
  const _StatusMenuItem({required this.label, required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: AppColors.royalGold),
      title: Text(label, style: AppTextStyles.labelLarge),
      onTap: onTap,
    );
  }
}
