import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/formatters.dart';
import '../../../widgets/gold_card.dart';
import '../../../widgets/status_badge.dart';
import '../../order/data/models/order_model.dart';
import '../../auth/data/models/user_model.dart';
import '../providers/admin_provider.dart';
import 'admin_order_detail_screen.dart';

class AdminOrderManager extends ConsumerWidget {
  const AdminOrderManager({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final adminState = ref.watch(adminProvider);
    final searchQuery = adminState.orderSearchQuery.toLowerCase();

    // Helper to filter orders
    List<dynamic> filterOrders(List<dynamic> baseOrders) {
      if (searchQuery.isEmpty) return baseOrders;
      return baseOrders.where((o) {
        final idMatch = o['id'].toString().toLowerCase().contains(searchQuery);
        final nameMatch = (o['user']?['name'] ?? '').toString().toLowerCase().contains(searchQuery);
        final phoneMatch = (o['user']?['phone'] ?? '').toString().toLowerCase().contains(searchQuery);
        return idMatch || nameMatch || phoneMatch;
      }).toList();
    }

    return DefaultTabController(
      length: 5,
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          title: Text('Order Management', style: AppTextStyles.h4),
          backgroundColor: Colors.transparent,
          elevation: 0,
          centerTitle: true,
          iconTheme: IconThemeData(color: AppColors.royalGold),
        ),
        body: Column(
          children: [
            /// 🔍 Search Bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: GoldCard(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                child: TextField(
                  style: AppTextStyles.labelMedium,
                  onChanged: (v) => ref.read(adminProvider.notifier).updateOrderSearchQuery(v),
                  cursorColor: AppColors.royalGold,
                  decoration: InputDecoration(
                    hintText: 'Search by Order ID or Customer...',
                    hintStyle: AppTextStyles.caption.copyWith(color: AppColors.pureWhite.withValues(alpha: 0.3)),
                    border: InputBorder.none,
                    icon: Icon(Icons.search, color: AppColors.royalGold, size: 22),
                  ),
                ),
              ),
            ),

            /// 🏷️ Tabs
            TabBar(
              isScrollable: true,
              indicatorColor: AppColors.royalGold,
              labelColor: AppColors.royalGold,
              unselectedLabelColor: AppColors.grey,
              tabs: const [
                Tab(text: 'ACTIVE'),
                Tab(text: 'HANDLING'),
                Tab(text: 'READY'),
                Tab(text: 'REFUNDS'),
                Tab(text: 'ALL'),
              ],
            ),

            Expanded(
              child: TabBarView(
                children: [
                  // ACTIVE: Just Confirmed/Paid
                  _OrderList(orders: filterOrders(adminState.allOrders.where((o) => 
                     ['PAYMENT_SUCCESSFUL', 'ORDER_CONFIRMED'].contains(o['status'].toString().toUpperCase())).toList())),
                  
                  // HANDLING: Processing & Quality Check
                  _OrderList(orders: filterOrders(adminState.allOrders.where((o) => 
                     ['PROCESSING', 'QUALITY_CHECKING'].contains(o['status'].toString().toUpperCase())).toList())),
                  
                  // READY: Ready for Pickup & Picked Up
                  _OrderList(orders: filterOrders(adminState.allOrders.where((o) => 
                     ['READY_FOR_PICKUP', 'PICKED_UP'].contains(o['status'].toString().toUpperCase())).toList())),

                  // REFUNDS
                  _OrderList(orders: filterOrders(adminState.allOrders.where((o) => 
                     ['REFUND_REQUESTED', 'REFUNDED'].contains(o['status'].toString().toUpperCase())).toList())),
                  
                  // ALL
                  _OrderList(orders: filterOrders(adminState.allOrders)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _OrderList extends StatelessWidget {
  final List<dynamic> orders;
  const _OrderList({required this.orders});

  @override
  Widget build(BuildContext context) {
    if (orders.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.inventory_2_outlined, size: 64, color: AppColors.grey.withValues(alpha: 0.2)),
            const SizedBox(height: 16),
            Text('No orders in this category', style: AppTextStyles.bodyMedium.copyWith(color: AppColors.grey)),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: orders.length,
      itemBuilder: (context, index) {
        final order = orders[index];
        final status = statusFromString(order['status'] ?? 'pending');
        
        return Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: GestureDetector(
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => AdminOrderDetailScreen(order: order)),
            ),
            child: GoldCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.pureWhite.withValues(alpha: 0.03),
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                    ),
                    child: Row(
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('ORDER #${order['id'].toString().substring(0, 8).toUpperCase()}', 
                              style: AppTextStyles.labelLarge.copyWith(letterSpacing: 1)),
                            const SizedBox(height: 4),
                            Text(Formatters.dateTime(order['createdAt'].toString()),
                              style: AppTextStyles.caption.copyWith(color: AppColors.grey)),
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
                        Row(
                          children: [
                            Icon(Icons.person_pin_outlined, size: 16, color: AppColors.royalGold),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                '${order['user']?['name'] ?? 'Guest'} • ${order['user']?['phone'] ?? '...'}',
                                style: AppTextStyles.bodySmall.copyWith(color: AppColors.offWhite),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('Est. Readiness', style: AppTextStyles.caption),
                            Text(
                              Formatters.deliveryCountdown(order['deliveryDate']),
                              style: AppTextStyles.bodySmall.copyWith(color: AppColors.royalGold),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('Total Amount', style: AppTextStyles.caption),
                            Text(
                              Formatters.currency(_toDouble(order['total'])),
                              style: AppTextStyles.labelLarge.copyWith(color: AppColors.royalGold),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        const Divider(height: 1, color: Colors.white10),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Icon(Icons.info_outline, size: 12, color: AppColors.grey),
                            const SizedBox(width: 4),
                            Text('Tap to view details & fulfill', 
                              style: AppTextStyles.caption.copyWith(fontSize: 10, color: AppColors.grey)),
                            const Spacer(),
                            Icon(Icons.arrow_forward_ios_rounded, size: 12, color: AppColors.grey),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ).animate(delay: (index * 50).ms).fadeIn().slideY(begin: 0.1);
      },
    );
  }

  double _toDouble(dynamic value) {
    if (value is num) return value.toDouble();
    return double.tryParse(value?.toString() ?? '0') ?? 0.0;
  }
}
