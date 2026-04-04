import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/services/mock_data_service.dart';
import '../../../widgets/gold_card.dart';
import '../../../widgets/gold_app_bar.dart';
import '../../../widgets/shimmer_loader.dart';

class TransactionsScreen extends ConsumerStatefulWidget {
  TransactionsScreen({super.key}) ;

  @override
  ConsumerState<TransactionsScreen> createState() => _TransactionsScreenState();
}

class _TransactionsScreenState extends ConsumerState<TransactionsScreen> {
  List<Map<String, dynamic>> _transactions = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadTransactions();
  }

  Future<void> _loadTransactions() async {
    await MockDataService.simulateDelay();
    if (mounted) {
      setState(() {
        _transactions = MockDataService.getTransactions();
        _isLoading = false;
      });
    }
  }

  IconData _getIcon(String type) {
    switch (type) {
      case 'purchase':
        return Icons.shopping_bag_rounded;
      case 'referral':
        return Icons.card_giftcard_rounded;
      case 'resell':
        return Icons.sell_rounded;
      case 'refund':
        return Icons.replay_rounded;
      default:
        return Icons.receipt_long;
    }
  }

  Color _getColor(String type) {
    switch (type) {
      case 'purchase':
        return AppColors.info;
      case 'referral':
        return AppColors.royalGold;
      case 'resell':
        return AppColors.success;
      case 'refund':
        return AppColors.warning;
      default:
        return AppColors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.deepBlack,
      appBar: GoldAppBar(title: 'Transactions'),
      body: Container(
        decoration: BoxDecoration(gradient: AppColors.darkGradient),
        child: _isLoading
            ? ListView.builder(
                padding: const EdgeInsets.all(24),
                itemCount: 5,
                itemBuilder: (_, __) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: ShimmerLoader.orderCard(),
                ),
              ) : _transactions.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.receipt_long, size: 64, color: AppColors.darkGrey),
                        SizedBox(height: 16),
                        Text('No transactions', style: AppTextStyles.h4.copyWith(color: AppColors.grey)),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(24),
                    itemCount: _transactions.length,
                    itemBuilder: (context, index) {
                      final txn = _transactions[index];
                      final amount = (txn['amount'] as num).toDouble() ;
                      final isCredit = amount > 0;
                      final type = txn['type'] as String;

                      return GoldCard(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          children: [
                            Container(
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(
                                color: _getColor(type).withOpacity(0.12),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Icon(_getIcon(type), color: _getColor(type), size: 22),
                            ),
                            SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    txn['description'] ?? '',
                                    style: AppTextStyles.labelMedium.copyWith(color: AppColors.pureWhite),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  SizedBox(height: 4),
                                  Text(
                                    Formatters.relativeTime(txn['date']),
                                    style: AppTextStyles.caption,
                                  ),
                                ],
                              ),
                            ),
                            Text(
                              '${isCredit ? '+' : ''}${Formatters.currency(amount.abs())}',
                              style: AppTextStyles.labelLarge.copyWith(
                                color: isCredit ? AppColors.success : AppColors.error,
                              ),
                            ),
                          ],
                        ),
                      ).animate(delay: (200 + index * 100).ms)
                          .fadeIn(duration: 400.ms)
                          .slideX(begin: 0.05) ;
                    },
                  ),
      ),
    );
  }
}
