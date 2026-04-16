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
import 'glass_container.dart';
import '../core/providers/settings_provider.dart';

class OfferPopup extends ConsumerWidget {
  const OfferPopup({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final homeState = ref.watch(homeProvider);
    final settings = ref.watch(settingsProvider);
    
    final marketPrice = homeState.goldPrice; // Sell Price (Market Rate)
    final discountPercent = settings.globalDiscount;
    final offerPrice = marketPrice * (1 - (discountPercent / 100));
    final savingsPerGram = marketPrice - offerPrice;
    
    // Target date: 2 days from now at 12 AM (Midnight)
    final now = Formatters.nowIST;
    final targetDate = DateTime(now.year, now.month, now.day + 2);

    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20),
      child: GlassContainer(
        borderRadius: 30,
        blur: 25,
        backgroundColor: AppColors.deepBlack.withOpacity(0.85),
        padding: EdgeInsets.zero,
        border: Border.all(color: AppColors.royalGold.withOpacity(0.2), width: 1.5),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Premium Image Header
            Stack(
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
                  child: SizedBox(
                    height: 220,
                    width: double.infinity,
                    child: GoldImage(
                      imageUrl: 'assets/images/premium_gold_offer.webp', 
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                // Elegant Gradient Overlay
                Positioned.fill(
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.transparent,
                          AppColors.deepBlack.withOpacity(0.9),
                        ],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                    ),
                  ),
                ),
                Positioned(
                  top: 16,
                  right: 16,
                  child: IconButton(
                    icon: Icon(Icons.close_rounded, color: AppColors.offWhite, size: 26),
                    onPressed: () => Navigator.pop(context),
                  ),
                ),
                // Festive Badge
                Positioned(
                  bottom: 20,
                  left: 20,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      gradient: AppColors.goldGradient,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(color: AppColors.royalGold.withOpacity(0.3), blurRadius: 10),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.auto_awesome, color: AppColors.deepBlack, size: 16),
                        const SizedBox(width: 8),
                        Text(
                          'FESTIVE SPECIAL',
                          style: AppTextStyles.labelSmall.copyWith(
                            color: AppColors.deepBlack,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1.5,
                          ),
                        ),
                      ],
                    ),
                  ).animate().fadeIn(delay: 200.ms).slideX(begin: -0.2),
                ),
              ],
            ),

            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
              child: Column(
                children: [
                  Text(
                    'Exclusive Gold Savings',
                    style: AppTextStyles.h3.copyWith(
                      color: AppColors.pureWhite, 
                      fontWeight: FontWeight.w900, 
                      fontSize: 26,
                      letterSpacing: -0.5,
                    ),
                    textAlign: TextAlign.center,
                  ).animate().fadeIn(delay: 300.ms).scale(begin: const Offset(0.95, 0.95)),

                  const SizedBox(height: 12),

                  Text(
                    'Unlock a special ${discountPercent.toStringAsFixed(1)}% collection discount on 24K pure gold today.',
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: AppColors.offWhite, 
                      height: 1.4,
                    ),
                    textAlign: TextAlign.center,
                  ).animate().fadeIn(delay: 400.ms),

                  const SizedBox(height: 32),

                  // Premium Breakdown Section
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: AppColors.cardDark.withOpacity(0.5),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: AppColors.royalGold.withOpacity(0.1)),
                    ),
                    child: Column(
                      children: [
                        _PriceRow(
                          label: 'Base Market Rate (1g)',
                          value: Formatters.currency(marketPrice),
                        ),
                        _PriceRow(
                          label: 'Member Discount',
                          value: '- ${Formatters.currency(savingsPerGram)}',
                          valueColor: AppColors.success,
                          badge: discountPercent > 0 ? '${discountPercent.toStringAsFixed(0)}% OFF' : null,
                        ),
                        _PriceRow(
                          label: 'Making Charges',
                          value: settings.makingCharge == 0 ? 'FREE' : Formatters.currency(marketPrice * (settings.makingCharge / 100)),
                          valueColor: settings.makingCharge == 0 ? AppColors.success : null,
                          isHighlighted: settings.makingCharge == 0,
                        ),
                        _PriceRow(
                          label: 'GST (${settings.gstRate.toStringAsFixed(0)}%)',
                          value: '+ ${Formatters.currency(offerPrice * (settings.gstRate / 100))}',
                        ),
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 12),
                          child: Divider(color: Colors.white10),
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'TOTAL MEMBER PRICE (Incl. GST)',
                              style: AppTextStyles.labelMedium.copyWith(color: AppColors.royalGold, fontWeight: FontWeight.bold, letterSpacing: 1, fontSize: 10),
                            ),
                            Text(
                              Formatters.currency(offerPrice + (offerPrice * (settings.gstRate / 100))),
                              style: AppTextStyles.h4.copyWith(color: AppColors.royalGold),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ).animate().fadeIn(delay: 500.ms),

                  const SizedBox(height: 32),

                  // Countdown Section
                  Column(
                    children: [
                       Text(
                        'OFFER EXPIRES IN',
                        style: AppTextStyles.labelSmall.copyWith(color: AppColors.grey, letterSpacing: 3),
                      ),
                      const SizedBox(height: 12),
                      LiveCountdown(
                        targetDate: targetDate,
                        style: AppTextStyles.h3.copyWith(
                          color: AppColors.royalGold,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1.5,
                        ),
                      ),
                    ],
                  ).animate().fadeIn(delay: 700.ms),

                  const SizedBox(height: 32),

                  GoldButton(
                    text: 'BUY GOLD NOW',
                    onPressed: () {
                      Navigator.pop(context);
                      Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const CatalogScreen()),
                      );
                    },
                  ).animate(onPlay: (controller) => controller.repeat())
                   .shimmer(duration: 3.seconds, delay: 1.seconds, color: Colors.white24)
                   .animate().fadeIn(delay: 800.ms),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PriceRow extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;
  final String? badge;
  final bool isHighlighted;

  const _PriceRow({
    required this.label,
    required this.value,
    this.valueColor,
    this.badge,
    this.isHighlighted = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Text(
                label,
                style: AppTextStyles.bodyMedium.copyWith(color: AppColors.offWhite.withOpacity(0.7)),
              ),
              if (badge != null) ...[
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.success.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    badge!,
                    style: AppTextStyles.caption.copyWith(color: AppColors.success, fontWeight: FontWeight.bold, fontSize: 8),
                  ),
                ),
              ],
            ],
          ),
          Text(
            value,
            style: AppTextStyles.labelLarge.copyWith(
              color: valueColor ?? AppColors.pureWhite,
              fontWeight: isHighlighted ? FontWeight.w900 : FontWeight.w500,
              fontSize: isHighlighted ? 15 : 14,
            ),
          ),
        ],
      ),
    );
  }
}
