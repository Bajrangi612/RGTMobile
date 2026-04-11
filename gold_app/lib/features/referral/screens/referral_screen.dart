import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:share_plus/share_plus.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/utils/extensions.dart';
import '../../../widgets/gold_button.dart';
import '../../../widgets/gold_card.dart';
import '../../auth/providers/auth_provider.dart';
import '../../wallet/providers/wallet_provider.dart';
import '../../../widgets/shimmer_loader.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/providers/settings_provider.dart';

class ReferralScreen extends ConsumerWidget {
  const ReferralScreen({super.key}) ;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authProvider).user;
    final walletState = ref.watch(walletProvider);
    final settings = ref.watch(settingsProvider);
    final referralCode = user?.referralCode ?? '----';
    
    // Filter for referral transactions
    final referralTransactions = walletState.transactions
        .where((t) => t.type.toLowerCase() == 'referral' || t.type.toLowerCase() == 'referral_reward')
        .take(5)
        .toList();

    return Container(
      decoration: BoxDecoration(gradient: AppColors.darkGradient),
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              SizedBox(height: 16),

              // Header
              Text('Refer & Earn', style: AppTextStyles.h2)
                  .animate().fadeIn(duration: 300.ms),
              SizedBox(height: 8),
              Text(
                'Earn ${Formatters.currency(settings.referralReward)} for every successful referral',
                style: AppTextStyles.bodySmall,
                textAlign: TextAlign.center,
              ).animate(delay: 100.ms).fadeIn(),

              SizedBox(height: 32),

              // Reward Icon
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  gradient: AppColors.goldGradient,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.royalGold.withValues(alpha: 0.3),
                      blurRadius: 30,
                      spreadRadius: 3,
                    ),
                  ],
                ),
                child: Icon(Icons.card_giftcard_rounded, size: 50, color: AppColors.deepBlack),
              ).animate().scale(duration: 500.ms, curve: Curves.elasticOut),

              SizedBox(height: 32),

              // Referral Code Card
              GoldCard(
                hasGoldBorder: true,
                hasGlow: true,
                child: Column(
                  children: [
                    Text('Your Referral Code', style: AppTextStyles.labelMedium),
                    SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                      decoration: BoxDecoration(
                        color: AppColors.royalGold.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: AppColors.royalGold.withValues(alpha: 0.3),
                          width: 1.5,
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            referralCode,
                            style: AppTextStyles.h2.copyWith(
                              color: AppColors.royalGold,
                              letterSpacing: 4,
                            ),
                          ),
                          SizedBox(width: 12),
                          GestureDetector(
                            onTap: () {
                              Clipboard.setData(ClipboardData(text: referralCode)) ;
                              context.showSuccessSnackBar('Referral code copied!');
                            },
                            child: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: AppColors.royalGold.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Icon(Icons.copy, color: AppColors.royalGold, size: 18),
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: 20),
                    GoldButton(
                      text: 'Share via WhatsApp',
                      onPressed: () {
                        Share.share(
                          'Join Royal Gold and start buying 24K pure gold! Use my referral code: $referralCode to earn ${Formatters.currency(settings.referralReward)} cashback on your first order. Download now!',
                          subject: 'Royal Gold Store Invitation',
                        ) ;
                      },
                      icon: Icons.share,
                    ),
                  ],
                ),
              ).animate(delay: 300.ms).fadeIn(duration: 500.ms).slideY(begin: 0.1),

              SizedBox(height: 24),

              // Stats
              Row(
                children: [
                  Expanded(
                    child: GoldCard(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          Text(
                            (user?.wallet?.referralRewards ?? 0.0) > 0 
                              ? (user!.wallet!.referralRewards / 500).toInt().toString() 
                              : '0', 
                            style: AppTextStyles.h2.copyWith(color: AppColors.royalGold),
                          ),
                          SizedBox(height: 4),
                          Text('Referrals', style: AppTextStyles.caption),
                        ],
                      ),
                    ),
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: GoldCard(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          Text(
                            Formatters.currency(user?.wallet?.referralRewards ?? 0.0), 
                            style: AppTextStyles.h2.copyWith(color: AppColors.success),
                          ),
                          SizedBox(height: 4),
                          Text('Earned', style: AppTextStyles.caption),
                        ],
                      ),
                    ),
                  ),
                ],
              ).animate(delay: 400.ms).fadeIn(duration: 400.ms),

              const SizedBox(height: 24),
              
              // Withdrawal Action
              GoldButton(
                text: 'Withdraw Rewards',
                isOutlined: true,
                icon: Icons.payments_rounded,
                onPressed: () => _showWithdrawDialog(context, ref, user?.wallet?.referralRewards ?? 0.0, settings.minWithdrawal),
              ).animate(delay: 450.ms).fadeIn(),

              if (referralTransactions.isNotEmpty) ...[
                const SizedBox(height: 32),
                Row(
                  children: [
                    Icon(Icons.history_rounded, color: AppColors.royalGold, size: 18),
                    const SizedBox(width: 8),
                    Text('Recent Rewards', style: AppTextStyles.labelLarge),
                  ],
                ),
                const SizedBox(height: 16),
                ...referralTransactions.map((txn) => _RewardTile(txn: txn)),
              ],

              SizedBox(height: 24),

              // How it works
              GoldCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('How it works', style: AppTextStyles.labelLarge),
                    SizedBox(height: 16),
                    _HowItWorksStep(number: '1', text: 'Share your referral code with friends'),
                    _HowItWorksStep(number: '2', text: 'They use it during their first purchase'),
                    _HowItWorksStep(number: '3', text: 'You earn ${Formatters.currency(settings.referralReward)} per order', isLast: true),
                  ],
                ),
              ).animate(delay: 500.ms).fadeIn(duration: 400.ms),

              SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  void _showWithdrawDialog(BuildContext context, WidgetRef ref, double balance, double minAmount) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.cardDark,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: AppColors.royalGold.withValues(alpha: 0.3)),
        ),
        title: Text('Withdraw Rewards', style: AppTextStyles.h4),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Available Reward: ${Formatters.currency(balance)}',
              style: AppTextStyles.caption.copyWith(color: AppColors.royalGold),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              keyboardType: TextInputType.number,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Enter amount',
                prefixText: '₹ ',
                prefixStyle: TextStyle(color: AppColors.royalGold),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Minimum withdrawal: ${Formatters.currency(minAmount)}',
              style: AppTextStyles.caption.copyWith(color: AppColors.grey, fontSize: 10),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('CANCEL', style: TextStyle(color: AppColors.grey)),
          ),
          ElevatedButton(
            onPressed: () async {
              final amountStr = controller.text.trim();
              if (amountStr.isEmpty) return;
              
              final amount = double.tryParse(amountStr) ?? 0.0;
              if (amount < minAmount) {
                context.showErrorSnackBar('Minimum withdrawal is ${Formatters.currency(minAmount)}');
                return;
              }
              if (amount > balance) {
                context.showErrorSnackBar('Insufficient rewards balance');
                return;
              }
              
              final success = await ref.read(walletProvider.notifier).requestWithdrawal(amount);
              if (context.mounted) {
                Navigator.pop(context);
                if (success) {
                  context.showSuccessSnackBar('Withdrawal request submitted successfully!');
                }
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.royalGold),
            child: const Text('SUBMIT', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}

class _HowItWorksStep extends StatelessWidget {
  final String number;
  final String text;
  final bool isLast;

  const _HowItWorksStep({required this.number, required this.text, this.isLast = false});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: isLast ? 0 : 16),
      child: Row(
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              gradient: AppColors.goldGradient,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                number,
                style: AppTextStyles.labelMedium.copyWith(color: AppColors.deepBlack, fontWeight: FontWeight.w700),
              ),
            ),
          ),
          SizedBox(width: 12),
          Expanded(child: Text(text, style: AppTextStyles.bodyMedium)),
        ],
      ),
    );
  }
}
class _RewardTile extends StatelessWidget {
  final dynamic txn;
  const _RewardTile({required this.txn});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardDark.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.royalGold.withValues(alpha: 0.05)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.success.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.add_rounded, color: AppColors.success, size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(txn.description, style: AppTextStyles.bodyMedium),
                const SizedBox(height: 2),
                Text(
                  Formatters.relativeTime(txn.date.toIso8601String()), 
                  style: AppTextStyles.caption.copyWith(color: AppColors.grey),
                ),
              ],
            ),
          ),
          Text(
            '+${Formatters.currency(txn.amount)}',
            style: AppTextStyles.labelLarge.copyWith(color: AppColors.success, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}
