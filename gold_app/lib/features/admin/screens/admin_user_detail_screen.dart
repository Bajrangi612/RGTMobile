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
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(user['name']?.toUpperCase() ?? 'USER PROFILE', style: AppTextStyles.h4),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        iconTheme: IconThemeData(color: AppColors.royalGold),
      ),
      body: Container(
        decoration: BoxDecoration(color: AppColors.background),
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
                      backgroundColor: AppColors.royalGold.withValues(alpha: 0.1),
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

              /// ✅ KYC Actions
              if (user['kycStatus'] != 'VERIFIED')
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: adminState.isLoading 
                          ? null 
                          : () => _updateKyc(context, ref, 'REJECTED'),
                        style: OutlinedButton.styleFrom(
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
                          : () => _updateKyc(context, ref, 'VERIFIED'),
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

              const SizedBox(height: 32),

              /// 🏦 Bank Details Review
              Text('BANK ACCOUNT VERIFICATION', style: AppTextStyles.labelLarge.copyWith(color: AppColors.royalGold, letterSpacing: 1.2)),
              const SizedBox(height: 16),
              
              GoldCard(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    _InfoRow('Acc Name', user['accountName'] ?? 'N/A'),
                    _InfoRow('Acc Number', user['accountNo'] ?? 'N/A'),
                    _InfoRow('IFSC Code', user['ifscCode'] ?? 'N/A'),
                    _InfoRow('Nominee', user['nomineeName'] ?? 'N/A'),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Text('Bank Status: ', style: AppTextStyles.caption),
                        _KycStatusBanner(status: user['bankStatus']),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              if (user['bankStatus'] != 'VERIFIED')
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: adminState.isLoading ? null : () => _updateBank(context, ref, 'REJECTED'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.redAccent,
                          side: const BorderSide(color: Colors.redAccent),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                        child: const Text('REJECT BANK'),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: adminState.isLoading ? null : () => _updateBank(context, ref, 'VERIFIED'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.success,
                          foregroundColor: Colors.black,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                        child: const Text('APPROVE BANK', style: TextStyle(fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ],
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
        SnackBar(content: Text('User KYC set to $status')),
      );
    }
  }

  Future<void> _updateBank(BuildContext context, WidgetRef ref, String status) async {
    await ref.read(adminProvider.notifier).updateBankStatus(user['id'], status);
    if (context.mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Bank details set to $status')),
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
    if (status?.toUpperCase() == 'VERIFIED') color = AppColors.success;
    if (status?.toUpperCase() == 'REJECTED') color = AppColors.error;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.3)),
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
              color: AppColors.pureWhite.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.pureWhite.withValues(alpha: 0.1)),
            ),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.image_outlined, size: 48, color: placeholderColor.withValues(alpha: 0.3)),
                  const SizedBox(height: 8),
                  Text('Official Document Photo', style: AppTextStyles.caption.copyWith(color: AppColors.pureWhite.withValues(alpha: 0.3))),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  const _InfoRow(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: AppTextStyles.bodySmall),
          Text(value, style: AppTextStyles.labelLarge),
        ],
      ),
    );
  }
}
