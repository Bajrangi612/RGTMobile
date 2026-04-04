import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';
import '../providers/product_providers.dart';
import '../../data/models/product_model.dart';
import '../../../../core/theme/app_colors.dart';

class CheckoutSheet extends ConsumerStatefulWidget {
  final ProductModel product;

  const CheckoutSheet({super.key, required this.product});

  @override
  ConsumerState<CheckoutSheet> createState() => _CheckoutSheetState();
}

class _CheckoutSheetState extends ConsumerState<CheckoutSheet> {
  late Razorpay _razorpay;
  int _quantity = 1;
  String? _pendingOrderId;

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
    _razorpay.clear();
    super.dispose();
  }

  void _handlePaymentSuccess(PaymentSuccessResponse response) async {
    if (_pendingOrderId != null) {
      await ref.read(purchaseProvider.notifier).verifyPayment(
        orderId: _pendingOrderId!,
        razorpayOrderId: response.orderId!,
        razorpayPaymentId: response.paymentId!,
        razorpaySignature: response.signature!,
      );

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Payment Successful! Your gold is secured.')),
        );
      }
    }
  }

  void _handlePaymentError(PaymentFailureResponse response) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Payment Failed: ${response.message}')),
      );
    }
  }

  void _handleExternalWallet(ExternalWalletResponse response) {
    // Handle external wallet
  }

  void _startPayment() async {
    final purchaseData = await ref.read(purchaseProvider.notifier).initiatePurchase(
      widget.product.id,
      _quantity,
    );

    if (purchaseData != null) {
      setState(() {
        _pendingOrderId = purchaseData['orderId'];
      });
      
      final options = {
        'key': purchaseData['razorpayKeyId'],
        'amount': purchaseData['amount'] * 100, // Amount in paise
        'name': 'Royal Gold Traders',
        'order_id': purchaseData['razorpayOrderId'],
        'description': 'Purchase of ${widget.product.name} (Qty: $_quantity)',
        'timeout': 300, // 5 minutes
        'prefill': {
          'contact': '', 
          'email': '',
        },
        'theme': {
          'color': '#D4AF37'
        }
      };

      try {
        _razorpay.open(options);
      } catch (e) {
        debugPrint('Error: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final pricing = widget.product.pricing;
    if (pricing == null) return const SizedBox.shrink();

    final totalAmount = pricing.total * _quantity;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: const BoxDecoration(
        color: Color(0xFF1A1A1A),
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
        border: Border(
           top: BorderSide(color: Color(0xFFD4AF37), width: 1.5),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Review Order',
                style: TextStyle(
                  color: Colors.white, 
                  fontSize: 24, 
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                ),
              ),
              IconButton(
                onPressed: () => Navigator.pop(context), 
                icon: const Icon(Icons.close, color: Colors.white60),
              ),
            ],
          ),
          const SizedBox(height: 24),
          
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.05),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.product.name, 
                        style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${widget.product.purity} Gold Coin', 
                        style: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 13),
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
          ),

          const SizedBox(height: 24),
          _PriceDetail(label: 'Price per gram', value: '₹${pricing.goldValue / widget.product.weight}'),
          _PriceDetail(label: 'Base Amount (${_quantity}x)', value: '₹${pricing.goldValue * _quantity}'),
          _PriceDetail(label: 'GST (3%)', value: '₹${(pricing.gstAmount * _quantity).toStringAsFixed(2)}'),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 16.0),
            child: Divider(color: Colors.white12, thickness: 1),
          ),
          _PriceDetail(
            label: 'Total Payable', 
            value: '₹${totalAmount.toStringAsFixed(2)}', 
            isTotal: true,
          ),

          const SizedBox(height: 32),
          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton(
              onPressed: ref.watch(purchaseProvider).isLoading ? null : _startPayment,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.royalGold,
                foregroundColor: Colors.black,
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              child: ref.watch(purchaseProvider).isLoading 
                ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.black, strokeWidth: 2))
                : const Text('PROCEED TO PAY', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16, letterSpacing: 1)),
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
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
        color: Colors.black.withOpacity(0.24),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white10),
      ),
      child: Row(
        children: [
          _Btn(icon: Icons.remove, onTap: () => quantity > 1 ? onChanged(quantity - 1) : null),
          Container(
            width: 40,
            alignment: Alignment.center,
            child: Text('$quantity', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
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
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Icon(icon, color: Colors.white70, size: 20),
      ),
    );
  }
}

class _PriceDetail extends StatelessWidget {
  final String label;
  final String value;
  final bool isTotal;
  const _PriceDetail({required this.label, required this.value, this.isTotal = false});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: isTotal ? Colors.white : Colors.white.withOpacity(0.5), fontSize: isTotal ? 16 : 14, fontWeight: isTotal ? FontWeight.w600 : FontWeight.normal)),
          Text(value, style: TextStyle(color: isTotal ? AppColors.royalGold : Colors.white, fontSize: isTotal ? 22 : 14, fontWeight: isTotal ? FontWeight.w900 : FontWeight.w600)),
        ],
      ),
    );
  }
}
