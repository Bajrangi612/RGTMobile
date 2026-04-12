import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../features/home/providers/home_provider.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/app_text_styles.dart';
import '../core/utils/formatters.dart';
import 'gold_card.dart';
import 'gold_button.dart';
import 'gold_image.dart';
import 'live_countdown.dart';
import '../features/product/screens/catalog_screen.dart';

class OfferPopup extends ConsumerWidget {
  const OfferPopup({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final homeState = ref.watch(homeProvider);
    final marketPrice = homeState.buyPrice; // Base market price
    final offerPrice = marketPrice * 0.98; // Generic 2% discount for the offer banner
    
    // Target date: 2 days from now at 12 AM (Midnight)
    final now = DateTime.now();
    final targetDate = DateTime(now.year, now.month, now.day + 2);

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20),
      child: GoldCard(
        isVibrant: true,
        hasGoldBorder: true,
        hasGlow: true,
        blurSigma: 80,
        padding: EdgeInsets.zero,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Banner Image Header
            Stack(
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                  child: SizedBox(
                    height: 200,
                    width: double.infinity,
                    child: GoldImage(
                      imageUrl: 'assets/images/premium_gold_offer.png', // Fallback to asset if local path differs
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                Positioned(
                  top: 16,
                  right: 16,
                  child: IconButton(
                    icon: const Icon(Icons.close, color: Colors.white, size: 24),
                    onPressed: () => Navigator.pop(context),
                  ),
                ),
                Positioned(
                  bottom: -1,
                  left: 0,
                  right: 0,
                  child: Container(
                    height: 80,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Colors.transparent, AppColors.deepBlack.withOpacity(0.9)],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                    ),
                  ),
                ),
              ],
            ),

            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppColors.royalGold.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.royalGold.withOpacity(0.3)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.auto_awesome, color: AppColors.royalGold, size: 14),
                        const SizedBox(width: 8),
                        Text(
                          'EXCLUSIVE FESTIVE RELEASE',
                          style: AppTextStyles.labelSmall.copyWith(
                            color: AppColors.royalGold,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.2,
                          ),
                        ),
                      ],
                    ),
                  ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.2),

                  const SizedBox(height: 20),

                  Text(
                    'Elite Portfolio Rewards',
                    style: AppTextStyles.h3.copyWith(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 24),
                    textAlign: TextAlign.center,
                  ).animate().fadeIn(delay: 300.ms).slideY(begin: 0.1),

                  const SizedBox(height: 8),

                  const Text(
                    'Invest in 24K pure gold with 0% Making Charges and exclusive institutional rates.',
                    style: TextStyle(color: Colors.white60, fontSize: 13, height: 1.5),
                    textAlign: TextAlign.center,
                  ).animate().fadeIn(delay: 400.ms),

                  const SizedBox(height: 28),

                  // Pricing Comparison Row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      Column(
                        children: [
                          const Text('MARKET RATE', style: TextStyle(color: Colors.white38, fontSize: 10, letterSpacing: 1)),
                          const SizedBox(height: 4),
                          Text(
                            Formatters.currency(marketPrice),
                            style: AppTextStyles.h4.copyWith(
                              decoration: TextDecoration.lineThrough,
                              color: Colors.white24,
                            ),
                          ),
                        ],
                      ),
                      Container(width: 1, height: 30, color: Colors.white12),
                      Column(
                        children: [
                          Text('OFFER RATE', style: AppTextStyles.labelSmall.copyWith(color: AppColors.success)),
                          const SizedBox(height: 4),
                          Text(
                            Formatters.currency(offerPrice),
                            style: AppTextStyles.goldPrice.copyWith(fontSize: 24),
                          ),
                        ],
                      ),
                    ],
                  ).animate().fadeIn(delay: 500.ms).scale(begin: const Offset(0.9, 0.9)),

                  const SizedBox(height: 32),

                  // Countdown Timer
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    decoration: BoxDecoration(
                      color: AppColors.royalGold.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: AppColors.royalGold.withOpacity(0.1)),
                    ),
                    child: Column(
                      children: [
                         Text(
                          'OFFER EXPIRES IN',
                          style: AppTextStyles.labelSmall.copyWith(color: AppColors.grey, letterSpacing: 4),
                        ),
                        const SizedBox(height: 12),
                        LiveCountdown(
                          targetDate: targetDate,
                          style: AppTextStyles.h2.copyWith(
                            color: AppColors.royalGold,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 2,
                            shadows: [
                              Shadow(color: AppColors.royalGold.withOpacity(0.3), blurRadius: 15),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ).animate().fadeIn(delay: 600.ms).slideY(begin: 0.2),

                  const SizedBox(height: 32),

                  GoldButton(
                    text: 'SHOP THE COLLECTION',
                    onPressed: () {
                      Navigator.pop(context);
                      Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const CatalogScreen()),
                      );
                    },
                  ).animate().fadeIn(delay: 700.ms).shimmer(duration: 2.seconds, color: Colors.white24),
                  
                  const SizedBox(height: 8),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
