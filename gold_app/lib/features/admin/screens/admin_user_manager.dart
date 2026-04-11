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

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          title: Text('USER MANAGEMENT', style: AppTextStyles.labelLarge.copyWith(letterSpacing: 2)),
          backgroundColor: Colors.transparent,
          elevation: 0,
          centerTitle: true,
          iconTheme: IconThemeData(color: AppColors.royalGold),
          bottom: TabBar(
            indicatorColor: AppColors.royalGold,
            labelColor: AppColors.royalGold,
            unselectedLabelColor: AppColors.grey,
            labelStyle: AppTextStyles.labelSmall.copyWith(fontWeight: FontWeight.bold),
            tabs: const [
              Tab(text: 'ALL USERS'),
              Tab(text: 'PENDING BANK'),
            ],
          ),
        ),
        body: Container(
          decoration: BoxDecoration(color: AppColors.background),
          child: TabBarView(
            children: [
              _UserList(users: adminState.users),
              _UserList(users: adminState.users.where((u) => u['bankStatus'] == 'PENDING').toList()),
            ],
          ),
        ),
      ),
    );
  }
}

class _UserList extends StatelessWidget {
  final List<dynamic> users;
  const _UserList({required this.users});

  @override
  Widget build(BuildContext context) {
    if (users.isEmpty) {
      return Center(child: Text('No users found', style: AppTextStyles.labelMedium.copyWith(color: AppColors.grey)));
    }
    
    return ListView.builder(
      padding: const EdgeInsets.all(24),
      itemCount: users.length,
      itemBuilder: (context, index) {
        final user = users[index];
        return _UserCard(user: user, index: index);
      },
    );
  }
}

class _UserCard extends StatelessWidget {
  final dynamic user;
  final int index;
  const _UserCard({required this.user, required this.index});

  @override
  Widget build(BuildContext context) {
    final wallet = user['wallet'] ?? {};
    final balance = double.tryParse(wallet['balance']?.toString() ?? '0') ?? 0.0;
    final goldBalance = double.tryParse(wallet['goldBalance']?.toString() ?? '0') ?? 0.0;

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: GoldCard(
        child: ListTile(
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => AdminUserDetailScreen(user: user)),
          ),
          contentPadding: const EdgeInsets.all(16),
          leading: CircleAvatar(
            backgroundColor: AppColors.royalGold.withValues(alpha: 0.1),
            child: Icon(Icons.person_outline, color: AppColors.royalGold, size: 24),
          ),
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      user['name']?.toUpperCase() ?? 'N/A',
                      style: AppTextStyles.labelLarge.copyWith(fontWeight: FontWeight.bold),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  _StatusBadge(status: user['status'] ?? 'active'),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                user['phone'] ?? 'No Phone',
                style: AppTextStyles.caption.copyWith(color: AppColors.royalGold),
              ),
            ],
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(Icons.account_balance_wallet_outlined, size: 12, color: AppColors.grey),
                  const SizedBox(width: 4),
                  Text(
                    'Balance: ₹${balance.toStringAsFixed(2)} | ${goldBalance.toStringAsFixed(3)}g',
                    style: AppTextStyles.caption.copyWith(color: Colors.white70),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Text('BANK: ', style: AppTextStyles.caption.copyWith(fontWeight: FontWeight.bold, fontSize: 9)),
                  _BankBadge(status: user['bankStatus'] ?? 'PENDING'),
                ],
              ),
            ],
          ),
          trailing: Icon(Icons.chevron_right, color: AppColors.royalGold.withValues(alpha: 0.3)),
        ),
      ),
    ).animate().fadeIn(delay: (index * 50).ms).slideX(begin: 0.1);
  }
}


class _BankBadge extends StatelessWidget {
  final String status;
  const _BankBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    Color color;
    switch (status.toUpperCase()) {
      case 'VERIFIED':
        color = AppColors.success;
        break;
      case 'PENDING':
        color = AppColors.royalGold;
        break;
      case 'REJECTED':
        color = AppColors.error;
        break;
      default:
        color = AppColors.grey;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withValues(alpha: 0.3), width: 0.5),
      ),
      child: Text(
        status.toUpperCase(),
        style: AppTextStyles.caption.copyWith(
          color: color,
          fontSize: 8,
          fontWeight: FontWeight.bold,
          letterSpacing: 0.5,
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
    final isActive = status.toLowerCase() == 'active' || status.toLowerCase() == 'customer';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: (isActive ? AppColors.success : AppColors.error).withValues(alpha: 0.1),
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

// KYC Badge code removed.
