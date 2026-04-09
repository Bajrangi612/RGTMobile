import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/kyc_provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:pin_code_fields/pin_code_fields.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/extensions.dart';
import '../../../widgets/gold_button.dart';
import '../../../widgets/gold_app_bar.dart';
import 'bank_form_screen.dart';

class KycOtpScreen extends ConsumerStatefulWidget {
  final String aadhaarNumber;

  KycOtpScreen({super.key, required this.aadhaarNumber});

  @override
  ConsumerState<KycOtpScreen> createState() => _KycOtpScreenState();
}

class _KycOtpScreenState extends ConsumerState<KycOtpScreen> {
  final _otpController = TextEditingController();

  Future<void> _verifyOtp() async {
    final success = await ref
        .read(kycProvider.notifier)
        .verifyAadhaarOtp(widget.aadhaarNumber, _otpController.text);

    if (success && mounted) {
      context.showSuccessSnackBar('Aadhaar verified successfully!');
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => BankFormScreen()),
      );
    } else if (mounted) {
      final error = ref.read(kycProvider).error;
      context.showErrorSnackBar(error ?? 'Verification failed');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.deepBlack,
      appBar:  GoldAppBar(title: 'Verify Aadhaar'),
      body: Container(
        decoration: BoxDecoration(gradient: AppColors.darkGradient),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(height: 24),
              Center(
                child: Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: AppColors.royalGold.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.royalGold.withValues(alpha: 0.3)),
                  ),
                  child: Icon(
                    Icons.sms_outlined,
                    size: 40,
                    color: AppColors.royalGold,
                  ),
                ),
              ).animate().scale(duration: 500.ms, curve: Curves.elasticOut),

              SizedBox(height: 32),
              Center(
                child: Text('OTP Verification', style: AppTextStyles.h3),
              ),
              SizedBox(height: 8),
              Center(
                child: RichText(
                  textAlign: TextAlign.center,
                  text: TextSpan(
                    style: AppTextStyles.bodySmall,
                    children: [
                      TextSpan(text: 'Enter the 6-digit code sent to the mobile number registered with Aadhaar '),
                      TextSpan(
                        text: '****${widget.aadhaarNumber.substring(widget.aadhaarNumber.length - 4)}',
                        style: AppTextStyles.labelLarge.copyWith(color: AppColors.royalGold, fontSize: 14),
                      ),
                    ],
                  ),
                ),
              ).animate().fadeIn(delay: 200.ms),

              SizedBox(height: 48),

              PinCodeTextField(
                appContext: context,
                length: 6,
                controller: _otpController,
                keyboardType: TextInputType.number,
                animationType: AnimationType.fade,
                pinTheme: PinTheme(
                  shape: PinCodeFieldShape.box,
                  borderRadius: BorderRadius.circular(8),
                  fieldHeight: 50,
                  fieldWidth: 45,
                  activeFillColor: AppColors.cardDark,
                  inactiveFillColor: AppColors.cardDark,
                  selectedFillColor: AppColors.cardDark,
                  activeColor: AppColors.royalGold,
                  inactiveColor: AppColors.darkGrey,
                  selectedColor: AppColors.royalGold,
                ),
                cursorColor: AppColors.royalGold,
                animationDuration: Duration(milliseconds: 300),
                enableActiveFill: true,
                onCompleted: (v) => _verifyOtp(),
                onChanged: (value) {},
                textStyle: TextStyle(color: AppColors.pureWhite, fontSize: 20),
              ).animate().fadeIn(delay: 400.ms),

              SizedBox(height: 40),

              GoldButton(
                text: 'Verify & Continue',
                isLoading: ref.watch(kycProvider).isLoading,
                onPressed: ref.watch(kycProvider).isLoading ? null : _verifyOtp,
                icon: Icons.check_circle_outline,
              ).animate().fadeIn(delay: 600.ms),

              SizedBox(height: 24),

              Center(
                child: TextButton(
                  onPressed: () {
                    context.showSuccessSnackBar('New OTP sent to your registered mobile number') ;
                  },
                  child: Text(
                    'Resend OTP',
                    style: AppTextStyles.labelLarge.copyWith(color: AppColors.royalGold),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
