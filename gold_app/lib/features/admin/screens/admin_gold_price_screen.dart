import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../widgets/gold_card.dart';
import '../../../widgets/gold_button.dart';
import '../../../widgets/gold_text_field.dart';
import '../providers/admin_provider.dart';
import '../../home/providers/home_provider.dart';
import '../../../core/network/api_service.dart';

class AdminGoldPriceScreen extends ConsumerStatefulWidget {
  const AdminGoldPriceScreen({super.key});

  @override
  ConsumerState<AdminGoldPriceScreen> createState() => _AdminGoldPriceScreenState();
}

class _AdminGoldPriceScreenState extends ConsumerState<AdminGoldPriceScreen> {
  double? _buyPrice;
  double? _sellPrice;
  bool _isLoadingPrices = true;

  @override
  void initState() {
    super.initState();
    _fetchCurrentPrices();
  }

  Future<void> _fetchCurrentPrices() async {
    setState(() => _isLoadingPrices = true);
    try {
      final response = await ApiService().getGoldPrice();
      if (response.statusCode == 200) {
        final data = response.data['data'];
        setState(() {
          _buyPrice = _toDouble(data['buyPrice']);
          _sellPrice = _toDouble(data['livePrice']);
          _isLoadingPrices = false;
        });
      }
    } catch (e) {
      setState(() => _isLoadingPrices = false);
    }
  }

  double _toDouble(dynamic v) => double.tryParse(v.toString()) ?? 0.0;

  Future<void> _triggerSync() async {
    final messenger = ScaffoldMessenger.of(context);
    final success = await ref.read(adminProvider.notifier).updateGoldPrice(0, 0); // Backend ignores input and syncs
    
    if (mounted) {
      if (success) {
        await _fetchCurrentPrices();
        ref.read(homeProvider.notifier).loadDashboard();
        messenger.showSnackBar(
          const SnackBar(
            content: Text('Live rates synced with Binance successfully'),
            backgroundColor: AppColors.success,
            behavior: SnackBarBehavior.floating,
          ),
        );
      } else {
        messenger.showSnackBar(
          SnackBar(
            content: Text(ref.read(adminProvider).error ?? 'Sync service unavailable'),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('MARKET SYNC', style: AppTextStyles.labelLarge.copyWith(letterSpacing: 2)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        iconTheme: IconThemeData(color: AppColors.royalGold),
      ),
      body: Container(
        decoration: BoxDecoration(color: AppColors.background),
        child: _isLoadingPrices 
          ? Center(child: CircularProgressIndicator(color: AppColors.royalGold))
          : RefreshIndicator(
              onRefresh: _fetchCurrentPrices,
              color: AppColors.royalGold,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('CURRENT SPOT RATES (PER GRAM)', style: AppTextStyles.labelLarge.copyWith(color: AppColors.royalGold.withValues(alpha: 0.7))),
                    const SizedBox(height: 16),
                    GoldCard(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          children: [
                            _RateRow(
                              label: 'LIVE SELL RATE (CUST. BUYS)',
                              value: _sellPrice ?? 0.0,
                              icon: Icons.trending_up_rounded,
                              color: AppColors.success,
                            ),
                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: 20),
                              child: Divider(color: AppColors.pureWhite.withValues(alpha: 0.05)),
                            ),
                            _RateRow(
                              label: 'LIVE BUY RATE (CUST. SELLS)',
                              value: _buyPrice ?? 0.0,
                              icon: Icons.trending_down_rounded,
                              color: AppColors.royalGold,
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 32),
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: AppColors.royalGold.withValues(alpha: 0.05),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppColors.royalGold.withValues(alpha: 0.1)),
                      ),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: AppColors.royalGold.withValues(alpha: 0.1),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(Icons.auto_awesome, color: AppColors.royalGold, size: 20),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Text(
                                  'Automated Pricing Active',
                                  style: AppTextStyles.labelLarge.copyWith(color: AppColors.pureWhite),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'Prices are automatically updated every 2 hours using Binance PAXG/USDT spot rates and institutional exchange formulas. Manual sync forces an immediate refresh.',
                            style: AppTextStyles.caption.copyWith(color: AppColors.pureWhite.withValues(alpha: 0.5), height: 1.5),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 48),
                    GoldButton(
                      text: 'SYNC LIVE MARKET RATES',
                      icon: Icons.sync_rounded,
                      isLoading: ref.watch(adminProvider).isLoading,
                      onPressed: ref.watch(adminProvider).isLoading ? null : _triggerSync,
                    ),
                    const SizedBox(height: 20),
                    Center(
                      child: TextButton.icon(
                        onPressed: _fetchCurrentPrices,
                        icon: Icon(Icons.refresh, size: 16, color: AppColors.royalGold.withValues(alpha: 0.5)),
                        label: Text('REFRESH VIEW', style: AppTextStyles.caption.copyWith(color: AppColors.royalGold.withValues(alpha: 0.5))),
                      ),
                    ),
                  ],
                ),
              ),
            ),
      ),
    );
  }
}

class _RateRow extends StatelessWidget {
  final String label;
  final double value;
  final IconData icon;
  final Color color;

  const _RateRow({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: AppTextStyles.caption.copyWith(letterSpacing: 1)),
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(icon, size: 16, color: color),
                const SizedBox(width: 8),
                Text(
                  '₹${value.toStringAsFixed(2)}',
                  style: AppTextStyles.h3.copyWith(color: AppColors.pureWhite, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ],
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            'LIVE',
            style: AppTextStyles.caption.copyWith(color: color, fontWeight: FontWeight.bold, fontSize: 10),
          ),
        ),
      ],
    );
  }
}
