import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter/services.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/formatters.dart';
import '../../../widgets/gold_card.dart';
import '../../../widgets/gold_app_bar.dart';
import '../../../widgets/status_badge.dart';
import '../../auth/providers/auth_provider.dart';
import '../../kyc/screens/aadhaar_kyc_screen.dart';
import '../../kyc/screens/bank_status_screen.dart';
import '../../notifications/screens/transactions_screen.dart';
import 'settings_screen.dart';
import 'passkey_setup_screen.dart';
import 'legal_policy_screen.dart';
import 'edit_profile_screen.dart';
import 'bank_details_screen.dart';
import '../../admin/screens/admin_login_screen.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authProvider).user;

    return Scaffold(
      backgroundColor: AppColors.deepBlack,
      appBar: GoldAppBar(title: 'Profile'),
      body: Container(
        decoration: BoxDecoration(gradient: AppColors.darkGradient),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                const SizedBox(height: 16),
                
                // Avatar & Name
                Container(
                  width: 90,
                  height: 90,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFFFFD700), Color(0xFFFF8C00)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFFFD700).withValues(alpha: 0.3),
                        blurRadius: 30,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: Center(
                    child: Text(
                      user?.name.isNotEmpty == true ? user!.name[0].toUpperCase() : 'R',
                      style: AppTextStyles.h1.copyWith(color: AppColors.deepBlack, fontWeight: FontWeight.w900, fontSize: 36),
                    ),
                  ),
                ).animate().scale(duration: 400.ms, curve: Curves.elasticOut),

                const SizedBox(height: 16),
                Text(user?.name ?? 'User', style: AppTextStyles.h3)
                    .animate(delay: 100.ms).fadeIn(),
                const SizedBox(height: 4),
                Text(user?.phone ?? '', style: AppTextStyles.bodySmall)
                    .animate(delay: 150.ms).fadeIn(),

                const SizedBox(height: 32),

                // Stats Row
                Row(
                  children: [
                    Expanded(
                      child: GoldCard(
                        isVibrant: true,
                        gradient: const LinearGradient(
                          colors: [Color(0xFF2E376E), Color(0xFF151B40)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          children: [
                            Text(
                              '${user?.orderCount ?? 0}',
                              style: AppTextStyles.h3.copyWith(color: Color(0xFF00E5FF), fontWeight: FontWeight.w900),
                            ),
                            const SizedBox(height: 4),
                            Text('Purchases', style: AppTextStyles.caption.copyWith(color: Colors.white70, fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: GoldCard(
                        isVibrant: true,
                        gradient: const LinearGradient(
                          colors: [Color(0xFF00C853), Color(0xFF00E5FF)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          children: [
                            Text(
                              Formatters.currency(user?.totalCollectionValue ?? 0),
                              style: AppTextStyles.h3.copyWith(color: AppColors.deepBlack, fontSize: 16, fontWeight: FontWeight.w900),
                            ),
                            const SizedBox(height: 4),
                            Text('Total Value', style: AppTextStyles.caption.copyWith(color: AppColors.deepBlack.withValues(alpha: 0.6), fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ),
                    ),
                  ],
                ).animate(delay: 200.ms).fadeIn(duration: 400.ms),

                const SizedBox(height: 24),

                // Verification Status
                GoldCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Verification', style: AppTextStyles.labelLarge),
                      const SizedBox(height: 16),
                      _ProfileRow(
                        icon: Icons.person_outline_rounded,
                        title: 'Personal Information',
                        onTap: () => Navigator.of(context).push(
                          MaterialPageRoute(builder: (_) => const EditProfileScreen()),
                        ),
                      ),
                      const Divider(height: 24, color: AppColors.darkGrey),
                      _ProfileRow(
                        icon: Icons.account_balance,
                        title: 'Bank Account / Refunds',
                        trailing: StatusBadge(
                          status: statusFromString(user?.bankStatus ?? 'pending'),
                          small: true,
                        ),
                        onTap: () => Navigator.of(context).push(
                          MaterialPageRoute(builder: (_) => BankDetailsScreen()),
                        ),
                      ),
                      const Divider(height: 24, color: AppColors.darkGrey),
                      _ProfileRow(
                        icon: user?.pin != null ? Icons.lock_rounded : Icons.lock_open_rounded,
                        title: user?.pin != null ? 'Security PIN' : 'Set up Passkey',
                        onTap: () => Navigator.of(context).push(
                          MaterialPageRoute(builder: (_) => const PasskeySetupScreen()),
                        ),
                      ),

                    ],
                  ),
                ).animate(delay: 300.ms).fadeIn(duration: 400.ms),

                const SizedBox(height: 32),

                // Menu Items
                GoldCard(
                  child: Column(
                    children: [
                      _ProfileRow(
                        icon: Icons.receipt_long,
                        title: 'Transaction History',
                        onTap: () => Navigator.of(context).push(
                          MaterialPageRoute(builder: (_) => TransactionsScreen()),
                        ),
                      ),
                      const Divider(height: 24, color: AppColors.darkGrey),
                      if (user?.isAdmin ?? false) ...[
                        _ProfileRow(
                          icon: Icons.admin_panel_settings,
                          title: 'Admin Control Panel',
                          onTap: () => Navigator.of(context).push(
                            MaterialPageRoute(builder: (_) => const AdminLoginScreen()),
                          ),
                        ),
                        const Divider(height: 24, color: AppColors.darkGrey),
                      ],
                      _ProfileRow(
                        icon: Icons.settings,
                        title: 'Settings',
                        onTap: () => Navigator.of(context).push(
                          MaterialPageRoute(builder: (_) => SettingsScreen()),
                        ),
                      ),
                      const Divider(height: 24, color: AppColors.darkGrey),
                      _ProfileRow(
                        icon: Icons.info_outline,
                        title: 'Terms of Service',
                        onTap: () => Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => LegalPolicyScreen(
                              title: 'Terms of Service',
                              content: LegalPolicyScreen.termsContent,
                            ),
                          ),
                        ),
                      ),
                      const Divider(height: 24, color: AppColors.darkGrey),
                      _ProfileRow(
                        icon: Icons.privacy_tip_outlined,
                        title: 'Privacy Policy',
                        onTap: () => Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => LegalPolicyScreen(
                              title: 'Privacy Policy',
                              content: LegalPolicyScreen.privacyContent,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ).animate(delay: 400.ms).fadeIn(duration: 400.ms),

                const SizedBox(height: 16),

                Center(
                  child: GestureDetector(
                    onLongPress: () => Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const AdminLoginScreen()),
                    ),
                    child: Text(
                      'Version 1.0.1 (Production)',
                      style: AppTextStyles.caption.copyWith(color: AppColors.grey.withValues(alpha: 0.4)),
                    ),
                  ),
                ),

                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ProfileRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final Widget? trailing;
  final VoidCallback onTap;

  const _ProfileRow({
    required this.icon,
    required this.title,
    this.trailing,
    required this.onTap,
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
          Expanded(child: Text(title, style: AppTextStyles.bodyMedium)),
          trailing ?? Icon(Icons.chevron_right, color: AppColors.grey, size: 20),
        ],
      ),
    );
  }
}
