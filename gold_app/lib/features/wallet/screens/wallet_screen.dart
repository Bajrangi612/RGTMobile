import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/formatters.dart';
import '../../../widgets/gold_card.dart';
import '../../../widgets/gold_button.dart';
import '../../auth/providers/auth_provider.dart';

class WalletScreen extends ConsumerWidget {
  const WalletScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authProvider).user;
    final wallet = user?.wallet;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Container(
        decoration: BoxDecoration(gradient: AppColors.darkGradient),
        child: SafeArea(
          child: CustomScrollView(
            slivers: [
              // Custom Gold Header
              SliverAppBar(
                expandedHeight: 120,
                backgroundColor: Colors.transparent,
                elevation: 0,
                leading: IconButton(
                  icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 20),
                  onPressed: () => Navigator.pop(context),
                ),
                flexibleSpace: FlexibleSpaceBar(
                  centerTitle: true,
                  title: Text(
                    'MY WALLET',
                    style: AppTextStyles.h4.copyWith(
                      color: AppColors.royalGold,
                      letterSpacing: 2,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),

              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    children: [
                      // Main Balance Card
                      _MainBalanceCard(balance: wallet?.balance ?? 0.0)
                          .animate().fadeIn().slideY(begin: 0.1),
                      
                      const SizedBox(height: 24),

                      // Stats Row
                      Row(
                        children: [
                          Expanded(
                            child: _StatCard(
                              label: 'Gold Advance',
                              value: wallet?.goldAdvance ?? 0.0,
                              icon: Icons.auto_graph_rounded,
                              color: AppColors.royalGold,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: _StatCard(
                              label: 'Referral Rewards',
                              value: wallet?.referralRewards ?? 0.0,
                              icon: Icons.card_giftcard_rounded,
                              color: AppColors.success,
                            ),
                          ),
                        ],
                      ).animate(delay: 200.ms).fadeIn().slideY(begin: 0.1),

                      const SizedBox(height: 32),

                      // Section Header
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Recent Transactions', style: AppTextStyles.labelLarge),
                          TextButton(
                            onPressed: () {},
                            child: Text('See All', style: TextStyle(color: AppColors.royalGold)),
                          ),
                        ],
                      ),

                      const SizedBox(height: 12),

                      // Mock Transactions or Empty State
                      _TransactionList(),
                      
                      const SizedBox(height: 40),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MainBalanceCard extends StatelessWidget {
  final double balance;

  const _MainBalanceCard({required this.balance});

  @override
  Widget build(BuildContext context) {
    return GoldCard(
      padding: const EdgeInsets.all(24),
      hasGlow: true,
      child: Column(
        children: [
          Text(
            'Total Cash Balance',
            style: AppTextStyles.bodySmall.copyWith(color: AppColors.grey),
          ),
          const SizedBox(height: 8),
          Text(
            Formatters.currency(balance),
            style: AppTextStyles.h1.copyWith(
              color: AppColors.pureWhite,
              fontSize: 36,
            ),
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: GoldButton(
                  text: 'Deposit',
                  icon: Icons.add_circle_outline,
                  onPressed: () {},
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: GoldButton(
                  text: 'Withdraw',
                  isOutlined: true,
                  icon: Icons.arrow_outward_rounded,
                  onPressed: () => _showWithdrawDialog(context),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showWithdrawDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.cardDark,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: AppColors.royalGold.withOpacity(0.3)),
        ),
        title: Text('Withdrawal Request', style: AppTextStyles.h4),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Available: ${Formatters.currency(balance)}',
              style: AppTextStyles.caption.copyWith(color: AppColors.royalGold),
            ),
            const SizedBox(height: 16),
            TextField(
              keyboardType: TextInputType.number,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Enter amount',
                prefixText: '₹ ',
                prefixStyle: TextStyle(color: AppColors.royalGold),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('CANCEL', style: TextStyle(color: AppColors.grey)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Withdrawal request submitted!')),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.royalGold),
            child: const Text('SUBMIT', style: TextStyle(color: Colors.black)),
          ),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final double value;
  final IconData icon;
  final Color color;

  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return GoldCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 12),
          Text(label, style: AppTextStyles.caption.copyWith(color: AppColors.grey)),
          const SizedBox(height: 4),
          Text(
            Formatters.currency(value),
            style: AppTextStyles.h4.copyWith(color: AppColors.pureWhite, fontSize: 16),
          ),
        ],
      ),
    );
  }
}

class _TransactionList extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _TransactionTile(
          title: 'Referral Reward - User XYZ',
          date: 'Oct 24, 2023',
          amount: 500,
          isCredit: true,
        ),
        const SizedBox(height: 12),
        _TransactionTile(
          title: 'Purchase - 1g Gold Coin',
          date: 'Oct 22, 2023',
          amount: 7500,
          isCredit: false,
        ),
        const SizedBox(height: 12),
        _TransactionTile(
          title: 'Gold Advance Monthly',
          date: 'Oct 15, 2023',
          amount: 2000,
          isCredit: true,
        ),
      ],
    );
  }
}

class _TransactionTile extends StatelessWidget {
  final String title;
  final String date;
  final double amount;
  final bool isCredit;

  const _TransactionTile({
    required this.title,
    required this.date,
    required this.amount,
    required this.isCredit,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardDark.withOpacity(0.5),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.royalGold.withOpacity(0.05)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: (isCredit ? AppColors.success : AppColors.error).withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              isCredit ? Icons.add_rounded : Icons.remove_rounded,
              color: isCredit ? AppColors.success : AppColors.error,
              size: 20,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: AppTextStyles.bodyMedium),
                const SizedBox(height: 4),
                Text(date, style: AppTextStyles.caption.copyWith(color: AppColors.grey)),
              ],
            ),
          ),
          Text(
            '${isCredit ? "+" : "-"} ₹${amount.toInt()}',
            style: AppTextStyles.labelLarge.copyWith(
              color: isCredit ? AppColors.success : AppColors.error,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
