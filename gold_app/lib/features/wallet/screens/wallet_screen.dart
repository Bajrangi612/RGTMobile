import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/formatters.dart';
import '../../../widgets/gold_card.dart';
import '../../../widgets/gold_button.dart';
import '../../auth/providers/auth_provider.dart';
import '../../wallet/providers/wallet_provider.dart';
import '../../../widgets/shimmer_loader.dart';
import '../../../core/providers/settings_provider.dart';

class WalletScreen extends ConsumerStatefulWidget {
  const WalletScreen({super.key});

  @override
  ConsumerState<WalletScreen> createState() => _WalletScreenState();
}

class _WalletScreenState extends ConsumerState<WalletScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(walletProvider.notifier).loadWalletDetails();
    });
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authProvider).user;
    final walletState = ref.watch(walletProvider);
    final wallet = user?.wallet;
    final transactions = walletState.transactions.take(5).toList();

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Container(
        decoration: BoxDecoration(gradient: AppColors.darkGradient),
        child: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {
            await ref.read(walletProvider.notifier).loadWalletDetails();
            await ref.read(authProvider.notifier).getCurrentUser();
          },
          color: AppColors.royalGold,
          backgroundColor: AppColors.surface,
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
            slivers: [
              // Custom Gold Header
              SliverAppBar(
                expandedHeight: 120,
                backgroundColor: Colors.transparent,
                elevation: 0,
                leading: IconButton(
                  icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 20),
                  onPressed: () => Navigator.pop(context),
                ),
                flexibleSpace: FlexibleSpaceBar(
                  centerTitle: true,
                  title: Text(
                    'ACCOUNT BALANCE',
                    style: AppTextStyles.h4.copyWith(
                      color: AppColors.royalGold,
                      letterSpacing: 2,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),

              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    children: [
                      // Main Balance Card
                      _MainBalanceCard(balance: wallet?.balance ?? 0.0)
                          .animate().fadeIn().slideY(begin: 0.1),
                      
                      const SizedBox(height: 24),

                      // Stats Header
                      Row(
                        children: [
                          Icon(Icons.analytics_rounded, color: AppColors.royalGold, size: 20),
                          const SizedBox(width: 8),
                          Text('ACCOUNT ACTIVITY', style: AppTextStyles.labelLarge),
                        ],
                      ).animate(delay: 200.ms).fadeIn().slideY(begin: 0.1),

                      const SizedBox(height: 32),

                      // Section Header
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Recent Transactions', style: AppTextStyles.labelLarge),
                          TextButton(
                            onPressed: () {},
                            child: Text('See All', style: TextStyle(color: AppColors.royalGold)),
                          ),
                        ],
                      ),

                      const SizedBox(height: 12),

                      // Live Transactions or Empty State
                      walletState.isLoading && transactions.isEmpty
                          ? ListView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: 3,
                              itemBuilder: (_, __) => Padding(
                                padding: const EdgeInsets.only(bottom: 12),
                                child: ShimmerLoader.orderCard(),
                              ),
                            )
                          : transactions.isEmpty
                              ? _EmptyState()
                              : _TransactionList(transactions: transactions),
                      
                      const SizedBox(height: 40),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        ),
      ),
    );
  }
}

class _MainBalanceCard extends ConsumerWidget {
  final double balance;

  const _MainBalanceCard({required this.balance});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return GoldCard(
      isVibrant: true,
      gradient: const LinearGradient(
        colors: [Color(0xFF00C853), Color(0xFF00E5FF)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      padding: const EdgeInsets.all(28),
      hasGlow: true,
      child: Column(
        children: [
          Text(
            'AVAILABLE FUNDS',
            style: AppTextStyles.labelSmall.copyWith(color: Colors.black.withValues(alpha: 0.5), fontWeight: FontWeight.bold, letterSpacing: 1),
          ),
          const SizedBox(height: 12),
          Text(
            Formatters.currency(balance),
            style: AppTextStyles.h1.copyWith(
              color: AppColors.deepBlack,
              fontSize: 42,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 28),
          GoldButton(
            text: 'Request Payout',
            icon: Icons.account_balance_rounded,
            onPressed: () => _showWithdrawDialog(context, ref, balance, ref.read(settingsProvider).minWithdrawal),
          ),
          const SizedBox(height: 12),
          GoldButton(
            text: 'Add Funds',
            isOutlined: true,
            icon: Icons.add_circle_outline_rounded,
            onPressed: () {},
          ),
        ],
      ),
    );
  }

  void _showWithdrawDialog(BuildContext context, WidgetRef ref, double balance, double minAmount) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.cardDark,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: AppColors.royalGold.withValues(alpha: 0.3)),
        ),
        title: Text('Withdrawal Request', style: AppTextStyles.h4),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Available: ${Formatters.currency(balance)}',
              style: AppTextStyles.caption.copyWith(color: AppColors.royalGold),
            ),
            const SizedBox(height: 4),
            Text(
              'Minimum: ${Formatters.currency(minAmount)}',
              style: AppTextStyles.caption.copyWith(color: AppColors.grey),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              keyboardType: TextInputType.number,
              style: AppTextStyles.h4.copyWith(color: AppColors.pureWhite),
              decoration: InputDecoration(
                hintText: 'Enter amount',
                hintStyle: AppTextStyles.bodyMedium.copyWith(color: AppColors.grey.withOpacity(0.5)),
                prefixText: '₹ ',
                prefixStyle: AppTextStyles.h4.copyWith(color: AppColors.royalGold, fontWeight: FontWeight.bold),
                enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: AppColors.royalGold.withOpacity(0.1))),
                focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: AppColors.royalGold)),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('CANCEL', style: TextStyle(color: AppColors.grey)),
          ),
          ElevatedButton(
            onPressed: () async {
              final amount = double.tryParse(controller.text.trim()) ?? 0;
              if (amount < minAmount) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Minimum withdrawal amount is ${Formatters.currency(minAmount)}')),
                );
                return;
              }
              if (amount > balance) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Insufficient balance')),
                );
                return;
              }
              
              final success = await ref.read(walletProvider.notifier).requestWithdrawal(amount);
              if (context.mounted) {
                Navigator.pop(context);
                if (success) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Withdrawal request submitted!')),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.royalGold),
            child: const Text('SUBMIT', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final double value;
  final IconData icon;
  final Color color;

  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return GoldCard(
      isVibrant: true,
      gradient: LinearGradient(
        colors: [color.withValues(alpha: 0.2), color.withValues(alpha: 0.05)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: color.withValues(alpha: 0.1), shape: BoxShape.circle),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(height: 16),
          Text(label, style: AppTextStyles.caption.copyWith(color: AppColors.pureWhite.withValues(alpha: 0.5), fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text(
            Formatters.currency(value),
            style: AppTextStyles.h4.copyWith(color: AppColors.pureWhite, fontSize: 18, fontWeight: FontWeight.w900),
          ),
        ],
      ),
    );
  }
}

class _TransactionList extends StatelessWidget {
  final List<dynamic> transactions;
  const _TransactionList({required this.transactions});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: transactions.map((txn) {
        final isCredit = ['referral', 'refund', 'resell', 'deposit', 'profit'].contains(txn['type']?.toString().toLowerCase());
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: _TransactionTile(
            title: txn['description'] ?? 'Transaction',
            date: Formatters.relativeTime(txn['createdAt'] ?? txn['date']),
            amount: _toDouble(txn['amount']),
            isCredit: isCredit,
            txnId: txn['id'],
            mode: txn['type'] ?? 'ONLINE',
            metadata: txn['metadata'] as Map<String, dynamic>?,
            status: txn['status'] ?? 'COMPLETED',
            invoiceNo: txn['invoiceNo'],
          ),
        );
      }).toList(),
    );
  }

  double _toDouble(dynamic val) {
    if (val is num) return val.toDouble();
    if (val is String) return double.tryParse(val) ?? 0.0;
    return 0.0;
  }
}

class _EmptyState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 40),
        child: Column(
          children: [
            Icon(Icons.history_rounded, size: 48, color: AppColors.grey.withValues(alpha: 0.3)),
            const SizedBox(height: 12),
            Text('No recent transactions', style: AppTextStyles.caption),
          ],
        ),
      ),
    );
  }
}

class _TransactionTile extends StatelessWidget {
  final String title;
  final String date;
  final double amount;
  final bool isCredit;
  final String? txnId;
  final String? mode;
  final String status;
  final String? invoiceNo;
  final Map<String, dynamic>? metadata;

  const _TransactionTile({
    required this.title,
    required this.date,
    required this.amount,
    required this.isCredit,
    this.txnId,
    this.mode,
    this.status = 'COMPLETED',
    this.invoiceNo,
    this.metadata,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _showTxnDetails(context),
      child: Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardDark.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.pureWhite.withValues(alpha: 0.05)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: (isCredit ? AppColors.success : AppColors.error).withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(
              isCredit ? Icons.add_rounded : Icons.remove_rounded,
              color: isCredit ? AppColors.success : AppColors.error,
              size: 22,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: AppTextStyles.labelLarge.copyWith(fontWeight: FontWeight.bold, fontSize: 13)),
                const SizedBox(height: 2),
                if (txnId != null) 
                   Text('ID: ${txnId!.substring(0, 8).toUpperCase()}', style: AppTextStyles.caption.copyWith(fontSize: 10, color: AppColors.royalGold.withValues(alpha: 0.6))),
                Text(date, style: AppTextStyles.caption.copyWith(color: AppColors.grey, fontSize: 10)),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${isCredit ? "+" : "-"} ${Formatters.currency(amount)}',
                style: AppTextStyles.labelLarge.copyWith(
                  color: isCredit ? AppColors.success : AppColors.error,
                  fontWeight: FontWeight.w900,
                  fontSize: 14,
                ),
              ),
              if (mode != null)
                Text(mode!.toUpperCase(), style: AppTextStyles.caption.copyWith(fontSize: 9, letterSpacing: 1)),
            ],
          ),
        ],
      ),
    ),
    );
  }

  void _showTxnDetails(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.cardDark,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(color: AppColors.grey.withValues(alpha: 0.3), borderRadius: BorderRadius.circular(2)),
                ),
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Transaction Details', style: AppTextStyles.h4),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: (status == 'COMPLETED' ? AppColors.success : AppColors.warning).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(status.toUpperCase(), style: AppTextStyles.caption.copyWith(color: status == 'COMPLETED' ? AppColors.success : AppColors.warning, fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              _DetailRow(label: 'Date & Time', value: date),
              if (txnId != null) _DetailRow(label: 'Transaction ID', value: txnId!),
              if (invoiceNo != null) _DetailRow(label: 'Invoice No', value: invoiceNo!),
              if (metadata?['paymentMode'] != null) _DetailRow(label: 'Payment Mode', value: metadata!['paymentMode']),
              
              if (metadata?['quantity'] != null) const SizedBox(height: 12),
              if (metadata?['quantity'] != null) _DetailRow(label: 'Quantity', value: metadata!['quantity'].toString()),
              if (metadata?['weight'] != null) _DetailRow(label: 'Weight (g)', value: '${metadata!['weight']}'),
              if (metadata?['gst'] != null) _DetailRow(label: 'GST Applied', value: Formatters.currency(_toDouble(metadata!['gst']))),
              
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                   Text('Total Amount', style: AppTextStyles.labelLarge.copyWith(color: AppColors.grey)),
                   Text(Formatters.currency(amount), style: AppTextStyles.h3.copyWith(color: AppColors.royalGold)),
                ],
              ),
              const SizedBox(height: 32),
            ],
          ),
        );
      },
    );
  }

  double _toDouble(dynamic val) {
    if (val is num) return val.toDouble();
    if (val is String) return double.tryParse(val) ?? 0.0;
    return 0.0;
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;
  const _DetailRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(flex: 2, child: Text(label, style: AppTextStyles.caption.copyWith(color: AppColors.grey))),
          Expanded(flex: 3, child: Text(value, style: AppTextStyles.labelLarge, textAlign: TextAlign.right)),
        ],
      ),
    );
  }
}
