import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/app_text_styles.dart';
import 'gold_button.dart';
import 'glass_container.dart';

class UpdateDialog extends StatelessWidget {
  final String latestVersion;
  final bool isMandatory;

  const UpdateDialog({
    super.key,
    required this.latestVersion,
    required this.isMandatory,
  });

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !isMandatory,
      child: Dialog(
        backgroundColor: Colors.transparent,
        elevation: 0,
        child: GlassContainer(
          borderRadius: 30,
          blur: 20,
          backgroundColor: AppColors.deepBlack.withOpacity(0.8),
          padding: const EdgeInsets.all(32),
          border: Border.all(color: AppColors.royalGold.withOpacity(0.2)),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Icon Header
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.royalGold.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.system_update_rounded, color: AppColors.royalGold, size: 40),
              ).animate(onPlay: (c) => c.repeat())
               .shimmer(duration: 2.seconds, color: Colors.white24),
              
              const SizedBox(height: 24),
              
              Text(
                'New Update Available',
                style: AppTextStyles.h3.copyWith(color: AppColors.pureWhite, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              
              const SizedBox(height: 12),
              
              Text(
                'Version $latestVersion is now available. Update now to enjoy the latest features and exclusive gold trading experience.',
                style: AppTextStyles.bodyMedium.copyWith(color: AppColors.offWhite, height: 1.5),
                textAlign: TextAlign.center,
              ),
              
              const SizedBox(height: 32),
              
              GoldButton(
                text: 'UPDATE NOW',
                onPressed: _launchStore,
              ),
              
              if (!isMandatory) ...[
                const SizedBox(height: 12),
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(
                    'MAYBE LATER',
                    style: AppTextStyles.labelMedium.copyWith(
                      color: AppColors.grey,
                      letterSpacing: 1,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _launchStore() async {
    // In a real app, you'd use a store URL from your config
    final url = Uri.parse('https://play.google.com/store/apps/details?id=com.royal.gold.traders');
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    }
  }
}
