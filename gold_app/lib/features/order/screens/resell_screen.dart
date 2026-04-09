import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:pin_code_fields/pin_code_fields.dart';
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

class ResellScreen extends ConsumerStatefulWidget {
  final OrderModel order;

  const ResellScreen({super.key, required this.order});

  @override
  ConsumerState<ResellScreen> createState() => _ResellScreenState();
}

class _ResellScreenState extends ConsumerState<ResellScreen> {
  int _step = 0; // 0: passkey, 1: confirm, 2: success
  String _passKey = '';
  bool _isVerifying = false;
  double _currentPrice = 0;
  double _resellAmount = 0;

  @override
  void initState() {
    super.initState();
    final homeState = ref.read(homeProvider);
    _currentPrice = homeState.buyPrice > 0 ? homeState.buyPrice : 7200.0;
    _resellAmount = _currentPrice * widget.order.weight;
  }

  Future<void> _verifyPassKey() async {
    if (_passKey.length != AppConstants.passKeyLength) return;
    setState(() => _isVerifying = true);
    // In production, you would verify this passkey via backend
    await Future.delayed(const Duration(milliseconds: 800));
    setState(() {
      _isVerifying = false;
      _step = 1;
    });
  }

  Future<void> _confirmResell() async {
    setState(() => _isVerifying = true);
    final success = await ref.read(orderProvider.notifier).resellOrder(widget.order.id);
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
      appBar: _step != 2 ?  GoldAppBar(title: 'Resell Gold') : null,
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
            Text(
              'Verify your identity to proceed with resell',
              style: AppTextStyles.bodySmall,
              textAlign: TextAlign.center,
            ).animate(delay: 300.ms).fadeIn(),
            SizedBox(height: 40),
            PinCodeTextField(
              appContext: context,
              length: AppConstants.passKeyLength,
              obscureText: true,
              obscuringCharacter: '●',
              animationType: AnimationType.scale,
              keyboardType: TextInputType.number,
              textStyle: TextStyle(color: AppColors.pureWhite, fontSize: 24, fontWeight: FontWeight.w700),
              pinTheme: PinTheme(
                shape: PinCodeFieldShape.box,
                borderRadius: BorderRadius.circular(14),
                fieldHeight: 60,
                fieldWidth: 60,
                activeFillColor: AppColors.cardDarkAlt,
                inactiveFillColor: AppColors.cardDark,
                selectedFillColor: AppColors.cardDarkAlt,
                activeColor: AppColors.royalGold,
                inactiveColor: AppColors.darkGrey,
                selectedColor: AppColors.royalGold,
                borderWidth: 1.5,
              ),
              enableActiveFill: true,
              cursorColor: AppColors.royalGold,
              onChanged: (value) => setState(() => _passKey = value),
              onCompleted: (_) => _verifyPassKey(),
            ).animate(delay: 400.ms).fadeIn(duration: 500.ms),
            SizedBox(height: 24),
            GoldButton(
              text: 'Verify',
              isLoading: _isVerifying,
              onPressed: _passKey.length == AppConstants.passKeyLength && !_isVerifying ? _verifyPassKey : null,
            ).animate(delay: 500.ms).fadeIn(),
            Spacer(flex: 2),
          ],
        ),
      ),
    ) ;
  }

  Widget _buildConfirmStep() {
    final profitLoss = _resellAmount - widget.order.price;
    final isProfit = profitLoss >= 0;

    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                GoldCard(
                  hasGoldBorder: true,
                  hasGlow: true,
                  child: Column(
                    children: [
                      Text('Resell Summary', style: AppTextStyles.h4),
                      SizedBox(height: 20),
                      _ResellRow('Product', widget.order.productName),
                      _ResellRow('Weight', '${widget.order.weight.toInt()}g'),
                      _ResellRow('Buy Price', Formatters.currency(widget.order.price)),
                      _ResellRow('Current Price/g', Formatters.currencyPrecise(_currentPrice)),
                      Divider(height: 24, color: AppColors.darkGrey),
                      _ResellRow('Resell Amount', Formatters.currency(_resellAmount)),
                      SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: (isProfit ? AppColors.success : AppColors.error).withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              isProfit ? Icons.trending_up : Icons.trending_down,
                              color: isProfit ? AppColors.success : AppColors.error,
                              size: 18,
                            ),
                            SizedBox(width: 8),
                            Text(
                              '${isProfit ? 'Profit' : 'Loss'}: ${Formatters.currency(profitLoss.abs())}',
                              style: AppTextStyles.labelLarge.copyWith(
                                color: isProfit ? AppColors.success : AppColors.error,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.05),
                SizedBox(height: 16),
                GoldCard(
                  padding: const EdgeInsets.all(14),
                  child: Row(
                    children: [
                      Icon(Icons.account_balance, color: AppColors.royalGold, size: 20),
                      SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Amount will be transferred to your linked bank account',
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
            color: AppColors.charcoal.withValues(alpha: 0.95),
            border: Border(top: BorderSide(color: AppColors.glassBorder)),
          ),
          child: SafeArea(
            child: GoldButton(
              text: 'Confirm Resell',
              isLoading: _isVerifying,
              onPressed: _isVerifying ? null : _confirmResell,
              icon: Icons.sell_rounded,
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
                child: Icon(Icons.check_circle, color: AppColors.success, size: 56),
              ).animate().scale(duration: 500.ms, curve: Curves.elasticOut),
              SizedBox(height: 32),
              Text('Resell Successful!', style: AppTextStyles.h2).animate(delay: 200.ms).fadeIn(),
              SizedBox(height: 8),
              Text(
                '${Formatters.currency(_resellAmount)} will be credited to your bank account within 24 hours',
                style: AppTextStyles.bodyMedium.copyWith(color: AppColors.grey),
                textAlign: TextAlign.center,
              ).animate(delay: 300.ms).fadeIn(),
              SizedBox(height: 40),
              GoldButton(
                text: 'Go to Home',
                onPressed: () => Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (_) =>  HomeScreen()),
                  (route) => false,
                ),
                icon: Icons.home_rounded,
              ).animate(delay: 400.ms).fadeIn(),
            ],
          ),
        ),
      ),
    ) ;
  }
}

class _ResellRow extends StatelessWidget {
  final String label;
  final String value;

  const _ResellRow(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: AppTextStyles.bodySmall),
          Text(value, style: AppTextStyles.bodyMedium),
        ],
      ),
    );
  }
}
