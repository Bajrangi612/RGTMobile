import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../widgets/gold_card.dart';
import '../providers/admin_provider.dart';
import 'admin_user_detail_screen.dart';

class AdminUserManager extends ConsumerWidget {
  const AdminUserManager({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final adminState = ref.watch(adminProvider);
    final users = adminState.users;

    return Scaffold(
      backgroundColor: AppColors.deepBlack,
      appBar: AppBar(
        title: Text('User Management', style: AppTextStyles.h4),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        iconTheme: IconThemeData(color: AppColors.royalGold),
      ),
      body: Container(
        decoration: BoxDecoration(gradient: AppColors.darkGradient),
        child: users.isEmpty
            ? Center(child: Text('No users found', style: AppTextStyles.labelLarge.copyWith(color: Colors.white24)))
            : ListView.builder(
                padding: const EdgeInsets.all(20),
                itemCount: users.length,
                itemBuilder: (context, index) {
                  final user = users[index];
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: GoldCard(
                      child: ListTile(
                        onTap: () => Navigator.of(context).push(
                          MaterialPageRoute(builder: (_) => AdminUserDetailScreen(user: user)),
                        ),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        leading: CircleAvatar(
                          backgroundColor: AppColors.royalGold.withOpacity(0.1),
                          child: Icon(Icons.person, color: AppColors.royalGold, size: 20),
                        ),
                        title: Row(
                          children: [
                            Text(user['name'] ?? 'N/A', style: AppTextStyles.labelLarge),
                            const SizedBox(width: 8),
                            _StatusBadge(status: user['status'] ?? 'active'),
                          ],
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 4),
                            Text(user['email'] ?? 'N/A', style: AppTextStyles.caption.copyWith(color: Colors.white38)),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Text('KYC: ', style: AppTextStyles.caption.copyWith(fontWeight: FontWeight.bold, fontSize: 10)),
                                _KYCBadge(status: user['kycStatus'] ?? 'pending'),
                              ],
                            ),
                          ],
                        ),
                        trailing: const Icon(Icons.chevron_right, color: Colors.white24),
                      ),
                    ),
                  ).animate().fadeIn(delay: (index * 50).ms).slideX(begin: 0.1);
                },
              ),
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final String status;
  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    final isActive = status == 'active';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: (isActive ? AppColors.success : AppColors.error).withOpacity(0.1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        status.toUpperCase(),
        style: AppTextStyles.caption.copyWith(
          color: isActive ? AppColors.success : AppColors.error,
          fontSize: 7,
          fontWeight: FontWeight.bold,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}

class _KYCBadge extends StatelessWidget {
  final String status;
  const _KYCBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    Color color;
    switch (status) {
      case 'verified':
        color = AppColors.success;
        break;
      case 'pending':
        color = AppColors.royalGold;
        break;
      case 'rejected':
        color = AppColors.error;
        break;
      default:
        color = AppColors.grey;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withOpacity(0.3), width: 0.5),
      ),
      child: Text(
        status.toUpperCase(),
        style: AppTextStyles.caption.copyWith(
          color: color,
          fontSize: 7,
          fontWeight: FontWeight.bold,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}
