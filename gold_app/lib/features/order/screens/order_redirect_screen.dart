import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/order_provider.dart';
import 'order_detail_screen.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';

class OrderRedirectScreen extends ConsumerStatefulWidget {
  final String orderId;

  const OrderRedirectScreen({super.key, required this.orderId});

  @override
  ConsumerState<OrderRedirectScreen> createState() => _OrderRedirectScreenState();
}

class _OrderRedirectScreenState extends ConsumerState<OrderRedirectScreen> {
  @override
  void initState() {
    super.initState();
    _loadAndRedirect();
  }

  Future<void> _loadAndRedirect() async {
    // 1. Ensure orders are loaded (or refresh them)
    await ref.read(orderProvider.notifier).loadOrders();
    
    if (!mounted) return;

    // 2. Find the specific order in the state
    final orders = ref.read(orderProvider).orders;
    final targetOrder = orders.where((o) => o.id == widget.orderId).firstOrNull;

    if (targetOrder != null) {
      // 3. Redirect to Detail Screen
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => OrderDetailScreen(order: targetOrder),
        ),
      );
    } else {
      // 4. Handle Not Found
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Order not found or access denied.'),
          backgroundColor: Colors.red,
        ),
      );
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.deepBlack,
      body: Container(
        decoration: BoxDecoration(gradient: AppColors.darkGradient),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(color: AppColors.royalGold),
              const SizedBox(height: 24),
              Text(
                'Fetching order details...',
                style: AppTextStyles.labelLarge.copyWith(color: AppColors.royalGold),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
