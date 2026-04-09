import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/validators.dart';
import '../../../core/utils/extensions.dart';
import '../../../widgets/gold_button.dart';
import '../../../widgets/gold_card.dart';
import '../../../widgets/gold_app_bar.dart';
import '../../../widgets/gold_text_field.dart';
import '../providers/kyc_provider.dart';

class BankFormScreen extends ConsumerStatefulWidget {
  BankFormScreen({super.key}) ;

  @override
  ConsumerState<BankFormScreen> createState() => _BankFormScreenState();
}

class _BankFormScreenState extends ConsumerState<BankFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _accountController = TextEditingController();
  final _confirmAccountController = TextEditingController();
  final _ifscController = TextEditingController();
  final _nameController = TextEditingController();

  @override
  void dispose() {
    _accountController.dispose();
    _confirmAccountController.dispose();
    _ifscController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final success = await ref.read(kycProvider.notifier).submitBankDetails(
          accountNumber: _accountController.text.trim(),
          ifscCode: _ifscController.text.trim().toUpperCase(),
          accountHolderName: _nameController.text.trim(),
        );
    if (success && mounted) {
      context.showSuccessSnackBar('Bank details verified!');
      Navigator.of(context).popUntil((route) => route.isFirst);
    }
  }

  @override
  Widget build(BuildContext context) {
    final kycState = ref.watch(kycProvider);

    return Scaffold(
      backgroundColor: AppColors.deepBlack,
      appBar: GoldAppBar(title: 'Bank Details'),
      body: Container(
        decoration: BoxDecoration(gradient: AppColors.darkGradient),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: AppColors.royalGold.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                      border: Border.all(color: AppColors.royalGold.withValues(alpha: 0.3)),
                    ),
                    child: Icon(Icons.account_balance, size: 40, color: AppColors.royalGold),
                  ),
                ).animate().scale(duration: 500.ms, curve: Curves.elasticOut),

                SizedBox(height: 24),
                Center(child: Text('Link Your Bank', style: AppTextStyles.h3))
                    .animate().fadeIn(delay: 200.ms),
                SizedBox(height: 8),
                Center(
                  child: Text(
                    'For secure payments and refunds',
                    style: AppTextStyles.bodySmall,
                  ),
                ).animate().fadeIn(delay: 300.ms),

                SizedBox(height: 32),

                GoldCard(
                  hasGoldBorder: true,
                  child: Column(
                    children: [
                      GoldTextField(
                        controller: _accountController,
                        label: 'Account Number',
                        hint: 'Enter account number',
                        validator: Validators.accountNumber,
                        keyboardType: TextInputType.number,
                        maxLength: 18,
                        prefixIcon: Icon(Icons.account_balance_wallet, color: AppColors.royalGold),
                      ),
                      SizedBox(height: 16),
                      GoldTextField(
                        controller: _confirmAccountController,
                        label: 'Confirm Account Number',
                        hint: 'Re-enter account number',
                        validator: (v) => Validators.confirmAccountNumber(v, _accountController.text),
                        keyboardType: TextInputType.number,
                        maxLength: 18,
                        prefixIcon: Icon(Icons.verified_outlined, color: AppColors.royalGold),
                      ),
                      SizedBox(height: 16),
                      GoldTextField(
                        controller: _ifscController,
                        label: 'IFSC Code',
                        hint: 'e.g., SBIN0001234',
                        validator: Validators.ifsc,
                        textCapitalization: TextCapitalization.characters,
                        maxLength: 11,
                        prefixIcon: Icon(Icons.code, color: AppColors.royalGold),
                        onChanged: (value) {
                          if (value.length >= 4) {
                            ref.read(kycProvider.notifier).lookupIfsc(value) ;
                          }
                        },
                      ),
                      if (kycState.bankName != null) ...[
                        SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: AppColors.success.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: AppColors.success.withValues(alpha: 0.3)),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.check_circle, color: AppColors.success, size: 16),
                              SizedBox(width: 8),
                              Text(
                                kycState.bankName!,
                                style: AppTextStyles.bodySmall.copyWith(color: AppColors.success),
                              ),
                            ],
                          ),
                        ),
                      ],
                      SizedBox(height: 16),
                      GoldTextField(
                        controller: _nameController,
                        label: 'Account Holder Name',
                        hint: 'As per bank records',
                        validator: Validators.name,
                        textCapitalization: TextCapitalization.words,
                        prefixIcon: Icon(Icons.person_outline, color: AppColors.royalGold),
                      ),
                      SizedBox(height: 24),
                      GoldButton(
                        text: 'Submit & Verify',
                        isLoading: kycState.isLoading,
                        onPressed: kycState.isLoading ? null : _submit,
                        icon: Icons.verified,
                      ),
                    ],
                  ),
                ).animate().fadeIn(delay: 400.ms, duration: 500.ms).slideY(begin: 0.1),
              ],
            ),
          ),
        ),
      ),
    ) ;
  }
}
