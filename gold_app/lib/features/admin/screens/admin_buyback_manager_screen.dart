import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/formatters.dart';
import '../../../widgets/gold_card.dart';
import '../../../widgets/gold_button.dart';
import '../providers/admin_provider.dart';

class AdminBuybackManagerScreen extends ConsumerStatefulWidget {
  const AdminBuybackManagerScreen({super.key});

  @override
  ConsumerState<AdminBuybackManagerScreen> createState() => _AdminBuybackManagerScreenState();
}

class _AdminBuybackManagerScreenState extends ConsumerState<AdminBuybackManagerScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() => ref.read(adminProvider.notifier).fetchBuybacks());
  }

  @override
  Widget build(BuildContext context) {
    final adminState = ref.watch(adminProvider);
    final requests = adminState.buybackRequests;

    return DefaultTabController(
      length: 4,
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          title: Text('BUYBACK MANAGEMENT', style: AppTextStyles.labelLarge.copyWith(letterSpacing: 2)),
          backgroundColor: Colors.transparent,
          elevation: 0,
          centerTitle: true,
          iconTheme: IconThemeData(color: AppColors.royalGold),
          bottom: TabBar(
            isScrollable: true,
            indicatorColor: AppColors.royalGold,
            labelColor: AppColors.royalGold,
            unselectedLabelColor: AppColors.grey,
            tabs: const [
              Tab(text: 'APPLIED'),
              Tab(text: 'APPROVED'),
              Tab(text: 'SETTLED'),
              Tab(text: 'REJECTED'),
            ],
          ),
        ),
        body: Container(
          decoration: BoxDecoration(color: AppColors.background),
          child: adminState.isLoading && requests.isEmpty
              ? Center(child: CircularProgressIndicator(color: AppColors.royalGold))
              : TabBarView(
                  children: [
                    _BuybackList(requests: requests.where((r) => r['status'] == 'SELL_BACK_APPLIED').toList()),
                    _BuybackList(requests: requests.where((r) => r['status'] == 'APPROVED').toList()),
                    _BuybackList(requests: requests.where((r) => r['status'] == 'PAYMENT_SETTLED').toList()),
                    _BuybackList(requests: requests.where((r) => r['status'] == 'REJECTED').toList()),
                  ],
                ),
        ),
      ),
    );
  }
}

class _BuybackList extends ConsumerWidget {
  final List<dynamic> requests;
  const _BuybackList({required this.requests});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (requests.isEmpty) return _EmptyBuybacks();
    
    return RefreshIndicator(
      onRefresh: () => ref.read(adminProvider.notifier).fetchBuybacks(),
      color: AppColors.royalGold,
      child: ListView.builder(
        padding: const EdgeInsets.all(24),
        itemCount: requests.length,
        itemBuilder: (context, index) {
          final req = requests[index];
          return _BuybackCard(request: req);
        },
      ),
    );
  }
}


class _BuybackCard extends StatefulWidget {
  final dynamic request;
  const _BuybackCard({required this.request});

  @override
  State<_BuybackCard> createState() => _BuybackCardState();
}

class _BuybackCardState extends State<_BuybackCard> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    final status = widget.request['status'] as String;
    final isApplied = status == 'SELL_BACK_APPLIED';
    final isApproved = status == 'APPROVED';
    final user = widget.request['user'] ?? {};
    final order = widget.request['order'] ?? {};
    final product = order['product'] ?? {};

    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: GoldCard(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            GestureDetector(
              onTap: () => setState(() => _isExpanded = !_isExpanded),
              behavior: HitTestBehavior.opaque,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(user['name'] ?? 'Unknown User', style: AppTextStyles.labelLarge.copyWith(fontWeight: FontWeight.bold)),
                      Row(
                        children: [
                          Text('Order #${order['id']?.toString().substring(0, 8) ?? 'N/A'}', style: AppTextStyles.caption),
                          const SizedBox(width: 8),
                          Icon(_isExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down, size: 16, color: AppColors.royalGold),
                        ],
                      ),
                    ],
                  ),
                  _StatusPill(status: status),
                ],
              ),
            ),
            const Divider(height: 32, color: Colors.white10),
            
            _InfoRow('Item', product['name'] ?? 'Gold Coin'),
            _InfoRow('Weight', '${order['weight']}g'),
            _InfoRow('Buy Price applied', Formatters.currencyPrecise(double.tryParse(widget.request['buyPrice'].toString()) ?? 0.0)),
            
            /// --- EXPANDABLE SECTION ---
            if (_isExpanded) ...[
              const Divider(height: 32, color: Colors.white10),
              Text('CUSTOMER & BANK DETAILS', style: AppTextStyles.caption.copyWith(color: AppColors.royalGold, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
              const SizedBox(height: 16),
              _InfoRow('Customer Phone', user['phone'] ?? 'N/A'),
              _InfoRow('Bank Name', user['bankName'] ?? 'N/A'),
              _InfoRow('A/C Holder', user['bankHolderName'] ?? 'N/A'),
              _InfoRow('Account No', user['bankAccountNo'] ?? 'N/A'),
              _InfoRow('IFSC Code', user['bankIfsc'] ?? 'N/A'),
              
              const SizedBox(height: 16),
              Text('TIMELINE', style: AppTextStyles.caption.copyWith(color: AppColors.royalGold, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
              const SizedBox(height: 12),
              _InfoRow('Order Made On', order['createdAt'] != null ? Formatters.dateTime(order['createdAt']) : 'N/A'),
              _InfoRow('Request Raised On', widget.request['createdAt'] != null ? Formatters.dateTime(widget.request['createdAt']) : 'N/A'),
            ],

            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Payable Amount', style: AppTextStyles.labelMedium.copyWith(color: AppColors.grey, fontWeight: FontWeight.bold)),
                Text(
                  Formatters.currency(double.tryParse(widget.request['amount'].toString()) ?? 0.0),
                  style: AppTextStyles.h4.copyWith(color: AppColors.royalGold, fontWeight: FontWeight.w900),
                ),
              ],
            ),

            if (isApplied || isApproved) ...[
              const SizedBox(height: 24),
              Consumer(
                builder: (context, ref, _) => Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => _handleStatusUpdate(context, ref, 'REJECT'),
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
                        text: isApplied ? 'APPROVE' : 'MARK SETTLED',
                        height: 48,
                        onPressed: () => _handleStatusUpdate(context, ref, 'APPROVE'),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            if (widget.request['adminNotes'] != null) ...[
              const SizedBox(height: 12),
              Text('Notes: ${widget.request['adminNotes']}', style: AppTextStyles.caption.copyWith(fontStyle: FontStyle.italic)),
            ]
          ],
        ),
      ).animate().fadeIn().slideX(begin: 0.1),
    );
  }

  Future<void> _handleStatusUpdate(BuildContext context, WidgetRef ref, String action) async {
    final notesController = TextEditingController();
    
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.deepBlack,
        title: Text('${action == 'APPROVE' ? 'Approve' : 'Reject'} Buyback', style: AppTextStyles.labelLarge),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Action: $action buyback request for this order.', style: AppTextStyles.caption),
            const SizedBox(height: 16),
            TextField(
              controller: notesController,
              autofocus: true,
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
            child: Text(action == 'APPROVE' ? 'PROCEED' : 'CONFIRM REJECT', style: TextStyle(color: action == 'APPROVE' ? AppColors.success : AppColors.error)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      final success = await ref.read(adminProvider.notifier).updateBuybackStatus(
        widget.request['id'],
        action,
        notes: notesController.text,
      );
      if (success && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Buyback $action successfully')));
      }
    }
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
          Text(label, style: AppTextStyles.caption),
          Text(value, style: AppTextStyles.bodySmall.copyWith(fontWeight: FontWeight.bold)),
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
    if (status == 'PAYMENT_SETTLED' || status == 'COMPLETED') color = AppColors.success;
    if (status == 'REJECTED') color = AppColors.error;
    if (status == 'APPROVED') color = Colors.blueAccent;

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

class _EmptyBuybacks extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.sell_outlined, size: 64, color: AppColors.royalGold.withValues(alpha: 0.2)),
          const SizedBox(height: 16),
          Text('No buyback requests found', style: AppTextStyles.labelLarge.copyWith(color: Colors.white54)),
        ],
      ),
    );
  }
}
