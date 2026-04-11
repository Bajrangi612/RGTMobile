import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/constants/app_constants.dart';
import '../../../widgets/gold_button.dart';
import '../../../widgets/gold_card.dart';
import '../../../widgets/gold_app_bar.dart';
import '../../../widgets/gold_text_field.dart';
import '../data/models/product_model.dart';
import '../presentation/widgets/checkout_sheet.dart';
import '../../auth/providers/auth_provider.dart';
import '../../../core/providers/settings_provider.dart';
import '../../profile/screens/profile_screen.dart';

class ProductDetailScreen extends ConsumerStatefulWidget {
  final ProductModel product;

  ProductDetailScreen({super.key, required this.product}) ;

  @override
  ConsumerState<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends ConsumerState<ProductDetailScreen> {
  int _quantity = 1;
  final _referralController = TextEditingController();

  @override
  void dispose() {
    _referralController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final product = widget.product;
    final pricing = product.pricing!;
    final subtotal = pricing.goldValue * _quantity;
    final gstAmount = pricing.gstAmount * _quantity;
    final totalAmount = pricing.total * _quantity;

    return Scaffold(
      backgroundColor: AppColors.deepBlack,
      appBar:  GoldAppBar(title: 'Product Details'),
      body: Container(
        decoration: BoxDecoration(gradient: AppColors.darkGradient),
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Product Image (Single)
                    Center(
                      child: Container(
                        width: 250,
                        height: 250,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: RadialGradient(
                            colors: [
                              AppColors.royalGold.withOpacity(0.15),
                              AppColors.cardDark,
                            ],
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.royalGold.withOpacity(0.1),
                              blurRadius: 40,
                              spreadRadius: 5,
                            ),
                          ],
                        ),
                        child: Center(
                          child: product.image.isNotEmpty
                            ? Image.network(
                                product.image,
                                height: 180,
                                width: 180,
                                fit: BoxFit.contain,
                                errorBuilder: (context, error, stackTrace) => Icon(
                                  Icons.monetization_on_rounded,
                                  size: 80,
                                  color: AppColors.royalGold.withOpacity(0.9),
                                ),
                              )
                            : Icon(
                                Icons.monetization_on_rounded,
                                size: 80,
                                color: AppColors.royalGold.withOpacity(0.9),
                              ),
                        ),
                      ),
                    ).animate(onPlay: (controller) => controller.repeat(reverse: true))
                      .slideY(
                        begin: -0.03,
                        end: 0.03,
                        duration: 2000.ms,
                        curve: Curves.easeInOutSine,
                      ),

                    SizedBox(height: 32),

                    // Product Name
                    Text(product.name, style: AppTextStyles.h2)
                        .animate().fadeIn(delay: 200.ms).slideX(begin: -0.05),

                    SizedBox(height: 16),

                    // Specs Row
                    Row(
                      children: [
                        _SpecChip(label: product.purity, icon: Icons.verified),
                        SizedBox(width: 8),
                        _SpecChip(label: 'Fine ${product.fineness}', icon: Icons.diamond),
                        SizedBox(width: 8),
                        _SpecChip(label: 'BIS', icon: Icons.shield),
                      ],
                    ).animate(delay: 300.ms).fadeIn(duration: 400.ms),

                    SizedBox(height: 24),

                    // Price Card
                     GoldCard(
                      hasGoldBorder: true,
                      hasGlow: true,
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('Price per unit', style: AppTextStyles.bodyMedium),
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.baseline,
                                textBaseline: TextBaseline.alphabetic,
                                children: [
                                  if (product.oldPrice != null) ...[
                                    Text(
                                      Formatters.currency(product.oldPrice!),
                                      style: AppTextStyles.caption.copyWith(
                                        decoration: TextDecoration.lineThrough,
                                        fontSize: 14,
                                      ),
                                    ),
                                    SizedBox(width: 8),
                                  ],
                                  Text(
                                    Formatters.currency(product.price),
                                    style: AppTextStyles.priceTag,
                                  ),
                                ],
                              ),
                            ],
                          ),
                          SizedBox(height: 16),
                          // Exclusivity Badge
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: AppColors.royalGold.withOpacity(0.05),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: AppColors.royalGold.withOpacity(0.2)),
                            ),
                            child: Row(
                              children: [
                                Icon(Icons.stars_rounded, color: AppColors.royalGold, size: 20),
                                SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text('Limited Edition Release', style: AppTextStyles.labelMedium.copyWith(color: AppColors.royalGold)),
                                      Text('Maximum 1 unit per customer for luxury integrity.', style: AppTextStyles.caption),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                           Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('Subtotal', style: AppTextStyles.bodyMedium),
                              Text(Formatters.currency(subtotal), style: AppTextStyles.bodyMedium),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('GST (3%)', style: AppTextStyles.bodyMedium),
                              Text(Formatters.currency(gstAmount), style: AppTextStyles.bodyMedium),
                            ],
                          ),
                          Divider(height: 32, color: AppColors.darkGrey),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('Total Payable', style: AppTextStyles.h4),
                              Text(
                                Formatters.currency(totalAmount),
                                style: AppTextStyles.goldPrice.copyWith(fontSize: 28),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ).animate(delay: 400.ms).fadeIn(duration: 500.ms),

                    SizedBox(height: 16),

                    // Referral Code
                    GoldCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.card_giftcard, color: AppColors.royalGold, size: 20),
                              SizedBox(width: 8),
                              Text('Referral Code', style: AppTextStyles.labelLarge),
                              SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: AppColors.success.withOpacity(0.15),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  'Optional',
                                  style: AppTextStyles.caption.copyWith(color: AppColors.success),
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 12),
                          GoldTextField(
                            controller: _referralController,
                            label: 'Enter referral code',
                            hint: 'e.g., RGXK7M2N',
                            textCapitalization: TextCapitalization.characters,
                            prefixIcon: Icon(Icons.confirmation_number_outlined, color: AppColors.grey),
                          ),
                          SizedBox(height: 8),
                          Text(
                            'Apply a referral code to earn ₹${ref.watch(settingsProvider).referralReward.toInt()} commission',
                            style: AppTextStyles.caption,
                          ),
                        ],
                      ),
                    ).animate(delay: 500.ms).fadeIn(duration: 400.ms),

                    SizedBox(height: 24),

                    // 🏆 Your Status / Referral Benefit
                    Builder(
                      builder: (context) {
                        final currentUser = ref.watch(authProvider).user;
                        if (currentUser == null) return const SizedBox.shrink();
                        
                        return GoldCard(
                          hasGoldBorder: true,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(Icons.stars, color: AppColors.royalGold, size: 20),
                                  SizedBox(width: 8),
                                  Text('Your Referral Benefit', style: AppTextStyles.labelLarge),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.05),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: AppColors.glassBorder),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text('Personal Code', style: AppTextStyles.caption),
                                        Text(currentUser.referralCode, style: AppTextStyles.h4.copyWith(color: AppColors.royalGold)),
                                      ],
                                    ),
                                    GoldButton(
                                      text: 'SHARE',
                                      width: 80,
                                      height: 36,
                                      onPressed: () {
                                        // Handle Share logic (e.g., share_plus)
                                      },
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 12),
                              Text(
                                'Share this code to earn ₹${ref.watch(settingsProvider).referralReward.toInt()} fixed reward on every successful referral purchase.',
                                style: AppTextStyles.caption.copyWith(color: AppColors.success),
                              ),
                            ],
                          ),
                        ).animate(delay: 600.ms).fadeIn();
                      },
                    ),

                    const SizedBox(height: 24),

                    // Description
                    Text('About this coin', style: AppTextStyles.labelLarge),
                    SizedBox(height: 8),
                    Text(product.description ?? 'A premium gold coin for long-term savings.', style: AppTextStyles.bodyMedium.copyWith(color: AppColors.grey, height: 1.6)),

                    SizedBox(height: 24),
                  ],
                ),
              ),
            ),

            // Bottom CTA
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppColors.charcoal.withOpacity(0.95),
                border: Border(top: BorderSide(color: AppColors.glassBorder)),
              ),
              child: SafeArea(
                child: GoldButton(
                  text: 'Proceed to Checkout',
                  onPressed: () {
                    final user = ref.read(authProvider).user;
                    if (user == null || !user.isProfileComplete) {
                      showModalBottomSheet(
                        context: context,
                        backgroundColor: Colors.transparent,
                        builder: (context) => GoldCard(
                          margin: const EdgeInsets.all(24),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.info_outline, color: AppColors.royalGold, size: 48),
                              const SizedBox(height: 16),
                              Text('Complete Profile', style: AppTextStyles.h3),
                              const SizedBox(height: 12),
                              Text(
                                'Please complete your personal and bank details to proceed with gold purchases.',
                                textAlign: TextAlign.center,
                                style: AppTextStyles.bodyMedium,
                              ),
                              const SizedBox(height: 24),
                              GoldButton(
                                text: 'GO TO PROFILE',
                                onPressed: () {
                                  Navigator.pop(context);
                                  Navigator.of(context).push(
                                    MaterialPageRoute(builder: (_) => ProfileScreen()),
                                  );
                                },
                              ),
                            ],
                          ),
                        ),
                      );
                      return;
                    }

                    showModalBottomSheet(
                      context: context,
                      isScrollControlled: true,
                      backgroundColor: Colors.transparent,
                      builder: (context) => CheckoutSheet(
                        product: product,
                        referralCode: _referralController.text.trim().isNotEmpty 
                          ? _referralController.text.trim() 
                          : null,
                      ),
                    );
                  },
                  icon: Icons.shopping_cart_checkout,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SpecChip extends StatelessWidget {
  final String label;
  final IconData icon;

  const _SpecChip({required this.label, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.royalGold.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.royalGold.withOpacity(0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: AppColors.royalGold, size: 14),
          SizedBox(width: 4),
          Text(
            label,
            style: AppTextStyles.caption.copyWith(
              color: AppColors.royalGold,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
