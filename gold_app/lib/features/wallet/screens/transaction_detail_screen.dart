import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/formatters.dart';
import '../../../widgets/gold_card.dart';
import '../../../widgets/gold_app_bar.dart';

class TransactionDetailScreen extends StatelessWidget {
  final String title;
  final String date;
  final double amount;
  final bool isCredit;
  final String? txnId;
  final String status;
  final String? invoiceNo;
  final String? mode;
  final Map<String, dynamic>? metadata;

  const TransactionDetailScreen({
    super.key,
    required this.title,
    required this.date,
    required this.amount,
    required this.isCredit,
    this.txnId,
    required this.status,
    this.invoiceNo,
    this.mode,
    this.metadata,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.deepBlack,
      appBar: GoldAppBar(title: 'Transaction Details'),
      body: Container(
        decoration: BoxDecoration(gradient: AppColors.darkGradient),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              const SizedBox(height: 20),
              
              // Status & Amount Card
              GoldCard(
                isVibrant: true,
                hasGlow: true,
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: (isCredit ? AppColors.success : AppColors.error).withValues(alpha: 0.15),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        isCredit ? Icons.arrow_downward_rounded : Icons.arrow_upward_rounded,
                        color: isCredit ? AppColors.success : AppColors.error,
                        size: 32,
                      ),
                    ).animate().scale(duration: 500.ms, curve: Curves.elasticOut),
                    const SizedBox(height: 16),
                    Text(
                      '${isCredit ? "+" : "-"} ${Formatters.currency(amount)}',
                      style: AppTextStyles.h1.copyWith(
                        color: isCredit ? AppColors.success : AppColors.error,
                        fontSize: 36,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: (status == 'COMPLETED' ? AppColors.success : AppColors.warning).withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: (status == 'COMPLETED' ? AppColors.success : AppColors.warning).withValues(alpha: 0.3),
                        ),
                      ),
                      child: Text(
                        status.toUpperCase(),
                        style: AppTextStyles.caption.copyWith(
                          color: status == 'COMPLETED' ? AppColors.success : AppColors.warning,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1,
                        ),
                      ),
                    ),
                  ],
                ),
              ).animate().fadeIn().slideY(begin: 0.1),
              
              const SizedBox(height: 24),
              
              // Information Section
              GoldCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('INFORMATION', style: AppTextStyles.caption.copyWith(color: AppColors.royalGold, letterSpacing: 1.5)),
                    const SizedBox(height: 20),
                    _DetailRow(label: 'Description', value: title),
                    _DetailRow(label: 'Type', value: mode?.toUpperCase() ?? 'TRANSACTION'),
                    _DetailRow(label: 'Date', value: date),
                    if (txnId != null) _DetailRow(label: 'Transaction ID', value: txnId!),
                    if (invoiceNo != null) _DetailRow(label: 'Invoice Number', value: invoiceNo!),
                  ],
                ),
              ).animate(delay: 100.ms).fadeIn().slideY(begin: 0.1),
              
              const SizedBox(height: 16),
              
              // Extended Metadata Section (if any)
              if (metadata != null && metadata!.isNotEmpty)
                GoldCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('METADATA', style: AppTextStyles.caption.copyWith(color: AppColors.royalGold, letterSpacing: 1.5)),
                      const SizedBox(height: 20),
                      ...metadata!.entries.map((e) => _DetailRow(
                        label: e.key[0].toUpperCase() + e.key.substring(1), 
                        value: e.value.toString(),
                      )),
                    ],
                  ),
                ).animate(delay: 200.ms).fadeIn().slideY(begin: 0.1),

              const SizedBox(height: 48),
              
              // Help Button
              TextButton.icon(
                onPressed: () {},
                icon: Icon(Icons.help_outline_rounded, color: AppColors.grey),

                label: Text('Need help with this transaction?', style: AppTextStyles.bodySmall.copyWith(color: AppColors.grey)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;
  const _DetailRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: AppTextStyles.caption.copyWith(color: AppColors.grey)),
          const SizedBox(height: 4),
          Text(value, style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}
