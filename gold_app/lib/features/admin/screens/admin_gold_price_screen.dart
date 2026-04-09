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
  final _buyPriceController = TextEditingController();
  final _sellPriceController = TextEditingController();
  bool _isLoadingPrices = true;

  @override
  void initState() {
    super.initState();
    _fetchCurrentPrices();
  }

  Future<void> _fetchCurrentPrices() async {
    try {
      final response = await ApiService().getGoldPrice();
      if (response.statusCode == 200) {
        final data = response.data['data'];
        setState(() {
          _buyPriceController.text = data['buyPrice'].toString();
          _sellPriceController.text = data['livePrice'].toString();
          _isLoadingPrices = false;
        });
      }
    } catch (e) {
      setState(() {
        _isLoadingPrices = false;
      });
    }
  }

  @override
  void dispose() {
    _buyPriceController.dispose();
    _sellPriceController.dispose();
    super.dispose();
  }

  Future<void> _savePrices() async {
    final buyPrice = double.tryParse(_buyPriceController.text);
    final sellPrice = double.tryParse(_sellPriceController.text);

    if (buyPrice == null || sellPrice == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter valid numeric values')),
      );
      return;
    }

    final messenger = ScaffoldMessenger.of(context);
    final success = await ref.read(adminProvider.notifier).updateGoldPrice(buyPrice, sellPrice);
    
    if (mounted) {
      if (success) {
        ref.read(homeProvider.notifier).loadDashboard(); // Refresh global ticker
        messenger.showSnackBar(
          const SnackBar(
            content: Text('Gold prices updated successfully'),
            backgroundColor: AppColors.success,
            behavior: SnackBarBehavior.floating,
          ),
        );
        Navigator.of(context).pop();
      } else {
        messenger.showSnackBar(
          SnackBar(
            content: Text(ref.read(adminProvider).error ?? 'Failed to update prices'),
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
        title: Text('SET GOLD PRICE', style: AppTextStyles.labelLarge.copyWith(letterSpacing: 2)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        iconTheme: IconThemeData(color: AppColors.royalGold),
      ),
      body: Container(
        decoration: BoxDecoration(color: AppColors.background),
        child: _isLoadingPrices 
          ? Center(child: CircularProgressIndicator(color: AppColors.royalGold))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('MARKET RATES (PER GRAM)', style: AppTextStyles.labelLarge.copyWith(color: AppColors.royalGold.withValues(alpha: 0.7))),
                  const SizedBox(height: 16),
                  GoldCard(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        children: [
                          GoldTextField(
                            label: 'BUY PRICE (CUSTOMER SELLS TO US)',
                            controller: _buyPriceController,
                            keyboardType: TextInputType.number,
                            hint: 'e.g., 7250.00',
                            prefixIcon: Icon(Icons.arrow_downward),
                          ),
                          const SizedBox(height: 24),
                          GoldTextField(
                            label: 'SELL PRICE (CUSTOMER BUYS FROM US)',
                            controller: _sellPriceController,
                            keyboardType: TextInputType.number,
                            hint: 'e.g., 7500.00',
                            prefixIcon: Icon(Icons.arrow_upward),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.royalGold.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.royalGold.withValues(alpha: 0.1)),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.info_outline, color: AppColors.royalGold, size: 20),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Updating these prices will immediately recalculate all product prices and live tickers across the entire platform.',
                            style: AppTextStyles.caption.copyWith(color: AppColors.pureWhite.withValues(alpha: 0.6)),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 48),
                  GoldButton(
                    text: 'UPDATE MARKET RATES',
                    isLoading: ref.watch(adminProvider).isLoading,
                    onPressed: ref.watch(adminProvider).isLoading ? null : _savePrices,
                  ),
                ],
              ),
            ),
      ),
    );
  }
}
