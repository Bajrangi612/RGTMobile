import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../widgets/gold_button.dart';
import '../../../widgets/gold_card.dart';
import '../../../widgets/gold_app_bar.dart';
import '../providers/admin_provider.dart';

class AdminSettingsScreen extends ConsumerStatefulWidget {
  const AdminSettingsScreen({super.key});

  @override
  ConsumerState<AdminSettingsScreen> createState() => _AdminSettingsScreenState();
}

class _AdminSettingsScreenState extends ConsumerState<AdminSettingsScreen> {
  final _referralController = TextEditingController();
  final _gstController = TextEditingController();
  final _minWithdrawalController = TextEditingController();
  final _deliveryDaysController = TextEditingController();
  final _commissionController = TextEditingController();
  final _intervalController = TextEditingController();
  final _lowStockController = TextEditingController();

  @override
  void initState() {
    super.initState();
    final state = ref.read(adminProvider);
    _referralController.text = state.referralReward.toStringAsFixed(0);
    _gstController.text = state.gstRate.toStringAsFixed(1);
    _minWithdrawalController.text = state.minWithdrawal.toStringAsFixed(0);
    _deliveryDaysController.text = state.deliveryTimeDays.toString();
    _commissionController.text = state.commissionRate.toStringAsFixed(1);
    _intervalController.text = state.orderIntervalMinutes.toString();
    _lowStockController.text = state.lowStockThreshold.toString();
  }

  @override
  void dispose() {
    _referralController.dispose();
    _gstController.dispose();
    _minWithdrawalController.dispose();
    _deliveryDaysController.dispose();
    _commissionController.dispose();
    _intervalController.dispose();
    _lowStockController.dispose();
    super.dispose();
  }

  Future<void> _saveSettings() async {
    await ref.read(adminProvider.notifier).updateConfigs(
      referralReward: double.tryParse(_referralController.text),
      gstRate: double.tryParse(_gstController.text),
      minWithdrawal: double.tryParse(_minWithdrawalController.text),
      deliveryTimeDays: int.tryParse(_deliveryDaysController.text),
      commissionRate: double.tryParse(_commissionController.text),
      orderIntervalMinutes: int.tryParse(_intervalController.text),
      lowStockThreshold: int.tryParse(_lowStockController.text),
    );

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Settings updated successfully'), behavior: SnackBarBehavior.floating),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final adminState = ref.watch(adminProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: GoldAppBar(title: 'Global Settings'),
      body: Container(
        decoration: BoxDecoration(color: AppColors.background),
        child: adminState.isLoading 
          ? Center(child: CircularProgressIndicator(color: AppColors.royalGold))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                   _buildSectionTitle('Platform Economics'),
                  const SizedBox(height: 16),
                  GoldCard(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      children: [
                        _ConfigField(
                          label: 'Referral Reward (₹)',
                          controller: _referralController,
                          icon: Icons.stars_rounded,
                          helperText: 'Fixed amount earnable per successful referral',
                        ),
                        _Divider(),
                        _ConfigField(
                          label: 'GST Rate (%)',
                          controller: _gstController,
                          icon: Icons.percent_rounded,
                          helperText: 'Default tax applied to all gold purchases',
                        ),
                        _Divider(),
                        _ConfigField(
                          label: 'Admin Commission (%)',
                          controller: _commissionController,
                          icon: Icons.account_balance_rounded,
                          helperText: 'Platform service fee on transactions',
                        ),
                        _Divider(),
                        _ConfigField(
                          label: 'Min Withdrawal (₹)',
                          controller: _minWithdrawalController,
                          icon: Icons.account_balance_wallet_rounded,
                          helperText: 'Minimum amount required for payout request',
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 32),
                  _buildSectionTitle('Orders & Inventory'),
                  const SizedBox(height: 16),
                  GoldCard(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      children: [
                        _ConfigField(
                          label: 'Delivery Duration (Days)',
                          controller: _deliveryDaysController,
                          icon: Icons.local_shipping_rounded,
                          helperText: 'Timeline for vaulted gold collection',
                        ),
                        _Divider(),
                        _ConfigField(
                          label: 'Order Interval (Minutes)',
                          controller: _intervalController,
                          icon: Icons.timer_rounded,
                          helperText: 'Cool-down period between user orders',
                        ),
                        _Divider(),
                        _ConfigField(
                          label: 'Low Stock Threshold',
                          controller: _lowStockController,
                          icon: Icons.inventory_2_rounded,
                          helperText: 'Units remaining before low stock alert',
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 48),
                  GoldButton(
                    text: 'SAVE GLOBAL CONFIGURATION',
                    onPressed: _saveSettings,
                    isLoading: adminState.isLoading,
                    icon: Icons.save_rounded,
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title.toUpperCase(),
      style: AppTextStyles.labelLarge.copyWith(
        color: AppColors.royalGold,
        letterSpacing: 2,
        fontWeight: FontWeight.bold,
      ),
    );
  }
}

class _Divider extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Divider(color: AppColors.pureWhite.withValues(alpha: 0.05), height: 32);
}

class _ConfigField extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final IconData icon;
  final String helperText;

  const _ConfigField({
    required this.label,
    required this.controller,
    required this.icon,
    required this.helperText,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Icon(icon, color: AppColors.royalGold.withValues(alpha: 0.7), size: 18),
                const SizedBox(width: 8),
                Text(label, style: AppTextStyles.labelMedium.copyWith(color: AppColors.grey)),
              ],
            ),
            SizedBox(
              width: 100,
              child: TextField(
                controller: controller,
                keyboardType: TextInputType.number,
                textAlign: TextAlign.right,
                style: AppTextStyles.bodyMedium.copyWith(color: AppColors.pureWhite, fontWeight: FontWeight.bold),
                decoration: const InputDecoration(
                  border: InputBorder.none,
                  hintText: '0.00',
                  hintStyle: TextStyle(color: Colors.white24),
                ),
              ),
            ),
          ],
        ),
        Text(helperText, style: AppTextStyles.caption.copyWith(fontSize: 10, color: AppColors.pureWhite.withValues(alpha: 0.3))),
      ],
    );
  }
}
