import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import 'login_screen.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> {
  @override
  void initState() {
    super.initState();
    // Use a simple Timer for guaranteed execution outside the build cycle
    Timer(const Duration(milliseconds: 2500), () {
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const LoginScreen()),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Container(
        decoration: BoxDecoration(gradient: AppColors.darkGradient),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Animated Official Logo
              Image.asset(
                'assets/images/logo.png',
                width: 180,
                height: 180,
                fit: BoxFit.contain,
              )
              .animate(onPlay: (controller) => controller.repeat(reverse: true))
              .scale(
                begin: const Offset(0.95, 0.95),
                end: const Offset(1.05, 1.05),
                duration: 2500.ms,
                curve: Curves.easeInOut,
              )
              .shimmer(
                duration: 4000.ms,
                color: Colors.white10,
              ),
              
              const SizedBox(height: 30),
              
              // Shimmering Title Text
              Text(
                'ROYAL GOLD',
                style: AppTextStyles.h1.copyWith(
                  color: AppColors.royalGold,
                  letterSpacing: 10,
                  fontSize: 32,
                  fontWeight: FontWeight.w900,
                ),
              )
              .animate()
              .fadeIn(duration: 1000.ms)
              .slideY(begin: 0.1, end: 0)
              .shimmer(
                delay: 1500.ms,
                duration: 3000.ms,
                color: Colors.white24,
              ),
              
              const SizedBox(height: 50),
              
              // Premium Progress Bar
              SizedBox(
                width: 220,
                height: 2,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(1),
                  child: LinearProgressIndicator(
                    backgroundColor: AppColors.royalGold.withOpacity(0.05),
                    color: AppColors.royalGold,
                  ),
                ),
              ).animate().fadeIn(delay: 800.ms),
              
              const SizedBox(height: 24),
              
              Text(
                'INVEST IN ELEGANCE. OWN THE LEGACY.',
                textAlign: TextAlign.center,
                style: AppTextStyles.labelSmall.copyWith(
                  color: AppColors.royalGold.withOpacity(0.7),
                  letterSpacing: 2,
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                ),
              ).animate().fadeIn(delay: 1800.ms),
            ],
          ),
        ),
      ),
    );
  }
}
