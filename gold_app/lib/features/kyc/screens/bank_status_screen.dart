import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/formatters.dart';
import '../../../widgets/gold_app_bar.dart';
import '../../../widgets/gold_card.dart';
import '../../../widgets/status_badge.dart';
import '../providers/kyc_provider.dart';

class BankStatusScreen extends ConsumerStatefulWidget {
  BankStatusScreen({super.key}) ;

  @override
  ConsumerState<BankStatusScreen> createState() => _BankStatusScreenState();
}

class _BankStatusScreenState extends ConsumerState<BankStatusScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(kycProvider.notifier).loadStatus();
    });
  }

  @override
  Widget build(BuildContext context) {
    final kycState = ref.watch(kycProvider);

    return Scaffold(
      backgroundColor: AppColors.deepBlack,
      appBar:  GoldAppBar(title: 'Verification Status'),
      body: Container(
        decoration: BoxDecoration(gradient: AppColors.darkGradient),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              // KYC Status Card
              GoldCard(
                hasGoldBorder: true,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.fingerprint, color: AppColors.royalGold, size: 24),
                        SizedBox(width: 12),
                        Text('Aadhaar KYC', style: AppTextStyles.h4),
                        Spacer(),
                        StatusBadge(
                          status: statusFromString(kycState.kycData?.status ?? 'pending'),
                        ),
                      ],
                    ),
                    if (kycState.kycData != null) ...[
                      SizedBox(height: 16),
                      _InfoRow(
                        label: 'Aadhaar',
                        value: Formatters.maskedAadhaar(kycState.kycData!.aadhaarNumber),
                      ),
                      if (kycState.kycData!.name != null)
                        _InfoRow(label: 'Name', value: kycState.kycData!.name!),
                    ],
                  ],
                ),
              ).animate().fadeIn(duration: 500.ms).slideY(begin: 0.05),

              SizedBox(height: 16),

              // Bank Status Card
              GoldCard(
                hasGoldBorder: true,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.account_balance, color: AppColors.royalGold, size: 24),
                        SizedBox(width: 12),
                        Text('Bank Account', style: AppTextStyles.h4),
                        Spacer(),
                        StatusBadge(
                          status: statusFromString(kycState.bankData?.status ?? 'pending'),
                        ),
                      ],
                    ),
                    if (kycState.bankData != null) ...[
                      SizedBox(height: 16),
                      _InfoRow(
                        label: 'Account',
                        value: '****${kycState.bankData!.accountNumber.length > 4 ? kycState.bankData!.accountNumber.substring(kycState.bankData!.accountNumber.length - 4) : kycState.bankData!.accountNumber}',
                      ),
                      _InfoRow(label: 'IFSC', value: kycState.bankData!.ifscCode),
                      _InfoRow(label: 'Name', value: kycState.bankData!.accountHolderName),
                      if (kycState.bankData!.bankName != null)
                        _InfoRow(label: 'Bank', value: kycState.bankData!.bankName!),
                    ],
                  ],
                ),
              ).animate(delay: 200.ms).fadeIn(duration: 500.ms).slideY(begin: 0.05),

              SizedBox(height: 24),

              // Timeline
              GoldCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Verification Timeline', style: AppTextStyles.labelLarge),
                    SizedBox(height: 16),
                    _TimelineItem(
                      title: 'KYC Submitted',
                      isCompleted: true,
                      isFirst: true,
                    ),
                    _TimelineItem(
                      title: 'Identity Verified',
                      isCompleted: kycState.kycData?.isVerified ?? false,
                    ),
                    _TimelineItem(
                      title: 'Bank Submitted',
                      isCompleted: kycState.bankData != null,
                    ),
                    _TimelineItem(
                      title: 'Bank Verified',
                      isCompleted: kycState.bankData?.isVerified ?? false,
                      isLast: true,
                    ),
                  ],
                ),
              ).animate(delay: 400.ms).fadeIn(duration: 500.ms).slideY(begin: 0.05),
            ],
          ),
        ),
      ),
    ) ;
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;

  const _InfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          SizedBox(
            width: 80,
            child: Text(label, style: AppTextStyles.bodySmall),
          ),
          Expanded(
            child: Text(value, style: AppTextStyles.bodyMedium),
          ),
        ],
      ),
    );
  }
}

class _TimelineItem extends StatelessWidget {
  final String title;
  final bool isCompleted;
  final bool isFirst;
  final bool isLast;

  const _TimelineItem({
    required this.title,
    this.isCompleted = false,
    this.isFirst = false,
    this.isLast = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isCompleted
                    ? AppColors.success.withOpacity(0.2) : AppColors.darkGrey.withOpacity(0.3),
                border: Border.all(
                  color: isCompleted ? AppColors.success : AppColors.darkGrey,
                  width: 2,
                ),
              ),
              child: isCompleted
                  ? Icon(Icons.check, color: AppColors.success, size: 14)
                  : null,
            ),
            if (!isLast)
              Container(
                width: 2,
                height: 30,
                color: isCompleted ? AppColors.success.withOpacity(0.5) : AppColors.darkGrey,
              ),
          ],
        ),
        SizedBox(width: 12),
        Padding(
          padding: const EdgeInsets.only(top: 2),
          child: Text(
            title,
            style: AppTextStyles.bodyMedium.copyWith(
              color: isCompleted ? AppColors.pureWhite : AppColors.grey,
            ),
          ),
        ),
      ],
    );
  }
}
