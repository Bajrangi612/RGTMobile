import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';

class OfferSplashScreen extends StatelessWidget {
  final Widget nextScreen;

  const OfferSplashScreen({super.key, required this.nextScreen});

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light.copyWith(
        statusBarColor: Colors.transparent,
      ),
      child: Scaffold(
        backgroundColor: Colors.black,
        body: Stack(
          children: [
            // Full Screen Image
            Positioned.fill(
              child: Image.asset(
                'assets/images/banner_1_vertical.png',
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Container(
                  color: AppColors.deepBlack,
                  child: Center(
                    child: Icon(Icons.auto_awesome, color: AppColors.royalGold, size: 64),
                  ),
                ),
              ),
            ),
            
            // Subtle Gradient Overlay for Readability
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.black.withOpacity(0.4),
                      Colors.transparent,
                      Colors.black.withOpacity(0.8),
                    ],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
              ),
            ),

            // Top Close/Skip Button (Elegant)
            Positioned(
              top: 50,
              right: 24,
              child: GestureDetector(
                onTap: () => _navigateToNext(context),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.white24),
                  ),
                  child: Text(
                    'SKIP',
                    style: AppTextStyles.caption.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.5,
                    ),
                  ),
                ),
              ).animate().fadeIn(delay: 1.seconds),
            ),

            // Bottom CTA
            Positioned(
              bottom: 60,
              left: 32,
              right: 32,
              child: Column(
                children: [
                  Text(
                    'LIMITED TIME FESTIVE OFFER',
                    style: AppTextStyles.labelSmall.copyWith(
                      color: AppColors.royalGold,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 4,
                    ),
                  ).animate().fadeIn(delay: 400.ms).slideY(begin: 0.2),
                  
                  const SizedBox(height: 24),
                  
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: () => _navigateToNext(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.royalGold,
                        foregroundColor: Colors.black,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        elevation: 10,
                        shadowColor: AppColors.royalGold.withOpacity(0.4),
                      ),
                      child: Text(
                        'CONTINUE TO APP',
                        style: AppTextStyles.labelLarge.copyWith(
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1,
                        ),
                      ),
                    ),
                  ).animate().fadeIn(delay: 800.ms).slideY(begin: 0.2),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _navigateToNext(BuildContext context) {
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => nextScreen,
        transitionsBuilder: (_, anim, __, child) => FadeTransition(opacity: anim, child: child),
        transitionDuration: const Duration(milliseconds: 600),
      ),
    );
  }
}
