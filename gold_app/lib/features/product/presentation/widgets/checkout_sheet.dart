import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';
import '../providers/product_providers.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../widgets/gold_button.dart';
import '../../../../widgets/gold_card.dart';
import '../../../profile/screens/profile_screen.dart';
import '../../data/models/product_model.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../auth/providers/auth_provider.dart';
import '../../../order/providers/order_provider.dart';
import '../../../../core/theme/app_text_styles.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../../core/providers/navigation_provider.dart';
import '../../../order/screens/order_detail_screen.dart';

class CheckoutSheet extends ConsumerStatefulWidget {
  final ProductModel product;
  final String? referralCode;

  const CheckoutSheet({super.key, required this.product, this.referralCode});

  @override
  ConsumerState<CheckoutSheet> createState() => _CheckoutSheetState();
}

class _CheckoutSheetState extends ConsumerState<CheckoutSheet> {
  late Razorpay _razorpay;
  int _quantity = 1;
  String? _pendingOrderId; // Database Order ID
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    _razorpay = Razorpay();
    _razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, _handlePaymentSuccess);
    _razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, _handlePaymentError);
    _razorpay.on(Razorpay.EVENT_EXTERNAL_WALLET, _handleExternalWallet);
  }

  @override
  void dispose() {
    super.dispose();
    _razorpay.clear();
  }

  void _handlePaymentSuccess(PaymentSuccessResponse response) async {
    if (_isProcessing) return;
    setState(() => _isProcessing = true);

    final messenger = ScaffoldMessenger.of(context);
    // Secure verification: send paymentId and signature to backend
    if (_pendingOrderId != null) {
      try {
        await ref.read(purchaseProvider.notifier).verifyPayment(
          orderId: _pendingOrderId!,
          paymentId: response.paymentId ?? '',
          signature: response.signature ?? '',
        );

        // Refresh orders list to show the new order
        await ref.read(orderProvider.notifier).loadOrders();

        if (mounted) {
          // Switch to My Orders tab
          ref.read(navigationProvider.notifier).state = 1;

          // Close the bottom sheet
          Navigator.pop(context);

          // Get the order that was just correctly verified
          final completedOrder = ref.read(purchaseProvider).completedOrder;
          
          if (completedOrder != null) {
            // Navigate to Order Details
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => OrderDetailScreen(order: completedOrder),
              ),
            );
          }

          // Show success snackbar
          messenger.showSnackBar(
            const SnackBar(
              content: Text('Payment Successful! Your gold is secured.'),
              behavior: SnackBarBehavior.floating,
              backgroundColor: AppColors.success,
            ),
          );
        }
      } catch (e) {
        setState(() => _isProcessing = false);
        if (mounted) {
          messenger.showSnackBar(
            SnackBar(
              content: Text('Verification failed: $e'),
              backgroundColor: AppColors.error,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    }
  }

  void _handlePaymentError(PaymentFailureResponse response) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Payment Failed: ${response.message}'),
          behavior: SnackBarBehavior.floating,
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  void _handleExternalWallet(ExternalWalletResponse response) {
    // Handle external wallet if needed
  }

  void _startPayment() async {
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
              const Text('Complete Profile', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              const Text(
                'Please complete your personal and bank details to proceed with gold purchases.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white70, fontSize: 14),
              ),
              const SizedBox(height: 24),
              GoldButton(
                text: 'GO TO PROFILE',
                onPressed: () {
                  Navigator.pop(context); // Close sheet
                  Navigator.pop(context); // Close checkout modal
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const ProfileScreen()),
                  );
                },
              ),
            ],
          ),
        ),
      );
      return;
    }

    final purchaseData = await ref.read(purchaseProvider.notifier).initiatePurchase(
      widget.product.id,
      _quantity,
      referralCode: widget.referralCode,
    );

    if (purchaseData == null && mounted) {
      final error = ref.read(purchaseProvider).error;
      _showErrorDialog(context, error ?? 'Unable to initiate purchase. Please try again.');
      return;
    }

    if (purchaseData != null) {
      setState(() {
        _pendingOrderId = purchaseData['orderId'];
      });

      try {
        final userData = ref.read(authProvider).user;
        debugPrint('Opening Razorpay for order: ${purchaseData['razorpayOrderId']}');
        
        var options = {
          'key': AppConstants.razorpayKeyId,
          'amount': (purchaseData['amount'] * 100).round(), // amount in paise
          'name': 'Royal Gold',
          'description': '${_quantity}x ${widget.product.name}',
          'order_id': purchaseData['razorpayOrderId'], // Provide Razorpay Order ID from backend
          'prefill': {
            'contact': userData?.phone ?? '',
            'email': userData?.email ?? '',
          },
          'theme': {
            'color': '#D4AF37' // Match our Champagne Gold primary theme
          }
        };

        _razorpay.open(options);
      } catch (e) {
        debugPrint('CRITICAL: Error opening Razorpay: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final pricing = widget.product.pricing;
    if (pricing == null) return const SizedBox.shrink();

    final totalAmount = pricing.total * _quantity;

    // Listen for errors and show snackbar
    ref.listen(purchaseProvider, (previous, next) {
      if (next.error != null && next.error != previous?.error) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error: ${next.error}'),
              backgroundColor: Colors.redAccent,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    });

    return AnimatedContainer(
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeOutQuart,
      padding: const EdgeInsets.only(left: 24, right: 24, top: 4, bottom: 24),
      decoration: BoxDecoration(
        color: const Color(0xFF0F0F1A),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(40)),
        boxShadow: [
          BoxShadow(
            color: AppColors.royalGold.withValues(alpha: 0.15),
            blurRadius: 50,
            spreadRadius: 10,
            offset: const Offset(0, -10),
          ),
        ],
        border: Border(
           top: BorderSide(color: AppColors.royalGold.withValues(alpha: 0.3), width: 2),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Drag Handle / Glow Line
          Center(
            child: Container(
              margin: const EdgeInsets.only(top: 12, bottom: 24),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.royalGold.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Precision Review',
                    style: TextStyle(
                      color: AppColors.royalGold.withValues(alpha: 0.7),
                      fontSize: 12,
                      letterSpacing: 2.5,
                      fontWeight: FontWeight.bold,
                    ),
                  ).animate().fadeIn(delay: 100.ms).slideY(begin: 0.3),
                  const Text(
                    'Finalize Order',
                    style: TextStyle(
                      color: Colors.white, 
                      fontSize: 28, 
                      fontWeight: FontWeight.w900,
                      letterSpacing: -0.5,
                    ),
                  ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.2),
                ],
              ),
              IconButton(
                onPressed: () => Navigator.pop(context), 
                icon: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.05),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.close, color: Colors.white70, size: 20),
                ),
              ),
            ],
          ),
          const SizedBox(height: 28),
          
          // Product Card (Mini)
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.03),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
              gradient: LinearGradient(
                colors: [Colors.white.withValues(alpha: 0.05), Colors.transparent],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Row(
              children: [
                Hero(
                  tag: 'product_image_${widget.product.id}',
                  child: Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      color: AppColors.royalGold.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(16),
                      image: widget.product.imageUrl != null ? DecorationImage(
                        image: NetworkImage(widget.product.imageUrl!),
                        fit: BoxFit.cover,
                      ) : null,
                    ),
                    child: widget.product.imageUrl == null ? Icon(Icons.token, color: AppColors.royalGold, size: 30) : null,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.product.name, 
                        style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${widget.product.weight}g • ${widget.product.purity} Fine Gold', 
                        style: TextStyle(color: AppColors.royalGold.withValues(alpha: 0.5), fontSize: 13, fontWeight: FontWeight.w500),
                      ),
                    ],
                  ),
                ),
                _QuantitySelector(
                  quantity: _quantity,
                  onChanged: (val) => setState(() => _quantity = val),
                ),
              ],
            ),
          ).animate().fadeIn(delay: 300.ms).scale(begin: const Offset(0.95, 0.95)),

          const SizedBox(height: 32),
          
          // Institutional Breakdown Section
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Column(
              children: [
                _PriceDetail(
                  icon: Icons.show_chart_rounded,
                  label: 'Market Gold Value', 
                  value: Formatters.currency(pricing.marketPrice * _quantity),
                  helperText: 'Base Rate: ₹${(pricing.marketPrice / pricing.weight).toStringAsFixed(2)}/g',
                ).animate().fadeIn(delay: 400.ms).slideX(begin: 0.1),
                
                _PriceDetail(
                  icon: Icons.local_offer_rounded,
                  label: 'Portfolio Discount', 
                  value: '- ${Formatters.currency(pricing.discountAmount * _quantity)}',
                  valueColor: Colors.greenAccent,
                  helperText: 'Special Reward: ${pricing.discountPercent}% OFF',
                ).animate().fadeIn(delay: 500.ms).slideX(begin: 0.1),

                _PriceDetail(
                  icon: Icons.account_balance_rounded,
                  label: 'Gold GST (IGST/CGST)', 
                  value: Formatters.currency(pricing.goldGst * _quantity),
                  helperText: 'Consolidated Tax: 3%',
                ).animate().fadeIn(delay: 600.ms).slideX(begin: 0.1),

                _PriceDetail(
                  icon: Icons.architecture_rounded,
                  label: 'Making Charge', 
                  value: Formatters.currency(pricing.makingCharges * _quantity),
                  helperText: 'Crafting Fee: 6% Markup',
                ).animate().fadeIn(delay: 700.ms).slideX(begin: 0.1),

                _PriceDetail(
                  icon: Icons.receipt_rounded,
                  label: 'GST on Making', 
                  value: Formatters.currency(pricing.makingGst * _quantity),
                  helperText: 'Service Tax: 5%',
                ).animate().fadeIn(delay: 800.ms).slideX(begin: 0.1),
                
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 20.0),
                  child: Divider(color: Colors.white12, thickness: 1),
                ).animate().fadeIn(delay: 900.ms),

                _PriceDetail(
                  icon: Icons.payments_rounded,
                  label: 'Final Total Payable', 
                  value: Formatters.currency(totalAmount), 
                  isTotal: true,
                ).animate().fadeIn(delay: 1000.ms).shimmer(duration: 2.seconds, color: Colors.white24),
              ],
            ),
          ),

          const SizedBox(height: 36),
          
          // Action Button
          SizedBox(
            width: double.infinity,
            height: 64,
            child: ElevatedButton(
              onPressed: ref.watch(purchaseProvider).isLoading ? null : _startPayment,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.royalGold,
                foregroundColor: Colors.black,
                elevation: 12,
                shadowColor: AppColors.royalGold.withValues(alpha: 0.4),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              ),
              child: ref.watch(purchaseProvider).isLoading 
                ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.black, strokeWidth: 3))
                : const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text('SECURE NOW', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18, letterSpacing: 1.5)),
                      SizedBox(width: 12),
                      Icon(Icons.arrow_forward_rounded, size: 20),
                    ],
                  ),
            ),
          ).animate().fadeIn(delay: 1100.ms).slideY(begin: 0.5),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  void _showErrorDialog(BuildContext context, String message) {
    bool isReferralError = message.toLowerCase().contains('referral') || 
                          message.toLowerCase().contains('own referral');
                          
    showDialog(
      context: context,
      builder: (ctx) => Center(
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 32),
          child: Material(
            color: Colors.transparent,
            child: GoldCard(
              hasGlow: true,
              hasGoldBorder: true,
              padding: const EdgeInsets.all(28),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                   Container(
                     padding: const EdgeInsets.all(16),
                     decoration: BoxDecoration(
                       color: (isReferralError ? AppColors.warning : AppColors.error).withValues(alpha: 0.1),
                       shape: BoxShape.circle,
                     ),
                     child: Icon(
                       isReferralError ? Icons.stars_rounded : Icons.error_outline_rounded,
                       color: isReferralError ? AppColors.royalGold : AppColors.error,
                       size: 40,
                     ),
                   ),
                   const SizedBox(height: 24),
                   Text(
                     isReferralError ? 'Referral Policy' : 'Action Required',
                     style: AppTextStyles.h3.copyWith(color: AppColors.pureWhite),
                     textAlign: TextAlign.center,
                   ),
                   const SizedBox(height: 12),
                   Text(
                     message.replaceAll('Exception:', '').trim(),
                     style: AppTextStyles.bodyMedium.copyWith(color: AppColors.pureWhite),
                     textAlign: TextAlign.center,
                   ),
                   const SizedBox(height: 32),
                   GoldButton(
                     text: 'UNDERSTOOD',
                     onPressed: () => Navigator.pop(ctx),
                     height: 52,
                   ),
                ],
              ),
            ),
          ),
        ),
      ).animate().scale(duration: 400.ms, curve: Curves.easeOutBack).fadeIn(),
    );
  }
}

class _QuantitySelector extends StatelessWidget {
  final int quantity;
  final Function(int) onChanged;

  const _QuantitySelector({required this.quantity, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _Btn(icon: Icons.remove, onTap: () => quantity > 1 ? onChanged(quantity - 1) : null),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Text('$quantity', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
          ),
          _Btn(icon: Icons.add, onTap: () => onChanged(quantity + 1)),
        ],
      ),
    );
  }
}

class _Btn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _Btn({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.all(10.0),
        child: Icon(icon, color: Colors.white, size: 18),
      ),
    );
  }
}

class _PriceDetail extends StatelessWidget {
  final String label;
  final String value;
  final String? helperText;
  final bool isTotal;
  final IconData? icon;
  final Color? valueColor;

  const _PriceDetail({
    required this.label, 
    required this.value, 
    this.helperText,
    this.isTotal = false,
    this.icon,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  if (icon != null) ...[
                    Icon(icon, color: isTotal ? AppColors.royalGold : Colors.white24, size: 18),
                    const SizedBox(width: 12),
                  ],
                  Text(
                    label, 
                    style: TextStyle(
                      color: isTotal ? Colors.white : Colors.white.withValues(alpha: 0.6), 
                      fontSize: isTotal ? 16 : 14, 
                      fontWeight: isTotal ? FontWeight.w700 : FontWeight.w500,
                      letterSpacing: 0.2,
                    )
                  ),
                ],
              ),
              Text(
                value, 
                style: TextStyle(
                  color: valueColor ?? (isTotal ? AppColors.royalGold : Colors.white), 
                  fontSize: isTotal ? 24 : 15, 
                  fontWeight: isTotal ? FontWeight.w900 : FontWeight.w700,
                  fontFamily: 'monospace',
                )
              ),
            ],
          ),
          if (helperText != null)
            Padding(
              padding: EdgeInsets.only(top: 4.0, left: icon != null ? 30 : 0),
              child: Text(
                helperText!,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.25),
                  fontSize: 11,
                  fontWeight: FontWeight.w400,
                  letterSpacing: 0.1,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
