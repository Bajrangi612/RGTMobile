import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/extensions.dart';
import '../../../widgets/gold_card.dart';
import '../../../widgets/gold_app_bar.dart';
import '../../../widgets/gold_button.dart';
import '../../auth/providers/auth_provider.dart';
import '../../auth/screens/login_screen.dart';

class SettingsScreen extends ConsumerWidget {
  SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: AppColors.deepBlack,
      appBar: GoldAppBar(title: 'Settings'),
      body: Container(
        decoration: BoxDecoration(gradient: AppColors.darkGradient),
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            // Passkey Section
            GoldCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.lock_rounded, color: AppColors.royalGold, size: 22),
                      SizedBox(width: 12),
                      Text('Passkey', style: AppTextStyles.labelLarge),
                    ],
                  ),
                  SizedBox(height: 12),
                  Text(
                    'Set up a 4-digit passkey for secure transactions like reselling gold.',
                    style: AppTextStyles.bodySmall,
                  ),
                  SizedBox(height: 16),
                  GoldButton(
                    text: 'Set Up Passkey',
                    isOutlined: true,
                    onPressed: () {
                      context.showSuccessSnackBar('Passkey setup coming soon!') ;
                    },
                    icon: Icons.vpn_key,
                  ),
                ],
              ),
            ).animate().fadeIn(duration: 400.ms),

            SizedBox(height: 16),

            // Security
            GoldCard(
              child: Column(
                children: [
                  _SettingsRow(
                    icon: Icons.security,
                    title: 'Two-Factor Authentication',
                    subtitle: 'Enabled via OTP',
                    trailing: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.success.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        'Active',
                        style: AppTextStyles.caption.copyWith(color: AppColors.success),
                      ),
                    ),
                  ),
                  Divider(height: 24, color: AppColors.darkGrey),
                  _SettingsRow(
                    icon: Icons.notifications_outlined,
                    title: 'Notifications',
                    subtitle: 'Order updates & offers',
                    trailing: Switch(
                      value: true,
                      onChanged: (_) {},
                      activeColor: AppColors.royalGold,
                    ),
                  ),
                ],
              ),
            ).animate(delay: 200.ms).fadeIn(duration: 400.ms),

            SizedBox(height: 16),

            // App Info
            GoldCard(
              child: Column(
                children: [
                  _SettingsRow(
                    icon: Icons.description_outlined,
                    title: 'Terms of Service',
                    onTap: () {},
                  ),
                  Divider(height: 24, color: AppColors.darkGrey),
                  _SettingsRow(
                    icon: Icons.privacy_tip_outlined,
                    title: 'Privacy Policy',
                    onTap: () {},
                  ),
                  Divider(height: 24, color: AppColors.darkGrey),
                  _SettingsRow(
                    icon: Icons.info_outline,
                    title: 'App Version',
                    trailing: Text('1.0.0', style: AppTextStyles.bodySmall),
                  ),
                ],
              ),
            ).animate(delay: 300.ms).fadeIn(duration: 400.ms),

            SizedBox(height: 32),

            // Logout
            GoldButton(
              text: 'Logout',
              isOutlined: true,
              onPressed: () async {
                final confirm = await showDialog<bool>(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: Text('Logout?'),
                    content: Text('Are you sure you want to logout?'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(ctx, false),
                        child: Text('Cancel'),
                      ),
                      ElevatedButton(
                        onPressed: () => Navigator.pop(ctx, true),
                        child: Text('Logout'),
                      ),
                    ],
                  ),
                );
                if (confirm == true) {
                  await ref.read(authProvider.notifier).logout();
                  if (context.mounted) {
                    Navigator.of(context).pushAndRemoveUntil(
                      MaterialPageRoute(builder: (_) =>  LoginScreen()),
                      (route) => false,
                    ) ;
                  }
                }
              },
              icon: Icons.logout,
            ).animate(delay: 400.ms).fadeIn(duration: 400.ms),

            SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}

class _SettingsRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;

  const _SettingsRow({
    required this.icon,
    required this.title,
    this.subtitle,
    this.trailing,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Row(
        children: [
          Icon(icon, color: AppColors.royalGold, size: 22),
          SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: AppTextStyles.bodyMedium),
                if (subtitle != null)
                  Text(subtitle!, style: AppTextStyles.caption),
              ],
            ),
          ),
          trailing ?? Icon(Icons.chevron_right, color: AppColors.grey, size: 20),
        ],
      ),
    );
  }
}
