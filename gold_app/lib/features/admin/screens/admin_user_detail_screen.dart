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
          child: Padding(
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
                          Text(user['phone'] ?? (user['email'] ?? 'N/A'), style: AppTextStyles.caption),
                          const SizedBox(height: 8),
                          // KYC Status Banner removed
                        ],
                      ),
                    ),
                  ],
                ),
              ).animate().fadeIn().slideY(begin: 0.1),

              const SizedBox(height: 16),
              
              /// 🏠 Residential Intelligence
              GoldCard(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.home_work_outlined, color: AppColors.royalGold, size: 18),
                        const SizedBox(width: 8),
                        Text('RESIDENTIAL INTELLIGENCE', style: AppTextStyles.labelSmall.copyWith(color: AppColors.royalGold, letterSpacing: 1.2)),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      user['address'] ?? 'Address not updated by user',
                      style: AppTextStyles.bodyMedium.copyWith(height: 1.5),
                    ),
                  ],
                ),
              ).animate(delay: 100.ms).fadeIn(),

              const SizedBox(height: 24),

              /// 💰 Financial Intelligence
              Text('FINANCIAL INTELLIGENCE', style: AppTextStyles.labelLarge.copyWith(color: AppColors.royalGold, letterSpacing: 1.2)),
              const SizedBox(height: 16),
              GoldCard(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    _InfoRow('Wallet Balance', '₹${user['wallet']?['balance'] ?? '0.00'}'),
                    _InfoRow('Wallet Balance', '₹${user['wallet']?['balance'] ?? '0.00'}', isGold: true),
                    const Divider(color: Colors.white10),
                    _InfoRow('Total Assets', '₹${user['totalCollectionValue'] ?? '0.00'}'),
                  ],
                ),
              ).animate(delay: 200.ms).fadeIn(),

              const SizedBox(height: 24),

              /// 👥 Referral Genealogy
              Text('REFERRAL GENEALOGY', style: AppTextStyles.labelLarge.copyWith(color: AppColors.royalGold, letterSpacing: 1.2)),
              const SizedBox(height: 16),
              GoldCard(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    _InfoRow('Personal Code', user['referralCode'] ?? 'N/A', isGold: true),
                    _InfoRow('Invited By (ID)', user['referrerId'] ?? 'DIRECT', isItalic: user['referrerId'] == null),
                  ],
                ),
              ).animate(delay: 300.ms).fadeIn(),

              const SizedBox(height: 32),

              // Compliance Documents section removed
              
              const SizedBox(height: 32),

              // KYC Actions Row removed
              
              const SizedBox(height: 16),

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
    ),
  );
}

// _updateKyc method removed as part of KYC cleanup.

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

// _KycStatusBanner removed.

// _DocumentCard removed.

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  final bool isGold;
  final bool isItalic;
  const _InfoRow(this.label, this.value, {this.isGold = false, this.isItalic = false});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: AppTextStyles.bodySmall),
          Text(
            value, 
            style: AppTextStyles.labelLarge.copyWith(
              color: isGold ? AppColors.royalGold : null,
              fontStyle: isItalic ? FontStyle.italic : null,
            ),
          ),
        ],
      ),
    );
  }
}
