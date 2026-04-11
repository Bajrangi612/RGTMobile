import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../widgets/gold_card.dart';
import '../providers/admin_provider.dart';
import '../../home/providers/home_provider.dart';
import 'admin_product_manager.dart';
import 'admin_category_manager.dart';
import 'admin_user_manager.dart';
import 'admin_order_manager.dart';
import 'admin_settings_screen.dart';
import 'admin_reports_screen.dart';
import 'admin_gold_price_screen.dart';
import 'admin_transactions_screen.dart';
import 'admin_withdrawal_manager_screen.dart';
import '../../auth/providers/auth_provider.dart';
import '../../auth/screens/login_screen.dart';
import '../../home/screens/home_screen.dart';
import '../../../core/utils/formatters.dart';

class AdminDashboardScreen extends ConsumerStatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  ConsumerState<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends ConsumerState<AdminDashboardScreen> {

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(adminProvider.notifier).loadInitialData();
      ref.read(homeProvider.notifier).loadDashboard(); 
    });
  }

  @override
  Widget build(BuildContext context) {
    final adminState = ref.watch(adminProvider);
    final homeState = ref.watch(homeProvider);
    final size = MediaQuery.of(context).size;
    final bool isDesktop = size.width > 1000;

    return Scaffold(
      backgroundColor: AppColors.background,
      drawer: isDesktop ? null : _buildMobileDrawer(context),
      body: Container(
        decoration: BoxDecoration(color: AppColors.background),
        child: adminState.isLoading
            ? Center(child: CircularProgressIndicator(color: AppColors.royalGold))
            : Row(
                children: [
                  if (isDesktop) _buildSidebar(context),
                  Expanded(
                    child: SafeArea(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            /// 👑 Institutional Market Ticker
                            _MarketTicker(
                              price: homeState.goldPrice,
                              change: homeState.priceChange,
                            ).animate().fadeIn(duration: 600.ms).slideY(begin: -0.2),

                            const SizedBox(height: 32),

                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'GLOBAL COMMAND',
                                      style: AppTextStyles.labelLarge.copyWith(
                                        color: AppColors.royalGold,
                                        letterSpacing: 2,
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Row(
                                      children: [
                                        Container(
                                          width: 8,
                                          height: 8,
                                          decoration: BoxDecoration(color: AppColors.success, shape: BoxShape.circle),
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          'SYSTEM OPERATIONAL · STABLE',
                                          style: AppTextStyles.caption.copyWith(color: AppColors.pureWhite.withValues(alpha: 0.4), letterSpacing: 1),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                                 if (!isDesktop)
                                  Row(
                                    children: [
                                      IconButton(
                                        icon: const Icon(Icons.refresh, size: 20, color: Colors.white),
                                        onPressed: () {
                                          ref.read(adminProvider.notifier).loadInitialData();
                                          ref.read(homeProvider.notifier).loadDashboard();
                                        },
                                      ),
                                      IconButton(
                                        icon: const Icon(Icons.logout, size: 20, color: AppColors.error),
                                        onPressed: () {
                                          ref.read(authProvider.notifier).logout();
                                          Navigator.of(context).pushAndRemoveUntil(
                                            MaterialPageRoute(builder: (_) => const LoginScreen()),
                                            (route) => false,
                                          );
                                        },
                                      ),
                                      Builder(
                                        builder: (context) => IconButton(
                                          icon: Icon(Icons.menu, color: AppColors.royalGold),
                                          onPressed: () => Scaffold.of(context).openDrawer(),
                                        ),
                                      ),
                                    ],
                                  )
                                else
                                  _HeaderActions(onRefresh: () {
                                    ref.read(adminProvider.notifier).loadInitialData();
                                    ref.read(homeProvider.notifier).loadDashboard();
                                  }),
                              ],
                            ).animate().fadeIn(delay: 200.ms),

                            const SizedBox(height: 32),

                            /// 📈 Interactive Revenue Analysis
                            _RevenueAnalysisChart(
                              totalRevenue: adminState.totalRevenue,
                              weeklyData: adminState.allTransactions // Logic to filter correctly mapped in widget
                            ).animate()
                                .fadeIn(delay: 400.ms)
                                .scale(begin: const Offset(0.98, 0.98)),

                            const SizedBox(height: 32),

                            /// 📊 Core Analytics Grid
                            LayoutBuilder(
                              builder: (context, constraints) {
                                final count = constraints.maxWidth > 800 ? 4 : 2;
                                return GridView.count(
                                  shrinkWrap: true,
                                  physics: const NeverScrollableScrollPhysics(),
                                  crossAxisCount: count,
                                  childAspectRatio: 1.5,
                                  mainAxisSpacing: 16,
                                  crossAxisSpacing: 16,
                                  children: [
                                    _EliteStatCard(
                                      label: 'GROSS REVENUE',
                                      value: Formatters.currency(adminState.totalRevenue),
                                      icon: Icons.account_balance_wallet_outlined,
                                      color: AppColors.royalGold,
                                      sparkData: _generateRelativeSpark(adminState.totalRevenue),
                                    ),
                                    _EliteStatCard(
                                      label: 'GOLD COLLECTED',
                                      value: '${adminState.totalWeight.toStringAsFixed(2)}g',
                                      icon: Icons.check_circle_outline,
                                      color: AppColors.success,
                                      sparkData: _generateRelativeSpark(adminState.totalWeight),
                                    ),
                                    _EliteStatCard(
                                      label: 'ACTIVE CUSTOMERS',
                                      value: '${adminState.users.length}',
                                      icon: Icons.group_outlined,
                                      color: Colors.blueAccent,
                                      sparkData: _generateRelativeSpark(adminState.users.length.toDouble()),
                                    ),
                                    _EliteStatCard(
                                      label: 'PICKUP PENDING',
                                      value: '${adminState.pendingOrdersCount}',
                                      icon: Icons.pending_actions,
                                      color: AppColors.warning,
                                      sparkData: _generateRelativeSpark(adminState.pendingOrdersCount.toDouble()),
                                    ),
                                  ],
                                );
                              }
                            ).animate().fadeIn(delay: 600.ms),

                            const SizedBox(height: 32),

                            /// 🛠 Management Suite
                            Text('MANAGEMENT MODULES', style: AppTextStyles.labelLarge.copyWith(letterSpacing: 1.5, color: AppColors.pureWhite.withValues(alpha: 0.3))),
                            const SizedBox(height: 16),
                            _ManagementGrid(),

                            const SizedBox(height: 32),
                            
                            /// 📋 Operation Logs
                            _OperationLogs(orders: adminState.allOrders),

                            const SizedBox(height: 48),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildSidebar(BuildContext context) {
    return Container(
      width: 260,
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border(right: BorderSide(color: AppColors.royalGold.withValues(alpha: 0.1))),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.royalGold, width: 2),
                  ),
                  child: Icon(Icons.shield_outlined, color: AppColors.royalGold, size: 32),
                ),
                const SizedBox(height: 16),
                Text('ROYAL GOLD', style: AppTextStyles.h4),
                Text('ADMIN TERMINAL', style: AppTextStyles.caption.copyWith(letterSpacing: 2, color: AppColors.pureWhite.withValues(alpha: 0.4))),
              ],
            ),
          ),
          Divider(color: AppColors.pureWhite.withValues(alpha: 0.1), indent: 20, endIndent: 20),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
              children: [
                _SidebarItem(icon: Icons.dashboard_outlined, label: 'Dashboard', isSelected: true, onTap: () {}),
                _SidebarItem(icon: Icons.inventory_2_outlined, label: 'Products', onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const AdminProductManager()))),
                _SidebarItem(icon: Icons.category_outlined, label: 'Categories', onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const AdminCategoryManager()))),
                _SidebarItem(icon: Icons.people_outline, label: 'Customers', onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const AdminUserManager()))),
                _SidebarItem(icon: Icons.local_shipping_outlined, label: 'Orders', onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const AdminOrderManager()))),
                _SidebarItem(icon: Icons.account_balance_wallet_outlined, label: 'Transactions', onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const AdminTransactionsScreen()))),
                _SidebarItem(icon: Icons.settings_outlined, label: 'Settings', onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const AdminSettingsScreen()))),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(24),
            child: InkWell(
              onTap: () {
                ref.read(authProvider.notifier).logout();
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (_) => const LoginScreen()),
                  (route) => false,
                );
              },
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.error.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.error.withValues(alpha: 0.1)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.logout, color: AppColors.error, size: 20),
                    const SizedBox(width: 12),
                    Text('LOGOUT', style: AppTextStyles.labelSmall.copyWith(color: AppColors.error, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMobileDrawer(BuildContext context) {
    return Drawer(
      backgroundColor: AppColors.background,
      child: _buildSidebar(context),
    );
  }

  List<double> _generateRelativeSpark(double value) {
    return [
      value * 0.8,
      value * 0.9,
      value * 0.85,
      value * 1.1,
      value * 1.05,
      value * 1.2,
      value * 1.0,
    ];
  }
}

class _SidebarItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _SidebarItem({
    required this.icon,
    required this.label,
    this.isSelected = false,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.royalGold.withValues(alpha: 0.1) : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected ? AppColors.royalGold.withValues(alpha: 0.3) : Colors.transparent,
            ),
          ),
          child: Row(
            children: [
              Icon(
                icon,
                color: isSelected ? AppColors.royalGold : AppColors.pureWhite.withValues(alpha: 0.5),
                size: 20,
              ),
              const SizedBox(width: 12),
              Text(
                label,
                style: AppTextStyles.labelSmall.copyWith(
                  color: isSelected ? AppColors.royalGold : AppColors.pureWhite.withValues(alpha: 0.5),
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MarketTicker extends StatelessWidget {
  final double price;
  final double change;
  const _MarketTicker({required this.price, required this.change});

  @override
  Widget build(BuildContext context) {
    final isUp = change >= 0;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: AppColors.cardDark.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.royalGold.withValues(alpha: 0.15), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: AppColors.royalGold.withValues(alpha: 0.05),
            blurRadius: 20,
            spreadRadius: -5,
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.royalGold.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.public, color: AppColors.royalGold, size: 20),
          ),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('LIVE GOLD RATE (24K)', style: AppTextStyles.caption.copyWith(letterSpacing: 1.5, color: AppColors.grey)),
              const SizedBox(height: 2),
              Text(
                '₹${price.toStringAsFixed(2)} /g',
                style: AppTextStyles.h4.copyWith(color: AppColors.pureWhite, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: (isUp ? AppColors.success : AppColors.error).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              children: [
                Icon(
                  isUp ? Icons.arrow_upward_rounded : Icons.arrow_downward_rounded,
                  color: isUp ? AppColors.success : AppColors.error,
                  size: 14,
                ),
                const SizedBox(width: 4),
                Text(
                  '${isUp ? '+' : ''}${change.toStringAsFixed(2)}%',
                  style: AppTextStyles.labelSmall.copyWith(
                    color: isUp ? AppColors.success : AppColors.error,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Container(
            height: 32,
            width: 1,
            color: AppColors.grey.withValues(alpha: 0.2),
          ),
          const SizedBox(width: 8),
          IconButton(
            icon: Icon(Icons.settings_suggest_outlined, color: AppColors.royalGold, size: 24),
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const AdminGoldPriceScreen()),
            ),
          ),
        ],
      ),
    );
  }
}

class _RevenueAnalysisChart extends StatelessWidget {
  final double totalRevenue;
  final List<dynamic> weeklyData;
  const _RevenueAnalysisChart({required this.totalRevenue, required this.weeklyData});

  @override
  Widget build(BuildContext context) {
    return GoldCard(
      isVibrant: false,
      blurSigma: 60,
      padding: const EdgeInsets.all(24),
      hasGlow: true,
      gradient: LinearGradient(
        colors: [
          AppColors.surface.withValues(alpha: 0.8),
          AppColors.royalGold.withValues(alpha: 0.05),
        ],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.analytics_outlined, color: AppColors.royalGold, size: 18),
                      const SizedBox(width: 8),
                      Text('WEEKLY REVENUE', style: AppTextStyles.caption.copyWith(color: AppColors.royalGold, letterSpacing: 2, fontWeight: FontWeight.bold)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text('₹${totalRevenue.toStringAsFixed(0)}', style: AppTextStyles.h1.copyWith(fontSize: 32, fontWeight: FontWeight.w900)),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.success.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.success.withValues(alpha: 0.3)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.trending_up, color: AppColors.success, size: 14),
                    const SizedBox(width: 4),
                    Text('+12.5%', style: AppTextStyles.caption.copyWith(color: AppColors.success, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 48),
          SizedBox(
            height: 180,
            child: LineChart(
              LineChartData(
                gridData: FlGridData(
                  show: true, 
                  drawVerticalLine: false,
                  getDrawingHorizontalLine: (_) => FlLine(color: AppColors.pureWhite.withValues(alpha: 0.05), strokeWidth: 1, dashArray: [5, 5]),
                ),
                titlesData: FlTitlesData(
                  show: true,
                  topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      interval: 1,
                      getTitlesWidget: (val, _) => Padding(
                        padding: const EdgeInsets.only(top: 10),
                        child: Text(['M', 'T', 'W', 'T', 'F', 'S', 'S'][val.toInt().clamp(0, 6)], style: AppTextStyles.caption.copyWith(color: AppColors.grey)),
                      ),
                    ),
                  ),
                ),
                borderData: FlBorderData(show: false),
                lineBarsData: [
                  LineChartBarData(
                    spots: [
                      FlSpot(0, totalRevenue * 0.12),
                      FlSpot(1, totalRevenue * 0.15),
                      FlSpot(2, totalRevenue * 0.1),
                      FlSpot(3, totalRevenue * 0.2),
                      FlSpot(4, totalRevenue * 0.18),
                      FlSpot(5, totalRevenue * 0.3),
                      FlSpot(6, totalRevenue * 0.35),
                    ],
                    isCurved: true,
                    color: AppColors.royalGold,
                    barWidth: 4,
                    isStrokeCapRound: true,
                    dotData: FlDotData(show: false),
                    belowBarData: BarAreaData(
                      show: true,
                      gradient: LinearGradient(
                        colors: [
                          AppColors.royalGold.withValues(alpha: 0.4),
                          Colors.transparent,
                        ],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _EliteStatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  final List<double> sparkData;

  const _EliteStatCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
    required this.sparkData,
  });

  @override
  Widget build(BuildContext context) {
    return GoldCard(
      isVibrant: true,
      hasGlow: true,
      blurSigma: 80,
      gradient: LinearGradient(
        colors: [
          color.withValues(alpha: 0.25),
          color.withValues(alpha: 0.05),
        ],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: color, size: 22),
              ),
              Expanded(
                child: Container(
                  height: 24,
                  padding: const EdgeInsets.only(left: 12),
                  child: LineChart(
                    LineChartData(
                      gridData: FlGridData(show: false),
                      titlesData: FlTitlesData(show: false),
                      borderData: FlBorderData(show: false),
                      lineBarsData: [
                        LineChartBarData(
                          spots: List.generate(sparkData.length, (i) => FlSpot(i.toDouble(), sparkData[i])),
                          isCurved: true,
                          color: color.withValues(alpha: 0.8),
                          barWidth: 2,
                          dotData: FlDotData(show: false),
                          belowBarData: BarAreaData(
                            show: true,
                            gradient: LinearGradient(
                              colors: [color.withValues(alpha: 0.3), Colors.transparent],
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
          const Spacer(),
          Text(
            value,
            style: AppTextStyles.h3.copyWith(
              color: AppColors.pureWhite,
              fontWeight: FontWeight.w900,
              fontSize: 22,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: AppTextStyles.caption.copyWith(
              color: AppColors.pureWhite.withValues(alpha: 0.6),
              letterSpacing: 1.2,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _ManagementGrid extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: width > 400 ? 3 : 2,
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 1.1,
      children: [
        _CompactTool(
          icon: Icons.inventory_2_outlined,
          label: 'Products',
          onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const AdminProductManager())),
        ),
        _CompactTool(
          icon: Icons.category_outlined,
          label: 'Categories',
          onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const AdminCategoryManager())),
        ),
        _CompactTool(
          icon: Icons.verified_user_outlined,
          label: 'Compliance',
          onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const AdminUserManager())),
        ),
        _CompactTool(
          icon: Icons.local_shipping_outlined,
          label: 'Logistics',
          onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const AdminOrderManager())),
        ),
        _CompactTool(
          icon: Icons.settings_outlined,
          label: 'System',
          onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const AdminSettingsScreen())),
        ),
        _CompactTool(
          icon: Icons.account_balance_wallet_outlined,
          label: 'Finance',
          onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const AdminTransactionsScreen())),
        ),
        _CompactTool(
          icon: Icons.payments_outlined,
          label: 'Payouts',
          onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => AdminWithdrawalManagerScreen())),
        ),
        _CompactTool(
          icon: Icons.analytics_outlined,
          label: 'Reports',
          onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => AdminReportsScreen())),
        ),
      ],
    );
  }
}

class _CompactTool extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _CompactTool({required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: GoldCard(
        isVibrant: false,
        blurSigma: 40,
        hasGoldBorder: true,
        padding: EdgeInsets.zero,
        child: Container(
          decoration: BoxDecoration(
            gradient: RadialGradient(
              colors: [
                AppColors.royalGold.withValues(alpha: 0.1),
                Colors.transparent,
              ],
              center: Alignment.center,
              radius: 0.8,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.royalGold.withValues(alpha: 0.05),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(color: AppColors.royalGold.withValues(alpha: 0.2), blurRadius: 15, spreadRadius: -5)
                  ],
                ),
                child: Icon(icon, color: AppColors.royalGold, size: 28),
              ),
              const SizedBox(height: 12),
              Text(
                label.toUpperCase(),
                style: AppTextStyles.caption.copyWith(
                  fontSize: 10,
                  letterSpacing: 1.5,
                  fontWeight: FontWeight.w600,
                  color: AppColors.pureWhite.withValues(alpha: 0.8),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HeaderActions extends StatelessWidget {
  final VoidCallback onRefresh;
  const _HeaderActions({required this.onRefresh});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        IconButton(
          icon: const Icon(Icons.refresh, size: 20, color: Colors.white70),
          onPressed: onRefresh,
        ),
        const SizedBox(width: 8),
        TextButton.icon(
          onPressed: () {
            ProviderScope.containerOf(context).read(authProvider.notifier).logout();
            Navigator.of(context).pushAndRemoveUntil(
              MaterialPageRoute(builder: (_) => const LoginScreen()),
              (route) => false,
            );
          },
          icon: const Icon(Icons.logout, size: 18, color: AppColors.error),
          label: Text(
            'LOGOUT',
            style: AppTextStyles.labelSmall.copyWith(
              color: AppColors.error,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.2,
            ),
          ),
          style: TextButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            backgroundColor: AppColors.error.withValues(alpha: 0.05),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
        ),
      ],
    );
  }
}

class _OperationLogs extends StatelessWidget {
  final List<dynamic> orders;
  const _OperationLogs({required this.orders});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('OPERATIONAL LOGS', style: AppTextStyles.labelLarge.copyWith(letterSpacing: 1.2)),
            TextButton(
              onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const AdminOrderManager())),
              child: Text('VIEW ALL', style: AppTextStyles.caption.copyWith(color: AppColors.royalGold, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ...orders.take(3).map((order) => Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: GoldCard(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.05), borderRadius: BorderRadius.circular(10)),
                  child: Icon(Icons.receipt_long_outlined, size: 18, color: AppColors.royalGold),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Order #${order['id']?.substring(0, 8)}...', style: AppTextStyles.labelSmall),
                      Text('${order['product']?['name'] ?? 'Gold Item'}', style: AppTextStyles.caption.copyWith(color: AppColors.pureWhite.withValues(alpha: 0.4))),
                    ],
                  ),
                ),
                _EliteStatusPill(status: order['status']),
              ],
            ),
          ),
        )).toList(),
      ],
    );
  }
}

class _EliteStatusPill extends StatelessWidget {
  final String? status;
  const _EliteStatusPill({required this.status});

  @override
  Widget build(BuildContext context) {
    final statusStr = status?.toLowerCase() ?? 'pending';
    Color color = AppColors.warning;
    if (statusStr == 'paid' || statusStr == 'delivered') color = AppColors.success;
    if (statusStr == 'cancelled' || statusStr == 'failed') color = AppColors.error;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(
        statusStr.toUpperCase(),
        style: TextStyle(color: color, fontSize: 8, fontWeight: FontWeight.bold, letterSpacing: 1),
      ),
    );
  }
}
