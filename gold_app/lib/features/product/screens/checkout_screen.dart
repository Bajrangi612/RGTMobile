import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/utils/extensions.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/services/mock_data_service.dart';
import '../../../core/network/api_service.dart';
import '../../../widgets/gold_button.dart';
import '../../../widgets/gold_card.dart';
import '../../../widgets/gold_app_bar.dart';
import '../data/models/product_model.dart';
import '../../order/screens/orders_screen.dart';
import '../../order/providers/order_provider.dart';
import '../../home/screens/home_screen.dart';

import '../../../core/services/invoice_service.dart';

class CheckoutScreen extends ConsumerStatefulWidget {
  final ProductModel product;
  final int quantity;
  final String referralCode;

  CheckoutScreen({
    super.key,
    required this.product,
    required this.quantity,
    required this.referralCode,
  }) ;

  @override
  ConsumerState<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends ConsumerState<CheckoutScreen> {
  String _selectedPayment = 'UPI';
  bool _isProcessing = false;
  bool _orderPlaced = false;
  Map<String, dynamic>? _invoiceDetails;

  @override
  void initState() {
    super.initState();
    _calculateTotals();
  }

  void _calculateTotals() {
    _invoiceDetails = InvoiceService.calculateInvoiceDetails(
      basePrice: widget.product.price,
      weight: widget.product.weight * widget.quantity,
    );
  }

  double get _subtotal => _invoiceDetails!['subtotal'];
  double get _gstAmount => _invoiceDetails!['gstAmount'];
  double get _referralDiscount => widget.referralCode.isNotEmpty ? AppConstants.referralCommission : 0;
  double get _total => (_invoiceDetails!['totalAmount'] as double) - _referralDiscount;

  Future<void> _placeOrder() async {
    setState(() => _isProcessing = true);
    try {
      final response = await ApiService().post('/gold-advances', data: {
        'amount': _total,
      });

      if (response.statusCode == 201) {
        setState(() {
          _isProcessing = false;
          _orderPlaced = true;
          _invoiceDetails = {
            ..._invoiceDetails!,
            'invoiceNumber': response.data['invoiceNo'].toString(),
          };
        });
        // Refresh orders list
        ref.read(orderProvider.notifier).loadOrders();
      } else {
        throw Exception(response.data['error'] ?? 'Failed to place order');
      }
    } catch (e) {
      setState(() => _isProcessing = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString()), backgroundColor: AppColors.error),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_orderPlaced) {
      return _OrderSuccessView(
        orderId: MockDataService.generateOrderId(),
        amount: _total,
        invoiceDetails: _invoiceDetails!,
      );
    }

    return Scaffold(
      backgroundColor: AppColors.deepBlack,
      appBar:  GoldAppBar(title: 'Checkout'),
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
                    // Order Summary
                    GoldCard(
                      hasGoldBorder: true,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Order Summary', style: AppTextStyles.h4),
                          SizedBox(height: 16),
                          Row(
                            children: [
                              Container(
                                width: 56,
                                height: 56,
                                decoration: BoxDecoration(
                                  color: AppColors.royalGold.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Icon(Icons.monetization_on_rounded, color: AppColors.royalGold, size: 32),
                              ),
                              SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(widget.product.name, style: AppTextStyles.labelLarge),
                                    Text(
                                      '${widget.product.purity} · ${widget.product.weight.toInt()}g × ${widget.quantity}',
                                      style: AppTextStyles.bodySmall,
                                    ),
                                  ],
                                ),
                              ),
                              Text(Formatters.currency(_subtotal), style: AppTextStyles.priceTag.copyWith(fontSize: 18)),
                            ],
                          ),
                        ],
                      ),
                    ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.05),

                    SizedBox(height: 16),

                    // Price Breakdown
                    GoldCard(
                      child: Column(
                        children: [
                          _PriceRow('Subtotal', Formatters.currency(_subtotal)),
                          const SizedBox(height: 8),
                          _PriceRow('GST (3%)', Formatters.currency(_gstAmount)),
                          if (_referralDiscount > 0) ...[
                            const SizedBox(height: 8),
                            _PriceRow(
                              'Referral Discount',
                              '-${Formatters.currency(_referralDiscount)}',
                              valueColor: AppColors.success,
                            ),
                          ],
                          Divider(height: 24, color: AppColors.darkGrey),
                          _PriceRow(
                            'Total Amount',
                            Formatters.currency(_total),
                            isTotal: true,
                          ),
                        ],
                      ),
                    ).animate(delay: 200.ms).fadeIn(duration: 400.ms),

                    if (widget.referralCode.isNotEmpty) ...[
                      SizedBox(height: 16),
                      GoldCard(
                        padding: const EdgeInsets.all(14),
                        child: Row(
                          children: [
                            Icon(Icons.card_giftcard, color: AppColors.success, size: 20),
                            SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                'Referral code ${widget.referralCode} applied',
                                style: AppTextStyles.bodySmall.copyWith(color: AppColors.success),
                              ),
                            ),
                            Icon(Icons.check_circle, color: AppColors.success, size: 18),
                          ],
                        ),
                      ).animate(delay: 250.ms).fadeIn(duration: 300.ms),
                    ],

                    SizedBox(height: 24),

                    // Payment Method
                    Text('Payment Method', style: AppTextStyles.h4),
                    SizedBox(height: 12),
                    _PaymentOption(
                      title: 'UPI',
                      subtitle: 'Google Pay, PhonePe, Paytm',
                      icon: Icons.qr_code_2,
                      isSelected: _selectedPayment == 'UPI',
                      onTap: () => setState(() => _selectedPayment = 'UPI'),
                    ),
                    SizedBox(height: 8),
                    _PaymentOption(
                      title: 'Bank Transfer',
                      subtitle: 'NEFT / IMPS',
                      icon: Icons.account_balance,
                      isSelected: _selectedPayment == 'Bank Transfer',
                      onTap: () => setState(() => _selectedPayment = 'Bank Transfer'),
                    ),
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
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Total:', style: AppTextStyles.bodyMedium),
                        Text(Formatters.currency(_total), style: AppTextStyles.goldPrice.copyWith(fontSize: 24)),
                      ],
                    ),
                    SizedBox(height: 12),
                    GoldButton(
                      text: 'Place Order',
                      isLoading: _isProcessing,
                      onPressed: _isProcessing ? null : _placeOrder,
                      icon: Icons.lock,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    ) ;
  }
}

class _PriceRow extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;
  final bool isTotal;

  const _PriceRow(this.label, this.value, {this.valueColor, this.isTotal = false});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: isTotal ? AppTextStyles.labelLarge : AppTextStyles.bodyMedium),
        Text(
          value,
          style: isTotal
              ? AppTextStyles.priceTag
              : AppTextStyles.bodyMedium.copyWith(color: valueColor ?? AppColors.pureWhite),
        ),
      ],
    );
  }
}

class _PaymentOption extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  const _PaymentOption({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: Duration(milliseconds: 200),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.royalGold.withOpacity(0.08) : AppColors.cardDark,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected ? AppColors.royalGold : AppColors.glassBorder,
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(icon, color: isSelected ? AppColors.royalGold : AppColors.grey, size: 24),
            SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: AppTextStyles.labelLarge),
                  Text(subtitle, style: AppTextStyles.caption),
                ],
              ),
            ),
            Container(
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected ? AppColors.royalGold : AppColors.darkGrey,
                  width: 2,
                ),
                color: isSelected ? AppColors.royalGold : Colors.transparent,
              ),
              child: isSelected
                  ? Icon(Icons.check, color: AppColors.deepBlack, size: 14)
                  : null,
            ),
          ],
        ),
      ),
    );
  }
}

class _OrderSuccessView extends StatelessWidget {
  final String orderId;
  final double amount;
  final Map<String, dynamic> invoiceDetails;

  const _OrderSuccessView({
    required this.orderId, 
    required this.amount,
    required this.invoiceDetails,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.deepBlack,
      body: Container(
        decoration: BoxDecoration(gradient: AppColors.darkGradient),
        child: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.success.withOpacity(0.15),
                      border: Border.all(color: AppColors.success.withOpacity(0.3)),
                    ),
                    child: Icon(Icons.check_circle, color: AppColors.success, size: 56),
                  ).animate().scale(duration: 500.ms, curve: Curves.elasticOut),

                  SizedBox(height: 32),
                  Text('Order Placed!', style: AppTextStyles.h2)
                      .animate(delay: 200.ms).fadeIn(),
                  SizedBox(height: 8),
                  Text(
                    'Your gold coin order has been confirmed',
                    style: AppTextStyles.bodyMedium.copyWith(color: AppColors.grey),
                    textAlign: TextAlign.center,
                  ).animate(delay: 300.ms).fadeIn(),

                  SizedBox(height: 32),

                  GoldCard(
                    hasGoldBorder: true,
                    child: Column(
                      children: [
                        _SuccessRow('Order ID', orderId),
                        const SizedBox(height: 8),
                        _SuccessRow('Invoice #', invoiceDetails['invoiceNumber']),
                        const SizedBox(height: 8),
                        _SuccessRow('Total (Incl. 3% GST)', Formatters.currency(amount)),
                        const SizedBox(height: 8),
                        _SuccessRow('Delivery', '5-7 Business Days'),
                      ],
                    ),
                  ).animate(delay: 400.ms).fadeIn().slideY(begin: 0.1),

                  SizedBox(height: 24),
                  
                  OutlinedButton.icon(
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Invoice ${invoiceDetails['invoiceNumber']} downloaded'),
                          backgroundColor: AppColors.success,
                        ),
                      );
                    },
                    icon: Icon(Icons.download, color: AppColors.royalGold),
                    label: Text('DOWNLOAD INVOICE', style: AppTextStyles.labelMedium.copyWith(color: AppColors.royalGold)),
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: AppColors.royalGold),
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    ),
                  ).animate(delay: 450.ms).fadeIn(),

                  SizedBox(height: 40),

                  GoldButton(
                    text: 'Go to Home',
                    onPressed: () {
                      Navigator.of(context).pushAndRemoveUntil(
                        MaterialPageRoute(builder: (_) =>  HomeScreen()),
                        (route) => false,
                      ) ;
                    },
                    icon: Icons.home_rounded,
                  ).animate(delay: 500.ms).fadeIn(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _SuccessRow extends StatelessWidget {
  final String label;
  final String value;

  const _SuccessRow(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: AppTextStyles.bodySmall),
        Text(value, style: AppTextStyles.labelLarge),
      ],
    );
  }
}
