import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../widgets/gold_card.dart';
import '../../../widgets/gold_button.dart';
import '../../../widgets/gold_text_field.dart';
import '../providers/admin_provider.dart';

class AdminConfigScreen extends ConsumerStatefulWidget {
  const AdminConfigScreen({super.key});

  @override
  ConsumerState<AdminConfigScreen> createState() => _AdminConfigScreenState();
}

class _AdminConfigScreenState extends ConsumerState<AdminConfigScreen> {
  final _commissionController = TextEditingController();
  final _deliveryController = TextEditingController();
  final _intervalController = TextEditingController();
  final _gstController = TextEditingController();
  final _lowStockController = TextEditingController();
  final _referralController = TextEditingController();
  final _minWithdrawalController = TextEditingController();

  @override
  void initState() {
    super.initState();
    final state = ref.read(adminProvider);
    _commissionController.text = state.commissionRate.toString();
    _deliveryController.text = state.deliveryTimeDays.toString();
    _intervalController.text = state.orderIntervalMinutes.toString();
    _gstController.text = state.gstRate.toString();
    _lowStockController.text = state.lowStockThreshold.toString();
    _referralController.text = state.referralReward.toString();
    _minWithdrawalController.text = state.minWithdrawal.toString();
  }

  @override
  void dispose() {
    _commissionController.dispose();
    _deliveryController.dispose();
    _intervalController.dispose();
    _gstController.dispose();
    _lowStockController.dispose();
    _referralController.dispose();
    _minWithdrawalController.dispose();
    super.dispose();
  }

  void _saveConfigs() async {
    await ref.read(adminProvider.notifier).updateConfigs(
      commissionRate: double.tryParse(_commissionController.text),
      deliveryTimeDays: int.tryParse(_deliveryController.text),
      orderIntervalMinutes: int.tryParse(_intervalController.text),
      gstRate: double.tryParse(_gstController.text),
      lowStockThreshold: int.tryParse(_lowStockController.text),
      referralReward: double.tryParse(_referralController.text),
      minWithdrawal: double.tryParse(_minWithdrawalController.text),
    );
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Configurations updated successfully', style: AppTextStyles.caption.copyWith(color: Colors.white)),
          backgroundColor: AppColors.success,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('System Configuration', style: AppTextStyles.h4),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        iconTheme: IconThemeData(color: AppColors.royalGold),
      ),
      body: Container(
        decoration: BoxDecoration(color: AppColors.background),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Trading & Commissions', style: AppTextStyles.labelLarge),
              const SizedBox(height: 16),
              GoldCard(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      GoldTextField(
                        label: 'Commission Rate (%)',
                        controller: _commissionController,
                        keyboardType: TextInputType.number,
                        hint: 'e.g., 2.5',
                      ),
                      const SizedBox(height: 16),
                      GoldTextField(
                        label: 'GST Rate (%)',
                        controller: _gstController,
                        keyboardType: TextInputType.number,
                        hint: 'e.g., 3.0',
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Text('Referrals & Rewards', style: AppTextStyles.labelLarge),
              const SizedBox(height: 16),
              GoldCard(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      GoldTextField(
                        label: 'Referral Reward (₹)',
                        controller: _referralController,
                        keyboardType: TextInputType.number,
                        hint: 'e.g., 500',
                      ),
                      const SizedBox(height: 16),
                      GoldTextField(
                        label: 'Min Withdrawal (₹)',
                        controller: _minWithdrawalController,
                        keyboardType: TextInputType.number,
                        hint: 'e.g., 1000',
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Text('Logistics & Delivery', style: AppTextStyles.labelLarge),
              const SizedBox(height: 16),
              GoldCard(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      GoldTextField(
                        label: 'Default Delivery Time (Days)',
                        controller: _deliveryController,
                        keyboardType: TextInputType.number,
                        hint: 'e.g., 5',
                      ),
                      const SizedBox(height: 16),
                      GoldTextField(
                        label: 'Order Interval (Minutes)',
                        controller: _intervalController,
                        keyboardType: TextInputType.number,
                        hint: 'e.g., 15',
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Text('Inventory & Alerts', style: AppTextStyles.labelLarge),
              const SizedBox(height: 16),
              GoldCard(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      GoldTextField(
                        label: 'Low Stock Threshold (Units)',
                        controller: _lowStockController,
                        keyboardType: TextInputType.number,
                        hint: 'e.g., 10',
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 40),
              GoldButton(
                text: 'SAVE CHANGES',
                onPressed: _saveConfigs,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
