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

  @override
  void initState() {
    super.initState();
    final state = ref.read(adminProvider);
    _referralController.text = state.referralReward.toStringAsFixed(0);
    _gstController.text = state.gstRate.toStringAsFixed(1);
    _minWithdrawalController.text = state.minWithdrawal.toStringAsFixed(0);
    _deliveryDaysController.text = state.deliveryTimeDays.toString();
  }

  @override
  void dispose() {
    _referralController.dispose();
    _gstController.dispose();
    _minWithdrawalController.dispose();
    _deliveryDaysController.dispose();
    super.dispose();
  }

  Future<void> _saveSettings() async {
    final referral = double.tryParse(_referralController.text);
    final gst = double.tryParse(_gstController.text);
    final minWith = double.tryParse(_minWithdrawalController.text);
    final delivery = int.tryParse(_deliveryDaysController.text);

    await ref.read(adminProvider.notifier).updateConfigs(
      referralReward: referral,
      gstRate: gst,
      minWithdrawal: minWith,
      deliveryTimeDays: delivery,
    );

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Settings updated successfully')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final adminState = ref.watch(adminProvider);

    return Scaffold(
      backgroundColor: AppColors.deepBlack,
      appBar: GoldAppBar(title: 'Global Settings'),
      body: Container(
        decoration: BoxDecoration(gradient: AppColors.darkGradient),
        child: adminState.isLoading 
          ? const Center(child: CircularProgressIndicator(color: AppColors.royalGold))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Platform Economics', style: AppTextStyles.h4),
                  const SizedBox(height: 16),
                  GoldCard(
                    child: Column(
                      children: [
                        _ConfigField(
                          label: 'Referral Reward (₹)',
                          controller: _referralController,
                          icon: Icons.card_giftcard_rounded,
                          helperText: 'Fixed amount earnable per successful referral',
                        ),
                        const Divider(color: AppColors.glassBorder, height: 32),
                        _ConfigField(
                          label: 'GST Rate (%)',
                          controller: _gstController,
                          icon: Icons.percent_rounded,
                          helperText: 'Default tax applied to all gold purchases',
                        ),
                        const Divider(color: AppColors.glassBorder, height: 32),
                        _ConfigField(
                          label: 'Min Withdrawal (₹)',
                          controller: _minWithdrawalController,
                          icon: Icons.account_balance_wallet_rounded,
                          helperText: 'Minimum amount required for payout request',
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),
                  Text('Logistics & Delivery', style: AppTextStyles.h4),
                  const SizedBox(height: 16),
                  GoldCard(
                    child: _ConfigField(
                      label: 'Delivery Duration (Days)',
                      controller: _deliveryDaysController,
                      icon: Icons.local_shipping_rounded,
                      helperText: 'Estimated timeline for vaulted gold collection',
                    ),
                  ),

                  const SizedBox(height: 48),
                  GoldButton(
                    text: 'Save Changes',
                    onPressed: _saveSettings,
                    isLoading: adminState.isLoading,
                    icon: Icons.save_rounded,
                  ),
                ],
              ),
            ),
      ),
    );
  }
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
          children: [
            Icon(icon, color: AppColors.royalGold, size: 20),
            const SizedBox(width: 8),
            Text(label, style: AppTextStyles.labelLarge),
          ],
        ),
        const SizedBox(height: 12),
        TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          style: AppTextStyles.bodyMedium.copyWith(color: AppColors.pureWhite),
          decoration: InputDecoration(
            filled: true,
            fillColor: Colors.white.withValues(alpha: 0.05),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: AppColors.glassBorder),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: AppColors.glassBorder),
            ),
          ),
        ),
        const SizedBox(height: 6),
        Text(helperText, style: AppTextStyles.caption.copyWith(fontSize: 10)),
      ],
    );
  }
}
