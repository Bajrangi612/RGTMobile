import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/validators.dart';
import '../../../core/utils/extensions.dart';
import '../../../core/utils/formatters.dart';
import '../../../widgets/gold_button.dart';
import '../../../widgets/gold_card.dart';
import '../../../widgets/gold_app_bar.dart';
import '../../../widgets/status_badge.dart';
import '../providers/kyc_provider.dart';
import 'kyc_otp_screen.dart';
import 'bank_form_screen.dart';

class AadhaarKycScreen extends ConsumerStatefulWidget {
  AadhaarKycScreen({super.key}) ;

  @override
  ConsumerState<AadhaarKycScreen> createState() => _AadhaarKycScreenState();
}

class _AadhaarKycScreenState extends ConsumerState<AadhaarKycScreen> {
  final _aadhaarController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _aadhaarController.dispose();
    super.dispose();
  }

  Future<void> _submitKyc() async {
    if (!_formKey.currentState!.validate()) return;
    final success = await ref
        .read(kycProvider.notifier)
        .submitAadhaarKyc(_aadhaarController.text.trim());
    if (success && mounted) {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => KycOtpScreen(aadhaarNumber: _aadhaarController.text.trim()),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final kycState = ref.watch(kycProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: GoldAppBar(title: 'Aadhaar KYC'),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFFFFDF5), Color(0xFFFFFFFF)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Center(
                  child: Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: AppColors.royalGold.withOpacity(0.1),
                      shape: BoxShape.circle,
                      border: Border.all(color: AppColors.royalGold.withOpacity(0.3)),
                    ),
                    child: Icon(
                      Icons.fingerprint,
                      size: 40,
                      color: AppColors.royalGold,
                    ),
                  ),
                ).animate().scale(duration: 500.ms, curve: Curves.elasticOut),

                SizedBox(height: 24),
                Center(
                  child: Text('Verify Your Identity', style: AppTextStyles.h3.copyWith(color: AppColors.pureWhite)),
                ).animate().fadeIn(delay: 200.ms),
                SizedBox(height: 8),
                Center(
                  child: Text(
                    'Enter your Aadhaar number to complete KYC',
                    style: AppTextStyles.bodySmall,
                    textAlign: TextAlign.center,
                  ),
                ).animate().fadeIn(delay: 300.ms),

                SizedBox(height: 40),

                // Input Card
                GoldCard(
                  hasGoldBorder: true,
                  hasGlow: true,
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Aadhaar Number', style: AppTextStyles.labelLarge.copyWith(color: AppColors.pureWhite)),
                      SizedBox(height: 16),
                      TextFormField(
                        controller: _aadhaarController,
                        validator: Validators.aadhaar,
                        keyboardType: TextInputType.number,
                        maxLength: 12,
                        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                        style: AppTextStyles.h4.copyWith(
                          color: AppColors.pureWhite,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 3,
                        ),
                        cursorColor: AppColors.royalGold,
                        decoration: InputDecoration(
                          hintText: '0000 0000 0000',
                          counterText: '',
                          prefixIcon: Icon(Icons.badge_outlined, color: AppColors.royalGold),
                        ),
                      ),
                      SizedBox(height: 24),
                      GoldButton(
                        text: 'Verify Aadhaar',
                        isLoading: kycState.isLoading,
                        onPressed: kycState.isLoading ? null : _submitKyc,
                        icon: Icons.verified_user,
                      ),
                    ],
                  ),
                ).animate().fadeIn(delay: 400.ms, duration: 500.ms).slideY(begin: 0.1),

                SizedBox(height: 24),

                // Info Card
                GoldCard(
                  hasGoldBorder: false,
                  hasGlow: false,
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Icon(Icons.info_outline, color: AppColors.royalGold.withOpacity(0.7), size: 20),
                      SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Your Aadhaar details are secured with encryption and only used for identity verification.',
                          style: AppTextStyles.caption.copyWith(height: 1.5),
                        ),
                      ),
                    ],
                  ),
                ).animate().fadeIn(delay: 600.ms),
              ],
            ),
          ),
        ),
      ),
    ) ;
  }
}
