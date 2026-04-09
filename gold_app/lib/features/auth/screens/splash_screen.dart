import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../providers/auth_provider.dart';
import 'login_screen.dart';
import '../../home/screens/home_screen.dart';
import '../../admin/screens/admin_dashboard_screen.dart';
import 'complete_profile_screen.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    // Wait for the animation to play a bit
    await Future.delayed(const Duration(milliseconds: 2500));
    
    if (!mounted) return;

    // Check authentication status
    await ref.read(authProvider.notifier).checkAuthStatus();
    
    if (!mounted) return;

    final authState = ref.read(authProvider);
    
    Widget nextScreen;
    if (authState.status == AuthStatus.authenticated) {
      final user = authState.user;
      if (user?.isAdmin == true) {
        nextScreen = const AdminDashboardScreen();
      } else if (user?.registerRequired == true || (user?.name.isEmpty ?? true)) {
        nextScreen = CompleteProfileScreen();
      } else {
        nextScreen = const HomeScreen();
      }
    } else {
      nextScreen = const LoginScreen();
    }

    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => nextScreen,
        transitionsBuilder: (_, anim, __, child) => FadeTransition(opacity: anim, child: child),
        transitionDuration: const Duration(milliseconds: 800),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark.copyWith(
        statusBarColor: Colors.transparent,
      ),
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: Container(
          decoration: BoxDecoration(color: AppColors.background),
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
                      backgroundColor: AppColors.royalGold.withValues(alpha: 0.1),
                      color: AppColors.royalGold,
                    ),
                  ),
                ).animate().fadeIn(delay: 800.ms),
                
                const SizedBox(height: 24),
                
                Text(
                  'INVEST IN ELEGANCE. OWN THE LEGACY.',
                  textAlign: TextAlign.center,
                  style: AppTextStyles.labelSmall.copyWith(
                    color: AppColors.royalGold.withValues(alpha: 0.7),
                    letterSpacing: 2,
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                  ),
                ).animate().fadeIn(delay: 1800.ms),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
