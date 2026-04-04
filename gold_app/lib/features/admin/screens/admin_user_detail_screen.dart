import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../widgets/gold_card.dart';
import '../providers/admin_provider.dart';

class AdminUserDetailScreen extends ConsumerWidget {
  final Map<String, dynamic> user;

  const AdminUserDetailScreen({super.key, required this.user});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final adminState = ref.watch(adminProvider);

    return Scaffold(
      backgroundColor: AppColors.deepBlack,
      appBar: AppBar(
        title: Text(user['name']?.toUpperCase() ?? 'USER PROFILE', style: AppTextStyles.h4),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        iconTheme: IconThemeData(color: AppColors.royalGold),
      ),
      body: Container(
        decoration: BoxDecoration(gradient: AppColors.darkGradient),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              /// 👤 User Info Card
              GoldCard(
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 30,
                      backgroundColor: AppColors.royalGold.withOpacity(0.1),
                      child: Icon(Icons.person, color: AppColors.royalGold, size: 30),
                    ),
                    const SizedBox(width: 20),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(user['name'] ?? 'N/A', style: AppTextStyles.h4),
                          Text(user['email'] ?? 'N/A', style: AppTextStyles.caption),
                          const SizedBox(height: 8),
                          _KycStatusBanner(status: user['kycStatus']),
                        ],
                      ),
                    ),
                  ],
                ),
              ).animate().fadeIn().slideY(begin: 0.1),

              const SizedBox(height: 24),

              /// 📄 Document Review Section
              Text('COMPLIANCE DOCUMENTS', style: AppTextStyles.labelLarge.copyWith(color: AppColors.royalGold, letterSpacing: 1.2)),
              const SizedBox(height: 16),
              
              _DocumentCard(
                label: 'Aadhaar Card',
                idValue: user['aadharNo'] ?? 'Not provided',
                placeholderColor: Colors.blueAccent,
              ),
              const SizedBox(height: 16),
              _DocumentCard(
                label: 'PAN Card',
                idValue: user['panNo'] ?? 'Not provided',
                placeholderColor: Colors.orangeAccent,
              ),

              const SizedBox(height: 32),

              /// ✅ KYC Actions (Only if PENDING or REJECTED)
              if (user['kycStatus'] != 'verified')
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        onPressed: adminState.isLoading 
                          ? null 
                          : () => _updateKyc(context, ref, 'rejected'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.redAccent.withOpacity(0.1),
                          foregroundColor: Colors.redAccent,
                          side: const BorderSide(color: Colors.redAccent),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                        child: const Text('REJECT KYC'),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: adminState.isLoading 
                          ? null 
                          : () => _updateKyc(context, ref, 'verified'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.success,
                          foregroundColor: Colors.black,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                        child: const Text('VERIFY KYC', style: TextStyle(fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ],
                ).animate().fadeIn(delay: 400.ms),
              
              const SizedBox(height: 20),
              
              if (user['kycStatus'] == 'verified')
                Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    decoration: BoxDecoration(
                      color: AppColors.success.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.success),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.verified, color: AppColors.success, size: 20),
                        const SizedBox(width: 10),
                        Text('ENTITY FULLY VERIFIED', style: AppTextStyles.labelLarge.copyWith(color: AppColors.success)),
                      ],
                    ),
                  ),
                ),

              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _updateKyc(BuildContext context, WidgetRef ref, String status) async {
    await ref.read(adminProvider.notifier).updateKycStatus(user['id'], status);
    if (context.mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('User KYC set to ${status.toUpperCase()}')),
      );
    }
  }
}

class _KycStatusBanner extends StatelessWidget {
  final String? status;
  const _KycStatusBanner({required this.status});

  @override
  Widget build(BuildContext context) {
    Color color = AppColors.royalGold;
    if (status == 'verified') color = AppColors.success;
    if (status == 'rejected') color = AppColors.error;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(
        status?.toUpperCase() ?? 'PENDING',
        style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 0.5),
      ),
    );
  }
}

class _DocumentCard extends StatelessWidget {
  final String label;
  final String idValue;
  final Color placeholderColor;

  const _DocumentCard({
    required this.label,
    required this.idValue,
    required this.placeholderColor,
  });

  @override
  Widget build(BuildContext context) {
    return GoldCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(label, style: AppTextStyles.labelMedium),
              Text(idValue, style: AppTextStyles.labelSmall.copyWith(color: AppColors.royalGold)),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            height: 180,
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.05),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white10),
            ),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.image_outlined, size: 48, color: placeholderColor.withOpacity(0.3)),
                  const SizedBox(height: 8),
                  Text('Official Document Photo', style: AppTextStyles.caption.copyWith(color: Colors.white24)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
