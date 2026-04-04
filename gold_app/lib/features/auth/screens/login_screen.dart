import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/validators.dart';
import '../../../core/utils/extensions.dart';
import '../../../widgets/gold_button.dart';
import '../../../widgets/gold_card.dart';
import '../providers/auth_provider.dart';
import '../../profile/screens/legal_policy_screen.dart';
import 'otp_screen.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _phoneController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  Future<void> _sendOtp() async {
    if (!_formKey.currentState!.validate()) return;

    final phone = _phoneController.text.trim();
    final success = await ref.read(authProvider.notifier).sendOtp(phone);

    if (success && mounted) {
      Navigator.of(context).push(
        PageRouteBuilder(
          pageBuilder: (_, __, ___) => OtpScreen(phone: phone),
          transitionsBuilder: (_, anim, __, child) => SlideTransition(
            position: Tween(begin: const Offset(1, 0), end: Offset.zero)
                .animate(
                  CurvedAnimation(parent: anim, curve: Curves.easeOutCubic),
                ),
            child: child,
          ),
          transitionDuration: const Duration(milliseconds: 400),
        ),
      );
    } else if (mounted) {
      context.showErrorSnackBar('Failed to send OTP. Please try again.');
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark.copyWith(
        statusBarColor: Colors.transparent,
      ),
      child: Scaffold(
        body: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFFFFFDF5), Color(0xFFFFFFFF)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Stack(
            children: [
              /// 🔥 Background Glow
              Positioned(
                top: -120,
                left: -80,
                child: Container(
                  width: 300,
                  height: 300,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.royalGold.withOpacity(0.04),
                  ),
                ),
              ),

              SafeArea(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 50),

                      /// 💎 Logo (Clean)
                      Center(
                        child: Image.asset(
                          'assets/images/logo.png',
                          width: 110,
                          fit: BoxFit.contain,
                        ),
                      )
                      .animate()
                      .scale(duration: 700.ms, curve: Curves.easeOutBack)
                      .fadeIn(),

                      const SizedBox(height: 40),

                      /// 🏆 Title
                      Text(
                        'Welcome to',
                        style: AppTextStyles.bodyLarge.copyWith(
                          color: AppColors.grey,
                        ),
                      ).animate().fadeIn(delay: 200.ms),

                      Text(
                        'Royal Gold Traders',
                        style: AppTextStyles.goldTitle.copyWith(
                          fontSize: 28,
                          letterSpacing: 1.5,
                        ),
                      ).animate().fadeIn(delay: 300.ms),

                      const SizedBox(height: 12),

                      Text(
                        'Buy • Sell • Invest in Gold Coins',
                        style: AppTextStyles.bodyMedium.copyWith(
                          color: AppColors.grey,
                          letterSpacing: 1.1,
                        ),
                      ).animate().fadeIn(delay: 400.ms),

                      const SizedBox(height: 40),

                      /// 💠 Frosted Glassmorphism Card
                      GoldCard(
                        hasGoldBorder: true,
                        hasGlow: true,
                        padding: const EdgeInsets.all(24),
                        child: Form(
                          key: _formKey,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Login / Signup',
                                style: AppTextStyles.h4.copyWith(fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: 24),

                              /// 📱 Phone Field
                              TextFormField(
                                controller: _phoneController,
                                validator: Validators.phone,
                                keyboardType: TextInputType.phone,
                                maxLength: 10,
                                inputFormatters: [
                                  FilteringTextInputFormatter.digitsOnly,
                                ],
                                style: AppTextStyles.h4.copyWith(
                                  color: AppColors.pureWhite,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 2,
                                ),
                                cursorColor: AppColors.royalGold,
                                decoration: InputDecoration(
                                  labelText: 'Mobile Number',
                                  labelStyle: TextStyle(color: AppColors.grey),
                                  prefixIcon: Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                                    child: Text(
                                      '🇮🇳 +91',
                                      style: AppTextStyles.labelLarge.copyWith(
                                        color: AppColors.pureWhite,
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(16),
                                    borderSide: BorderSide(color: AppColors.royalGold.withOpacity(0.15)),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(16),
                                    borderSide: const BorderSide(color: Color(0xFFD4AF37), width: 1.5),
                                  ),
                                ),
                              ),

                              const SizedBox(height: 28),

                              /// 🚀 Button
                              GoldButton(
                                text: 'Send OTP',
                                isLoading: authState.isLoading,
                                onPressed: authState.isLoading ? null : _sendOtp,
                                icon: Icons.arrow_forward_ios_rounded,
                              ),
                            ],
                          ),
                        ),
                      ).animate().fadeIn(delay: 500.ms).slideY(begin: 0.1),

                      const SizedBox(height: 30),

                      /// 📜 Terms
                      Center(
                        child: RichText(
                          textAlign: TextAlign.center,
                          text: TextSpan(
                            style: AppTextStyles.caption,
                            children: [
                              const TextSpan(
                                text: 'By continuing, you agree to ',
                              ),
                              TextSpan(
                                text: 'Terms',
                                style: TextStyle(color: AppColors.royalGold, fontWeight: FontWeight.bold),
                                recognizer: TapGestureRecognizer()..onTap = () {},
                              ),
                              const TextSpan(text: ' & '),
                              TextSpan(
                                text: 'Privacy Policy',
                                style: TextStyle(color: AppColors.royalGold, fontWeight: FontWeight.bold),
                                recognizer: TapGestureRecognizer()..onTap = () {},
                              ),
                            ],
                          ),
                        ),
                      ).animate().fadeIn(delay: 700.ms),

                      const SizedBox(height: 40),
                    ],
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
