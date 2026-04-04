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

class ReferralScreen extends ConsumerWidget {
  ReferralScreen({super.key}) ;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authProvider).user;
    final referralCode = user?.referralCode ?? 'RGXK7M2N';

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
                'Earn ₹${AppConstants.referralCommission.toInt()} for every successful referral',
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
                      color: AppColors.royalGold.withOpacity(0.3),
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
                        color: AppColors.royalGold.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: AppColors.royalGold.withOpacity(0.3),
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
                                color: AppColors.royalGold.withOpacity(0.15),
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
                          'Join Royal Gold and start investing in 24K pure gold! Use my referral code: $referralCode to earn ₹${AppConstants.referralCommission.toInt()} cashback on your first purchase. Download now!',
                          subject: 'Premium Gold Trading Referral',
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
                          Text('12', style: AppTextStyles.h2.copyWith(color: AppColors.royalGold)),
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
                          Text('₹6,000', style: AppTextStyles.h2.copyWith(color: AppColors.success)),
                          SizedBox(height: 4),
                          Text('Earned', style: AppTextStyles.caption),
                        ],
                      ),
                    ),
                  ),
                ],
              ).animate(delay: 400.ms).fadeIn(duration: 400.ms),

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
                    _HowItWorksStep(number: '3', text: 'You earn ₹${AppConstants.referralCommission.toInt()} per order', isLast: true),
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
