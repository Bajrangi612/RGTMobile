import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/formatters.dart';
import '../../../widgets/gold_card.dart';
import '../../../widgets/gold_button.dart';
import '../providers/admin_provider.dart';

class AdminWithdrawalManagerScreen extends ConsumerStatefulWidget {
  const AdminWithdrawalManagerScreen({super.key});

  @override
  ConsumerState<AdminWithdrawalManagerScreen> createState() => _AdminWithdrawalManagerScreenState();
}

class _AdminWithdrawalManagerScreenState extends ConsumerState<AdminWithdrawalManagerScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() => ref.read(adminProvider.notifier).fetchWithdrawals());
  }

  @override
  Widget build(BuildContext context) {
    final adminState = ref.watch(adminProvider);
    final requests = adminState.withdrawalRequests;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('WITHDRAWAL MANAGEMENT', style: AppTextStyles.labelLarge.copyWith(letterSpacing: 2)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        iconTheme: IconThemeData(color: AppColors.royalGold),
      ),
      body: Container(
        decoration: BoxDecoration(color: AppColors.background),
        child: adminState.isLoading && requests.isEmpty
            ? Center(child: CircularProgressIndicator(color: AppColors.royalGold))
            : requests.isEmpty
                ? _EmptyWithdrawals()
                : RefreshIndicator(
                    onRefresh: () => ref.read(adminProvider.notifier).fetchWithdrawals(),
                    color: AppColors.royalGold,
                    child: ListView.builder(
                      padding: const EdgeInsets.all(24),
                      itemCount: requests.length,
                      itemBuilder: (context, index) {
                        final req = requests[index];
                        return _WithdrawalCard(request: req);
                      },
                    ),
                  ),
      ),
    );
  }
}

class _WithdrawalCard extends ConsumerWidget {
  final dynamic request;
  const _WithdrawalCard({required this.request});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final status = request['status'] as String;
    final isPending = status == 'PENDING';
    final user = request['user'] ?? {};
    final bank = request['bankDetails'] ?? {};

    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: GoldCard(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(user['name'] ?? 'Unknown User', style: AppTextStyles.labelLarge.copyWith(fontWeight: FontWeight.bold)),
                    Text(user['phone'] ?? 'N/A', style: AppTextStyles.caption),
                  ],
                ),
                _StatusPill(status: status),
              ],
            ),
            const Divider(height: 32, color: Colors.white10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Requested Amount', style: AppTextStyles.caption),
                Text(
                  Formatters.currency(double.tryParse(request['amount'].toString()) ?? 0.0),
                  style: AppTextStyles.h4.copyWith(color: AppColors.royalGold),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            // Bank Details Subsection
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.03),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white10),
              ),
              child: Column(
                children: [
                  _BankRow('Bank', bank['bankName'] ?? bank['bankName'] ?? 'N/A'),
                  _BankRow('A/C No', bank['accNo'] ?? bank['bankAccountNo'] ?? 'N/A'),
                  _BankRow('IFSC', bank['ifsc'] ?? bank['bankIfsc'] ?? 'N/A'),
                ],
              ),
            ),

            if (isPending) ...[
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => _handleStatusUpdate(context, ref, 'REJECTED'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.error,
                        side: const BorderSide(color: AppColors.error),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text('REJECT'),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: GoldButton(
                      text: 'APPROVE & TRANSFER',
                      height: 48,
                      onPressed: () => _handleStatusUpdate(context, ref, 'COMPLETED'),
                    ),
                  ),
                ],
              ),
            ],
            if (request['adminNotes'] != null) ...[
              const SizedBox(height: 12),
              Text('Notes: ${request['adminNotes']}', style: AppTextStyles.caption.copyWith(fontStyle: FontStyle.italic)),
            ]
          ],
        ),
      ).animate().fadeIn().slideX(begin: 0.1),
    );
  }

  Future<void> _handleStatusUpdate(BuildContext context, WidgetRef ref, String status) async {
    final notesController = TextEditingController();
    
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.deepBlack,
        title: Text('${status == 'COMPLETED' ? 'Approve' : 'Reject'} Withdrawal', style: AppTextStyles.labelLarge),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Action: Set payment status to $status', style: AppTextStyles.caption),
            const SizedBox(height: 16),
            TextField(
              controller: notesController,
              style: AppTextStyles.bodyMedium,
              decoration: InputDecoration(
                hintText: 'Add administrative notes...',
                hintStyle: AppTextStyles.caption,
                filled: true,
                fillColor: Colors.white.withValues(alpha: 0.05),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(status == 'COMPLETED' ? 'PROCEED' : 'CONFIRM REJECT', style: TextStyle(color: status == 'COMPLETED' ? AppColors.success : AppColors.error)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      final success = await ref.read(adminProvider.notifier).updateWithdrawalStatus(
        request['id'],
        status,
        notes: notesController.text,
      );
      if (success && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Withdrawal $status successfully')));
      }
    }
  }
}

class _BankRow extends StatelessWidget {
  final String label;
  final String value;
  const _BankRow(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 10, color: Colors.grey)),
          Text(value, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white70)),
        ],
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  final String status;
  const _StatusPill({required this.status});

  @override
  Widget build(BuildContext context) {
    Color color = AppColors.royalGold;
    if (status == 'COMPLETED') color = AppColors.success;
    if (status == 'REJECTED') color = AppColors.error;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(
        status,
        style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold),
      ),
    );
  }
}

class _EmptyWithdrawals extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.account_balance_wallet_outlined, size: 64, color: AppColors.royalGold.withValues(alpha: 0.2)),
          const SizedBox(height: 16),
          Text('No withdrawal requests found', style: AppTextStyles.labelLarge.copyWith(color: Colors.white54)),
        ],
      ),
    );
  }
}
