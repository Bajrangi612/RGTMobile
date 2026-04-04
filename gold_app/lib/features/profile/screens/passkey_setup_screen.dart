import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:lottie/lottie.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/extensions.dart';
import '../../../widgets/gold_button.dart';
import '../../../widgets/gold_card.dart';
import '../../../widgets/gold_app_bar.dart';

class PasskeySetupScreen extends ConsumerStatefulWidget {
  PasskeySetupScreen({super.key});

  @override
  ConsumerState<PasskeySetupScreen> createState() => _PasskeySetupScreenState();
}

class _PasskeySetupScreenState extends ConsumerState<PasskeySetupScreen> {
  bool _isEnabling = false;

  Future<void> _enablePasskey() async {
    setState(() => _isEnabling = true);
    
    // Mock biometric/security prompt delay
    await Future.delayed(Duration(seconds: 2));

    if (mounted) {
      setState(() => _isEnabling = false);
      context.showSuccessSnackBar('Passkey enabled successfully!');
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.deepBlack,
      appBar: GoldAppBar(title: 'Security'),
      body: Container(
        decoration: BoxDecoration(gradient: AppColors.darkGradient),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              SizedBox(height: 24),
              
              // Animated Illustration
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  color: AppColors.cardDarkAlt,
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.royalGold.withOpacity(0.3)),
                ),
                child: Icon(
                  Icons.fingerprint,
                  size: 64,
                  color: AppColors.royalGold,
                ),
              ).animate()
               .scale(duration: 600.ms, curve: Curves.elasticOut)
               .shimmer(delay: 1.seconds, duration: 2.seconds),

              SizedBox(height: 32),

              Text('Setup Passkey', style: AppTextStyles.h2),
              SizedBox(height: 12),
              Text(
                'Use biometrics or your screen lock pin to sign in faster and more securely.',
                style: AppTextStyles.bodySmall,
                textAlign: TextAlign.center,
              ),

              SizedBox(height: 48),

              GoldCard(
                hasGoldBorder: true,
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    _FeatureRow(
                      icon: Icons.flash_on_rounded,
                      title: 'Faster Login',
                      description: 'Sign in instantly without OTP',
                    ),
                    Divider(height: 32, color: AppColors.darkGrey),
                    _FeatureRow(
                      icon: Icons.security_rounded,
                      title: 'Extra Secure',
                      description: 'Uses industry standard encryption',
                    ),
                    Divider(height: 32, color: AppColors.darkGrey),
                    _FeatureRow(
                      icon: Icons.devices_rounded,
                      title: 'Device Sync',
                      description: 'Works across all your devices',
                    ),
                  ],
                ),
              ).animate(delay: 200.ms).fadeIn(duration: 500.ms).slideY(begin: 0.1),

              SizedBox(height: 48),

              GoldButton(
                text: 'Enable Passkey',
                isLoading: _isEnabling,
                onPressed: _isEnabling ? null : _enablePasskey,
                icon: Icons.lock_open_rounded,
              ),

              SizedBox(height: 24),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(
                  'Skip for now',
                  style: AppTextStyles.labelLarge.copyWith(color: AppColors.grey),
                ),
              ),
            ],
          ),
        ),
      ),
    ) ;
  }
}

class _FeatureRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;

  const _FeatureRow({
    required this.icon,
    required this.title,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppColors.royalGold.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: AppColors.royalGold, size: 20),
        ),
        SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: AppTextStyles.labelLarge),
              SizedBox(height: 2),
              Text(description, style: AppTextStyles.caption),
            ],
          ),
        ),
      ],
    );
  }
}
