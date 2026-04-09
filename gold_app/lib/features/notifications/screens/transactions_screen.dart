import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/formatters.dart';
import '../../../widgets/gold_card.dart';
import '../../../widgets/gold_app_bar.dart';
import '../../../widgets/shimmer_loader.dart';
import '../../../widgets/gold_button.dart';
import '../../wallet/providers/wallet_provider.dart';

class TransactionsScreen extends ConsumerStatefulWidget {
  const TransactionsScreen({super.key});

  @override
  ConsumerState<TransactionsScreen> createState() => _TransactionsScreenState();
}

class _TransactionsScreenState extends ConsumerState<TransactionsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(walletProvider.notifier).loadWalletDetails();
    });
  }

  IconData _getIcon(String type) {
    switch (type.toLowerCase()) {
      case 'purchase':
        return Icons.shopping_bag_rounded;
      case 'referral':
        return Icons.card_giftcard_rounded;
      case 'resell':
        return Icons.sell_rounded;
      case 'refund':
        return Icons.replay_rounded;
      case 'withdrawal':
        return Icons.account_balance_wallet_rounded;
      default:
        return Icons.receipt_long;
    }
  }

  Color _getColor(String type) {
    switch (type.toLowerCase()) {
      case 'purchase':
        return AppColors.info;
      case 'referral':
        return AppColors.royalGold;
      case 'resell':
        return AppColors.success;
      case 'refund':
        return AppColors.warning;
      case 'withdrawal':
        return AppColors.error;
      default:
        return AppColors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final walletState = ref.watch(walletProvider);
    final transactions = walletState.transactions;
    final isLoading = walletState.isLoading;

    return Scaffold(
      backgroundColor: AppColors.deepBlack,
      appBar: GoldAppBar(title: 'Transactions'),
      body: Container(
        decoration: BoxDecoration(gradient: AppColors.darkGradient),
        child: isLoading && transactions.isEmpty
            ? ListView.builder(
                padding: const EdgeInsets.all(24),
                itemCount: 5,
                itemBuilder: (_, __) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: ShimmerLoader.orderCard(),
                ),
              ) 
            : walletState.error != null
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.error_outline_rounded, size: 48, color: AppColors.error),
                          const SizedBox(height: 16),
                          Text(
                            'Something went wrong',
                            style: AppTextStyles.h4.copyWith(color: AppColors.error),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            walletState.error!,
                            textAlign: TextAlign.center,
                            style: AppTextStyles.caption.copyWith(color: AppColors.grey),
                          ),
                          const SizedBox(height: 24),
                          GoldButton(
                            text: 'RETRY',
                            onPressed: () => ref.read(walletProvider.notifier).loadWalletDetails(),
                          ),
                        ],
                      ),
                    ),
                  )
                : transactions.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.receipt_long_rounded, size: 64, color: AppColors.darkGrey),
                        const SizedBox(height: 16),
                        Text('No transactions found', style: AppTextStyles.h4.copyWith(color: AppColors.grey)),
                        const SizedBox(height: 8),
                        Text('Your financial history will appear here', style: AppTextStyles.caption),
                      ],
                    ),
                  )
                : RefreshIndicator(
                    onRefresh: () => ref.read(walletProvider.notifier).loadWalletDetails(),
                    color: AppColors.royalGold,
                    backgroundColor: AppColors.cardDark,
                    child: ListView.builder(
                      padding: const EdgeInsets.all(24),
                      itemCount: transactions.length,
                      itemBuilder: (context, index) {
                        final txn = transactions[index];
                        final amount = txn.amount;
                        final isCredit = ['referral', 'refund', 'resell'].contains(txn.type.toLowerCase());
                        final type = txn.type;

                        return GoldCard(
                          margin: const EdgeInsets.only(bottom: 12),
                          padding: const EdgeInsets.all(16),
                          child: Row(
                            children: [
                              Container(
                                width: 44,
                                height: 44,
                                decoration: BoxDecoration(
                                  color: _getColor(type).withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Icon(_getIcon(type), color: _getColor(type), size: 22),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      txn.description,
                                      style: AppTextStyles.labelMedium.copyWith(color: AppColors.pureWhite),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      Formatters.relativeTime(txn.date.toIso8601String()),
                                      style: AppTextStyles.caption,
                                    ),
                                  ],
                                ),
                              ),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    '${isCredit ? '+' : '-'}${Formatters.currency(amount)}',
                                    style: AppTextStyles.labelLarge.copyWith(
                                      color: isCredit ? AppColors.success : AppColors.error,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  if (txn.status.toLowerCase() != 'completed')
                                    Text(
                                      txn.status.toUpperCase(),
                                      style: TextStyle(
                                        color: AppColors.warning,
                                        fontSize: 9, 
                                        fontWeight: FontWeight.w800,
                                        letterSpacing: 1,
                                      ),
                                    ),
                                ],
                              ),
                            ],
                          ),
                        ).animate(delay: (index * 50).ms)
                            .fadeIn(duration: 400.ms)
                            .slideX(begin: 0.05);
                      },
                    ),
                  ),
      ),
    );
  }
}
