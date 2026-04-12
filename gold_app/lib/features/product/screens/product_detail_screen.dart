import 'dart:async';
import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
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
import '../../../widgets/gold_image.dart';
import '../presentation/widgets/checkout_sheet.dart';
import '../../auth/providers/auth_provider.dart';
import '../../../core/providers/settings_provider.dart';
import '../../profile/screens/profile_screen.dart';
import '../../../core/network/api_service.dart';

class ProductDetailScreen extends ConsumerStatefulWidget {
  final ProductModel product;

  ProductDetailScreen({super.key, required this.product}) ;

  @override
  ConsumerState<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends ConsumerState<ProductDetailScreen> {
  int _quantity = 1;
  final _referralController = TextEditingController();
  String? _refereeName;
  bool _isValidatingReferral = false;
  String? _referralError;
  Timer? _debounceTimer;

  @override
  void initState() {
    super.initState();
    _referralController.addListener(_onReferralChanged);
  }

  void _onReferralChanged() {
    if (_debounceTimer?.isActive ?? false) _debounceTimer!.cancel();
    
    final code = _referralController.text.trim();

    // Reset validation state immediately if not yet 10 digits
    if (code.length != 10) {
      if (_refereeName != null || _referralError != null || _isValidatingReferral) {
        setState(() {
          _refereeName = null;
          _referralError = null;
          _isValidatingReferral = false;
        });
      }
      return;
    }

    _debounceTimer = Timer(const Duration(milliseconds: 300), () {
      _validateReferral(code);
    });
  }

  Future<void> _validateReferral(String code) async {
    // Only validate if exactly 10 characters
    if (code.length != 10) return;

    final currentUser = ref.read(authProvider).user;
    if (currentUser != null && code == currentUser.referralCode && currentUser.orderCount == 0) {
      setState(() {
        _refereeName = null;
        _referralError = "You cannot use your own code for your first order";
      });
      return;
    }

    setState(() => _isValidatingReferral = true);

    try {
      final response = await ApiService().verifyReferralCode(code);
      if (mounted) {
        setState(() {
          _refereeName = response.data['data']['name'];
          _referralError = null;
          _isValidatingReferral = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _refereeName = null;
          _referralError = "Invalid referral code";
          _isValidatingReferral = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _referralController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final product = widget.product;
    final pricing = product.pricing;
    
    if (pricing == null) {
      return Scaffold(
        backgroundColor: AppColors.deepBlack,
        appBar: GoldAppBar(title: 'Product Details'),
        body: Center(
          child: CircularProgressIndicator(color: AppColors.royalGold),
        ),
      );
    }

    final subtotal = pricing.discountedGoldValue * _quantity;
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
                        child: Hero(
                          tag: 'elite_${product.id}',
                          child: Center(
                            child: GoldImage(
                              imageUrl: product.image,
                              height: 180,
                              width: 180,
                              fit: BoxFit.contain,
                            ),
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
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('Base Gold Value', style: AppTextStyles.bodyMedium.copyWith(color: AppColors.offWhite)),
                                    const SizedBox(height: 4),
                                    Text(
                                      Formatters.currency(pricing.marketPrice),
                                      style: AppTextStyles.caption.copyWith(
                                        decoration: TextDecoration.lineThrough,
                                        fontSize: 16,
                                        color: AppColors.grey.withOpacity(0.4),
                                      ),
                                    ),
                                  ],
                                ),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Text('Special Offer', style: AppTextStyles.labelSmall.copyWith(color: AppColors.success)),
                                    const SizedBox(height: 4),
                                    Text(
                                      Formatters.currency(pricing.discountedGoldValue),
                                      style: AppTextStyles.priceTag.copyWith(fontSize: 32),
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
                          const SizedBox(height: 12),

                          // Delivery & Security Trust Badges
                          Container(
                            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.03),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.white.withOpacity(0.05)),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                _TrustIcon(icon: Icons.local_shipping_outlined, label: 'On-Time Delivery'),
                                _TrustIcon(icon: Icons.verified_outlined, label: 'BIS Hallmarked'),
                                _TrustIcon(icon: Icons.lock_outline, label: 'Fully Insured'),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),
                           Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('Gold Value', style: AppTextStyles.bodyMedium.copyWith(color: AppColors.offWhite)),
                              Text(Formatters.currency(pricing.discountedGoldValue * _quantity), style: AppTextStyles.bodyMedium.copyWith(color: AppColors.pureWhite)),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('Making Charges', style: AppTextStyles.bodyMedium.copyWith(color: AppColors.offWhite)),
                              Text(Formatters.currency(pricing.makingCharges * _quantity), style: AppTextStyles.bodyMedium.copyWith(color: AppColors.pureWhite)),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('CGST (1.5% + SGST)', style: AppTextStyles.bodyMedium.copyWith(color: AppColors.offWhite)),
                              Text(Formatters.currency((pricing.gstAmount * _quantity) / 2), style: AppTextStyles.bodyMedium.copyWith(color: AppColors.pureWhite)),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('SGST (1.5% + SGST)', style: AppTextStyles.bodyMedium.copyWith(color: AppColors.offWhite)),
                              Text(Formatters.currency((pricing.gstAmount * _quantity) / 2), style: AppTextStyles.bodyMedium.copyWith(color: AppColors.pureWhite)),
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
                            prefixIcon: Icon(Icons.confirmation_number_outlined, color: AppColors.royalGold.withOpacity(_refereeName != null ? 1 : 0.5)),
                          ),
                          if (_isValidatingReferral)
                            Padding(
                              padding: const EdgeInsets.only(top: 8, left: 4),
                              child: const SizedBox(
                                height: 12,
                                width: 12,
                                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.amber), // Use standard color if const is required, or remove const
                              ),
                            ),
                          if (_refereeName != null)
                            Padding(
                              padding: const EdgeInsets.only(top: 8, left: 4),
                              child: Row(
                                children: [
                                  const Icon(Icons.check_circle_outline, color: AppColors.success, size: 14),
                                  const SizedBox(width: 6),
                                  Text(
                                    'Verified: $_refereeName',
                                    style: AppTextStyles.caption.copyWith(color: AppColors.success, fontWeight: FontWeight.bold),
                                  ),
                                ],
                              ),
                            ),
                          if (_referralError != null)
                            Padding(
                              padding: const EdgeInsets.only(top: 8, left: 4),
                              child: Row(
                                children: [
                                  const Icon(Icons.error_outline, color: AppColors.error, size: 14),
                                  const SizedBox(width: 6),
                                  Text(
                                    _referralError!,
                                    style: AppTextStyles.caption.copyWith(color: AppColors.error),
                                  ),
                                ],
                              ),
                            ),
                          const SizedBox(height: 8),
                          Text(
                            'Support your referrer by applying their code!',
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
                                        Share.share(
                                          'Join Royal Gold and start buying 24K pure gold! Use my referral code: ${currentUser.referralCode} to earn ${Formatters.currency(ref.read(settingsProvider).referralReward)} cashback per gram on your first order. Download now!',
                                          subject: 'Royal Gold Store Invitation',
                                        );
                                      },
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 12),
                              Text(
                                'You earn ${Formatters.currency(ref.watch(settingsProvider).referralReward)} per Gram. For this ${product.weight}g coin, you will receive ${Formatters.currency(ref.watch(settingsProvider).referralReward * product.weight)} reward!',
                                style: AppTextStyles.caption.copyWith(color: AppColors.success, fontWeight: FontWeight.bold),
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

class _TrustIcon extends StatelessWidget {
  final IconData icon;
  final String label;

  const _TrustIcon({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, color: Colors.white70, size: 16),
        const SizedBox(height: 4),
        Text(
          label,
          style: AppTextStyles.caption.copyWith(fontSize: 8, color: Colors.white38),
        ),
      ],
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
