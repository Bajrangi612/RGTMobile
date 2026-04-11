import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/formatters.dart';
import '../../../widgets/gold_card.dart';
import '../providers/admin_provider.dart';

class AdminTransactionsScreen extends ConsumerWidget {
  const AdminTransactionsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final transactions = ref.watch(adminProvider).allTransactions;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('ALL TRANSACTIONS', style: AppTextStyles.h4),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        iconTheme: IconThemeData(color: AppColors.royalGold),
      ),
      body: Column(
        children: [
          /// 📊 Summary Card
          Padding(
            padding: const EdgeInsets.all(24),
            child: GoldCard(
              padding: const EdgeInsets.all(20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _SummaryStat(
                    label: 'System Volume',
                    value: transactions.fold(0.0, (sum, item) => sum + (double.tryParse(item['amount']?.toString() ?? '0.0') ?? 0.0)),
                    color: AppColors.royalGold,
                  ),
                  _SummaryStat(
                    label: 'Count',
                    value: transactions.length.toDouble(),
                    isCurrency: false,
                    color: AppColors.pureWhite,
                  ),
                ],
              ),
            ),
          ).animate().fadeIn().scaleX(begin: 0.9),

          /// 📜 Transaction List
          Expanded(
            child: transactions.isEmpty
                ? _EmptyTransactions()
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    itemCount: transactions.length,
                    itemBuilder: (context, index) {
                      final txn = transactions[index];
                      return _TransactionCard(txn: txn)
                          .animate(delay: (index * 50).ms)
                          .fadeIn()
                          .slideY(begin: 0.1);
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

class _TransactionCard extends StatefulWidget {
  final Map<String, dynamic> txn;
  const _TransactionCard({required this.txn});

  @override
  State<_TransactionCard> createState() => _TransactionCardState();
}

class _TransactionCardState extends State<_TransactionCard> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    final type = widget.txn['type']?.toString().toLowerCase() ?? '';
    final isPurchase = type == 'purchase';
    final user = widget.txn['user'] ?? {};
    
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: AppColors.cardDark.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.royalGold.withValues(alpha: _isExpanded ? 0.2 : 0.05)),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => setState(() => _isExpanded = !_isExpanded),
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: _getColor(type).withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(_getIcon(type), color: _getColor(type), size: 20),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            user['name'] ?? 'User Activity',
                            style: AppTextStyles.labelSmall.copyWith(color: AppColors.grey),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            widget.txn['description'] ?? 'No description',
                            style: AppTextStyles.bodyMedium,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            Formatters.dateTime(widget.txn['createdAt'].toString()),
                            style: AppTextStyles.caption.copyWith(fontSize: 9),
                          ),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          Formatters.currency(double.tryParse(widget.txn['amount']?.toString() ?? '0.0') ?? 0.0),
                          style: AppTextStyles.labelLarge.copyWith(
                            color: isPurchase ? AppColors.pureWhite : AppColors.success,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        if (widget.txn['status'] != null)
                          Row(
                            children: [
                              Text(
                                widget.txn['status'].toString().toUpperCase(),
                                style: TextStyle(
                                  fontSize: 8,
                                  color: _getColor(type).withValues(alpha: 0.7),
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(width: 4),
                              Icon(_isExpanded ? Icons.keyboard_arrow_up_rounded : Icons.keyboard_arrow_down_rounded, size: 12, color: AppColors.grey),
                            ],
                          ),
                      ],
                    ),
                  ],
                ),
                
                if (_isExpanded) ...[
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 12),
                    child: Divider(color: Colors.white10),
                  ),
                  _DetailRow(label: 'Full Transaction ID', value: widget.txn['id']?.toString() ?? 'N/A'),
                  _DetailRow(label: 'Customer Name', value: user['name'] ?? 'N/A'),
                  _DetailRow(label: 'Customer Phone', value: user['phone'] ?? 'N/A'),
                  _DetailRow(label: 'Transaction Type', value: widget.txn['type']?.toString().toUpperCase() ?? 'N/A'),
                  _DetailRow(label: 'Payment Mode', value: widget.txn['provider']?.toString().toUpperCase() ?? 'WALLET'),
                  _DetailRow(label: 'Precise Timestamp', value: widget.txn['createdAt'] != null ? Formatters.dateTime(widget.txn['createdAt']) : 'N/A'),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  IconData _getIcon(String type) {
    switch (type) {
      case 'purchase': return Icons.shopping_cart_rounded;
      case 'referral': return Icons.card_giftcard_rounded;
      case 'refund': return Icons.replay_rounded;
      case 'deposit': return Icons.add_circle_outline;
      case 'withdrawal': return Icons.remove_circle_outline;
      default: return Icons.account_balance_wallet_rounded;
    }
  }

  Color _getColor(String type) {
    switch (type) {
      case 'purchase': return AppColors.info;
      case 'referral': return AppColors.royalGold;
      case 'refund': return AppColors.error;
      case 'deposit': return AppColors.success;
      case 'withdrawal': return AppColors.warning;
      default: return AppColors.grey;
    }
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;
  const _DetailRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: AppTextStyles.caption.copyWith(fontSize: 10, color: AppColors.grey)),
          const SizedBox(width: 16),
          Flexible(
            child: Text(
              value, 
              style: AppTextStyles.bodySmall.copyWith(fontSize: 10, fontWeight: FontWeight.bold),
              textAlign: TextAlign.end,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

class _SummaryStat extends StatelessWidget {
  final String label;
  final double value;
  final Color color;
  final bool isCurrency;
  const _SummaryStat({required this.label, required this.value, required this.color, this.isCurrency = true});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(label, style: AppTextStyles.caption.copyWith(color: AppColors.grey)),
        const SizedBox(height: 4),
        Text(
          isCurrency ? Formatters.currency(value) : value.toInt().toString(),
          style: AppTextStyles.h4.copyWith(color: color),
        ),
      ],
    );
  }
}

class _EmptyTransactions extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.history_rounded, size: 64, color: AppColors.grey.withValues(alpha: 0.2)),
          const SizedBox(height: 16),
          Text('No transactions yet in the system.', style: AppTextStyles.bodyMedium.copyWith(color: AppColors.grey)),
        ],
      ),
    );
  }
}
