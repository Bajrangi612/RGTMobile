import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:gold_app/core/theme/app_colors.dart';
import 'package:gold_app/core/theme/app_text_styles.dart';
import 'package:gold_app/core/providers/navigation_provider.dart';
import 'package:gold_app/features/auth/providers/auth_provider.dart';
import 'package:gold_app/features/auth/screens/login_screen.dart';
import 'package:gold_app/features/home/screens/home_screen.dart';
import 'package:gold_app/features/admin/screens/admin_dashboard_screen.dart';
import 'package:gold_app/features/auth/screens/complete_profile_screen.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'offer_splash_screen.dart';
import '../../../core/utils/version_utils.dart';
import '../../../widgets/update_dialog.dart';
import '../../../core/providers/settings_provider.dart';

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

    // Version Check
    final packageInfo = await PackageInfo.fromPlatform();
    final currentVersion = packageInfo.version;
    final settings = ref.read(settingsProvider);

    if (!mounted) return;

    if (VersionUtils.isUpdateRequired(currentVersion, settings.minVersion)) {
      // Mandatory Update
      await showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => UpdateDialog(latestVersion: settings.latestVersion, isMandatory: true),
      );
      return; // Stop app flow
    } else if (VersionUtils.isUpdateAvailable(currentVersion, settings.latestVersion)) {
      // Optional Update
      await showDialog(
        context: context,
        barrierDismissible: true,
        builder: (_) => UpdateDialog(latestVersion: settings.latestVersion, isMandatory: false),
      );
    }

    if (!mounted) return;
    
    Widget nextScreen;
    if (authState.status == AuthStatus.authenticated) {
      ref.read(navigationProvider.notifier).state = 0; // Reset to Dashboard on start
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

    if (authState.status == AuthStatus.authenticated && 
        authState.user?.isAdmin != true && 
        nextScreen is HomeScreen) {
       Navigator.of(context).pushReplacement(
        PageRouteBuilder(
          pageBuilder: (_, __, ___) => OfferSplashScreen(nextScreen: nextScreen),
          transitionsBuilder: (_, anim, __, child) => FadeTransition(opacity: anim, child: child),
          transitionDuration: const Duration(milliseconds: 800),
        ),
      );
    } else {
      Navigator.of(context).pushReplacement(
        PageRouteBuilder(
          pageBuilder: (_, __, ___) => nextScreen,
          transitionsBuilder: (_, anim, __, child) => FadeTransition(opacity: anim, child: child),
          transitionDuration: const Duration(milliseconds: 800),
        ),
      );
    }
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
                  'assets/images/logo.webp',
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
                    fontSize: 42,
                    letterSpacing: 6,
                    fontWeight: FontWeight.w900,
                  ),
                ).animate().fadeIn(duration: 800.ms).slideY(begin: 0.2),
                Text(
                  'TRADERS',
                  style: AppTextStyles.h2.copyWith(
                    color: AppColors.royalGold,
                    fontSize: 24,
                    letterSpacing: 12,
                    fontWeight: FontWeight.w300,
                  ),
                ).animate(delay: 200.ms).fadeIn(),
              const SizedBox(height: 8),
              Text(
                'PRECISION QUALITY',
                style: AppTextStyles.labelMedium.copyWith(
                  color: AppColors.pureWhite.withValues(alpha: 0.4),
                  letterSpacing: 4,
                ),
              ).animate(delay: 400.ms).fadeIn(),
                
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
                  'SAVE IN ELEGANCE. OWN THE LEGACY.',
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
