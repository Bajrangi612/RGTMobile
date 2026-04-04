import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/formatters.dart';
import '../../../widgets/gold_card.dart';
import '../../../widgets/status_badge.dart';
import '../../auth/providers/auth_provider.dart';
import '../../kyc/screens/aadhaar_kyc_screen.dart';
import '../../kyc/screens/bank_status_screen.dart';
import '../../notifications/screens/transactions_screen.dart';
import 'settings_screen.dart';
import 'passkey_setup_screen.dart';
import 'legal_policy_screen.dart';
import '../../../core/providers/theme_provider.dart';
import '../../admin/screens/admin_login_screen.dart';

class ProfileScreen extends ConsumerWidget {
  ProfileScreen({super.key}) ;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authProvider).user;

    return Container(
      decoration: BoxDecoration(gradient: AppColors.darkGradient),
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              SizedBox(height: 16),
              Text('Profile', style: AppTextStyles.h2).animate().fadeIn(duration: 300.ms),
              SizedBox(height: 24),

              // Avatar & Name
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  gradient: AppColors.goldGradient,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.royalGold.withOpacity(0.25),
                      blurRadius: 20,
                    ),
                  ],
                ),
                child: Center(
                  child: Text(
                    user?.name.isNotEmpty == true ? user!.name[0].toUpperCase() : 'R',
                    style: AppTextStyles.h1.copyWith(color: AppColors.deepBlack),
                  ),
                ),
              ).animate().scale(duration: 400.ms, curve: Curves.elasticOut),

              SizedBox(height: 16),
              Text(user?.name ?? 'User', style: AppTextStyles.h3)
                  .animate(delay: 100.ms).fadeIn(),
              SizedBox(height: 4),
              Text(user?.phone ?? '', style: AppTextStyles.bodySmall)
                  .animate(delay: 150.ms).fadeIn(),

              SizedBox(height: 32),

              // Stats Row
              Row(
                children: [
                  Expanded(
                    child: GoldCard(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          Text(
                            '${user?.orderCount ?? 0}',
                            style: AppTextStyles.h3.copyWith(color: AppColors.royalGold),
                          ),
                          SizedBox(height: 4),
                          Text('Orders', style: AppTextStyles.caption),
                        ],
                      ),
                    ),
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: GoldCard(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          Text(
                            Formatters.currency(user?.totalInvestment ?? 0),
                            style: AppTextStyles.h3.copyWith(color: AppColors.success, fontSize: 18),
                          ),
                          SizedBox(height: 4),
                          Text('Invested', style: AppTextStyles.caption),
                        ],
                      ),
                    ),
                  ),
                ],
              ).animate(delay: 200.ms).fadeIn(duration: 400.ms),

              SizedBox(height: 24),

              // Verification Status
              GoldCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Verification', style: AppTextStyles.labelLarge),
                    SizedBox(height: 16),
                    _ProfileRow(
                      icon: Icons.fingerprint,
                      title: 'Aadhaar KYC',
                      trailing: StatusBadge(
                        status: statusFromString(user?.kycStatus ?? 'pending'),
                        small: true,
                      ),
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) =>  AadhaarKycScreen()),
                      ),
                    ),
                    Divider(height: 24, color: AppColors.darkGrey),
                    _ProfileRow(
                      icon: Icons.account_balance,
                      title: 'Bank Account',
                      trailing: StatusBadge(
                        status: statusFromString(user?.bankStatus ?? 'pending'),
                        small: true,
                      ),
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => BankStatusScreen()),
                      ),
                    ),
                    Divider(height: 24, color: AppColors.darkGrey),
                    _ProfileRow(
                      icon: Icons.lock_open_rounded,
                      title: 'Set up Passkey',
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => PasskeySetupScreen()),
                      ),
                    ),
                  ],
                ),
              ).animate(delay: 300.ms).fadeIn(duration: 400.ms),

              SizedBox(height: 16),


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
                    Divider(height: 24, color: AppColors.darkGrey),
                    _ProfileRow(
                      icon: Icons.settings,
                      title: 'Settings',
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => SettingsScreen()),
                      ),
                    ),
                    Divider(height: 24, color: AppColors.darkGrey),
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
                    Divider(height: 24, color: AppColors.darkGrey),
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

              SizedBox(height: 16),

              Center(
                child: GestureDetector(
                  onLongPress: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const AdminLoginScreen()),
                  ),
                  child: Text(
                    'Version 1.0.1 (Production)',
                    style: AppTextStyles.caption.copyWith(color: AppColors.grey.withOpacity(0.4)),
                  ),
                ),
              ),

              SizedBox(height: 40),
            ],
          ),
        ),
      ),
    ) ;
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
