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
import '../data/models/order_model.dart';
import '../providers/order_provider.dart';
import '../../home/providers/home_provider.dart';
import '../../home/screens/home_screen.dart';

class SellBackScreen extends ConsumerStatefulWidget {
  final OrderModel order;

  const SellBackScreen({super.key, required this.order});

  @override
  ConsumerState<SellBackScreen> createState() => _SellBackScreenState();
}

class _SellBackScreenState extends ConsumerState<SellBackScreen> {
  int _step = 0; // 0: passkey, 1: confirm, 2: success
  String _passKey = '';
  bool _isVerifying = false;
  double _currentPrice = 0;
  double _sellBackAmount = 0;

  @override
  void initState() {
    super.initState();
    final homeState = ref.read(homeProvider);
    _currentPrice = homeState.buyPrice > 0 ? homeState.buyPrice : 7200.0;
    _sellBackAmount = _currentPrice * widget.order.weight;
  }

  Future<void> _verifyPassKey() async {
    // Note: Passkey length is usually 6 in this app
    if (_passKey.length < 4) return;
    setState(() => _isVerifying = true);
    await Future.delayed(const Duration(milliseconds: 800));
    setState(() {
      _isVerifying = false;
      _step = 1;
    });
  }

  Future<void> _confirmSellBack() async {
    setState(() => _isVerifying = true);
    final success = await ref.read(orderProvider.notifier).sellBackOrder(widget.order.id);
    setState(() {
      _isVerifying = false;
      if (success) {
        _step = 2;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.deepBlack,
      appBar: _step != 2 ?  GoldAppBar(title: 'Sell back to Store') : null,
      body: Container(
        decoration: BoxDecoration(gradient: AppColors.darkGradient),
        child: _buildStep(),
      ),
    ) ;
  }

  Widget _buildStep() {
    switch (_step) {
      case 0:
        return _buildPassKeyStep();
      case 1:
        return _buildConfirmStep();
      case 2:
        return _buildSuccessStep();
      default:
        return SizedBox();
    }
  }

  Widget _buildPassKeyStep() {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Spacer(),
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: AppColors.royalGold.withValues(alpha: 0.1),
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.royalGold.withValues(alpha: 0.3)),
              ),
              child: Icon(Icons.lock_rounded, size: 40, color: AppColors.royalGold),
            ).animate().scale(duration: 500.ms, curve: Curves.elasticOut),
            SizedBox(height: 24),
            Text('Enter Passkey', style: AppTextStyles.h3).animate(delay: 200.ms).fadeIn(),
            SizedBox(height: 8),
            const SizedBox(height: 40), // Placeholder for actual passkey fields
            GoldButton(
              text: 'Verify',
              isLoading: _isVerifying,
              onPressed: () => _verifyPassKey(),
            ).animate(delay: 500.ms).fadeIn(),
            Spacer(flex: 2),
          ],
        ),
      ),
    ) ;
  }

  Widget _buildConfirmStep() {
    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                GoldCard(
                  isVibrant: true,
                  gradient: const LinearGradient(
                    colors: [Color(0xFF1A1F3D), Color(0xFF2E376E)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  child: Column(
                    children: [
                      Text('Buyback Summary', style: AppTextStyles.h4),
                      SizedBox(height: 20),
                      _SellBackRow('Product', widget.order.productName),
                      _SellBackRow('Weight', '${widget.order.weight}g'),
                      _SellBackRow('Original Price', Formatters.currency(widget.order.price)),
                      _SellBackRow('Current Buy Rate/g', Formatters.currencyPrecise(_currentPrice)),
                      Divider(height: 24, color: AppColors.pureWhite.withValues(alpha: 0.1)),
                      _SellBackRow('Estimated Payout', Formatters.currency(_sellBackAmount)),
                      const SizedBox(height: 20),
                    ],
                  ),
                ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.05),
                SizedBox(height: 16),
                GoldCard(
                  padding: const EdgeInsets.all(14),
                  child: Row(
                    children: [
                      Icon(Icons.info_outline_rounded, color: AppColors.royalGold, size: 20),
                      SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Your request will be sent to the administrator for review. Once approved, the amount will be processed to your bank account.',
                          style: AppTextStyles.bodySmall,
                        ),
                      ),
                    ],
                  ),
                ).animate(delay: 200.ms).fadeIn(),
              ],
            ),
          ),
        ),
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: AppColors.deepBlack.withValues(alpha: 0.95),
            border: Border(top: BorderSide(color: AppColors.pureWhite.withValues(alpha: 0.05))),
          ),
          child: SafeArea(
            child: GoldButton(
              text: 'Submit Buyback Request',
              isLoading: _isVerifying,
              onPressed: _isVerifying ? null : _confirmSellBack,
              icon: Icons.send_rounded,
            ),
          ),
        ),
      ],
    ) ;
  }

  Widget _buildSuccessStep() {
    return SafeArea(
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
                  color: AppColors.success.withValues(alpha: 0.15),
                  border: Border.all(color: AppColors.success.withValues(alpha: 0.3)),
                ),
                child: Icon(Icons.check_circle_outline_rounded, color: AppColors.success, size: 56),
              ).animate().scale(duration: 500.ms, curve: Curves.elasticOut),
              SizedBox(height: 32),
              Text('Request Submitted!', style: AppTextStyles.h2).animate(delay: 200.ms).fadeIn(),
              SizedBox(height: 8),
              Text(
                'Your buyback request for ${Formatters.currency(_sellBackAmount)} has been sent for approval. You can track the status in your order history.',
                style: AppTextStyles.bodyMedium.copyWith(color: AppColors.grey),
                textAlign: TextAlign.center,
              ).animate(delay: 300.ms).fadeIn(),
              SizedBox(height: 40),
              GoldButton(
                text: 'Go to Dashboard',
                onPressed: () => Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (_) =>  HomeScreen()),
                  (route) => false,
                ),
                icon: Icons.dashboard_rounded,
              ).animate(delay: 400.ms).fadeIn(),
            ],
          ),
        ),
      ),
    ) ;
  }
}

class _SellBackRow extends StatelessWidget {
  final String label;
  final String value;

  const _SellBackRow(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: AppTextStyles.bodySmall.copyWith(color: Colors.white70)),
          Text(value, style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}
