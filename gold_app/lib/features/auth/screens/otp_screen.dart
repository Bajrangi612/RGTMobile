import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:pin_code_fields/pin_code_fields.dart';
import 'dart:async';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/utils/extensions.dart';
import '../../../widgets/gold_button.dart';
import '../../../widgets/gold_card.dart';
import '../providers/auth_provider.dart';
import '../../home/screens/home_screen.dart';
import '../../admin/screens/admin_dashboard_screen.dart';
import 'complete_profile_screen.dart';

class OtpScreen extends ConsumerStatefulWidget {
  final String phone;

  const OtpScreen({super.key, required this.phone});

  @override
  ConsumerState<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends ConsumerState<OtpScreen> {
  final _otpController = TextEditingController();
  late Timer _timer;
  int _resendSeconds = AppConstants.otpResendSeconds;
  bool _canResend = false;
  String _otp = '';

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  void _startTimer() {
    _resendSeconds = AppConstants.otpResendSeconds;
    _canResend = false;
    _timer = Timer.periodic(Duration(seconds: 1), (timer) {
      if (_resendSeconds == 0) {
        setState(() => _canResend = true);
        timer.cancel();
      } else {
        setState(() => _resendSeconds--);
      }
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    _otpController.dispose();
    super.dispose();
  }

  Future<void> _verifyOtp() async {
    if (_otp.length != AppConstants.otpLength) return;

    final success = await ref.read(authProvider.notifier).verifyOtp(
          widget.phone,
          _otp,
        );

    if (success && mounted) {
      final user = ref.read(authProvider).user;
      if (user != null && user.name.isNotEmpty) {
        context.showSuccessSnackBar('Welcome back, ${user.name}!');
      }

      Navigator.of(context).pushAndRemoveUntil(
        PageRouteBuilder(
          pageBuilder: (_, __, ___) {
            final latestUser = ref.read(authProvider).user;
            if (latestUser?.isAdmin == true) {
              return const AdminDashboardScreen();
            } else if (latestUser?.registerRequired == true || (latestUser?.name.isEmpty ?? true)) {
              return const CompleteProfileScreen();
            } else {
              return const HomeScreen();
            }
          },
          transitionsBuilder: (_, anim, __, child) =>
              FadeTransition(opacity: anim, child: child),
          transitionDuration: const Duration(milliseconds: 600),
        ),
        (route) => false,
      );
    } else if (mounted) {
      context.showErrorSnackBar('Invalid OTP. Please try again.');
      _otpController.clear();
      setState(() => _otp = '');
    }
  }

  Future<void> _resendOtp() async {
    if (!_canResend) return;
    await ref.read(authProvider.notifier).sendOtp(widget.phone);
    _startTimer();
    if (mounted) {
      context.showSuccessSnackBar('OTP sent successfully!');
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final maskedPhone = '${widget.phone.substring(0, 2)}****${widget.phone.substring(widget.phone.length - 4)}';

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Container(
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: AppColors.darkGradient,
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 20),

                // Back button
                GestureDetector(
                  onTap: () => Navigator.of(context).pop(),
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.black.withValues(alpha: 0.05)),
                    ),
                    child: Icon(
                      Icons.arrow_back_ios_new,
                      color: AppColors.royalGold,
                      size: 18,
                    ),
                  ),
                ).animate().fadeIn(duration: 300.ms),

                const SizedBox(height: 40),

                // Title
                Text('Verify OTP', style: AppTextStyles.h2.copyWith(color: AppColors.royalGold))
                    .animate().fadeIn(delay: 200.ms, duration: 500.ms).slideX(begin: -0.1),
                SizedBox(height: 8),
                RichText(
                  text: TextSpan(
                    style: AppTextStyles.bodyMedium.copyWith(color: AppColors.grey),
                    children: [
                      TextSpan(text: 'We sent a verification code to\n'),
                      TextSpan(
                        text: '+91 $maskedPhone',
                        style: AppTextStyles.bodyMedium.copyWith(
                          color: AppColors.royalGold,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ).animate().fadeIn(delay: 300.ms, duration: 500.ms),

                SizedBox(height: 48),

                // OTP Input
                GoldCard(
                  hasGoldBorder: true,
                  child: Column(
                    children: [
                      Text(
                        'Enter 6-digit OTP',
                        style: AppTextStyles.labelLarge.copyWith(color: AppColors.pureWhite),
                      ),
                      SizedBox(height: 24),

                      PinCodeTextField(
                        appContext: context,
                        length: AppConstants.otpLength,
                        controller: _otpController,
                        animationType: AnimationType.scale,
                        animationDuration: Duration(milliseconds: 200),
                        keyboardType: TextInputType.number,
                        textStyle: TextStyle(
                          color: AppColors.pureWhite,
                          fontSize: 24,
                          fontWeight: FontWeight.w700,
                        ),
                        pinTheme: PinTheme(
                          shape: PinCodeFieldShape.box,
                          borderRadius: BorderRadius.circular(12),
                          fieldHeight: 56,
                          fieldWidth: 40,
                          activeFillColor: Colors.white,
                          inactiveFillColor: Colors.white,
                          selectedFillColor: Colors.white,
                          activeColor: AppColors.royalGold,
                          inactiveColor: Colors.black.withValues(alpha: 0.05),
                          selectedColor: AppColors.royalGold,
                          borderWidth: 1.5,
                        ),
                        enableActiveFill: true,
                        cursorColor: AppColors.royalGold,
                        onChanged: (value) {
                          setState(() => _otp = value) ;
                        },
                        onCompleted: (value) {
                          setState(() => _otp = value);
                          _verifyOtp();
                        },
                      ),

                      if (authState.testOtp != null) ...[
                        SizedBox(height: 8),
                        Text(
                          'Test OTP: ${authState.testOtp}',
                          style: AppTextStyles.bodySmall.copyWith(
                            color: AppColors.royalGold,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],

                      SizedBox(height: 16),

                      // Resend timer
                      _canResend
                          ? GestureDetector(
                              onTap: _resendOtp,
                              child: Text(
                                'Resend OTP',
                                style: AppTextStyles.labelLarge.copyWith(
                                  color: AppColors.royalGold,
                                ),
                              ),
                            ) : Text(
                              'Resend OTP in ${_resendSeconds}s',
                              style: AppTextStyles.bodySmall,
                            ),
                    ],
                  ),
                ).animate().fadeIn(delay: 400.ms, duration: 600.ms).slideY(begin: 0.1),

                SizedBox(height: 32),

                // Verify Button
                GoldButton(
                  text: 'Verify & Continue',
                  isLoading: authState.isLoading,
                  onPressed: _otp.length == AppConstants.otpLength && !authState.isLoading
                      ? _verifyOtp
                      : null,
                  icon: Icons.verified_rounded,
                ).animate().fadeIn(delay: 600.ms, duration: 400.ms),

                SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    ) ;
  }
}
