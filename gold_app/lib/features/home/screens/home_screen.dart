import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../product/data/models/product_model.dart';
import '../../../core/utils/formatters.dart';
import '../../../widgets/gold_card.dart';
import '../../../widgets/gold_button.dart';
import '../../../widgets/gold_image.dart';
import '../../../widgets/shimmer_loader.dart';
import '../../../widgets/bottom_nav_bar.dart';
import '../providers/home_provider.dart';
import '../../order/providers/order_provider.dart';
import '../../wallet/providers/wallet_provider.dart';
import '../../auth/providers/auth_provider.dart';
import '../../product/screens/product_detail_screen.dart';
import '../../product/screens/catalog_screen.dart';
import '../../product/presentation/providers/product_providers.dart';
import '../../order/screens/orders_screen.dart';
import '../../referral/screens/referral_screen.dart';
import '../../profile/screens/profile_screen.dart';
import '../../kyc/screens/aadhaar_kyc_screen.dart';
import '../../notifications/screens/transactions_screen.dart';
import '../../notifications/screens/notification_screen.dart';
import '../../notifications/presentation/providers/notification_provider.dart';
import '../../order/screens/sell_back_screen.dart';
import '../../wallet/screens/wallet_screen.dart';
import '../../admin/screens/admin_gold_price_screen.dart';
import '../../admin/screens/admin_withdrawal_manager_screen.dart';
import '../../admin/screens/admin_buyback_manager_screen.dart';
import '../../../core/providers/navigation_provider.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  late final List<Widget> _screens;

  @override
  void initState() {
    super.initState();
    _screens = [
      _HomeDashboard(onTabChange: (index) {
        ref.read(navigationProvider.notifier).state = index;
        _handleRefresh(index);
      }),
      const OrdersScreen(),
      const ReferralScreen(),
      const ProfileScreen(),
      const CatalogScreen(),
    ];
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(homeProvider.notifier).loadDashboard();
    });
  }

  void _handleRefresh(int index) {
    switch (index) {
      case 0:
        ref.read(homeProvider.notifier).loadDashboard();
        break;
      case 1:
        ref.read(orderProvider.notifier).loadOrders();
        break;
      case 2:
        ref.read(walletProvider.notifier).loadWalletDetails();
        ref.read(walletProvider.notifier).loadWithdrawalHistory();
        ref.read(authProvider.notifier).getCurrentUser();
        break;
      case 3:
        ref.read(authProvider.notifier).getCurrentUser();
        break;
      case 4:
        ref.invalidate(categoriesProvider);
        ref.invalidate(productsProvider);
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentIndex = ref.watch(navigationProvider);
    
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: currentIndex == 0 ? AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: Builder(
          builder: (context) => IconButton(
            icon: Icon(Icons.menu_rounded, color: AppColors.royalGold),
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: CircleAvatar(
              backgroundColor: AppColors.royalGold.withValues(alpha: 0.1),
              child: Icon(Icons.person_outline_rounded, color: AppColors.royalGold),
            ),
          ),
        ],
      ) : null,
      drawer: Drawer(
        backgroundColor: AppColors.deepBlack,
        child: Column(
          children: [
            DrawerHeader(
              decoration: BoxDecoration(
                gradient: AppColors.darkGradient,
                border: Border(bottom: BorderSide(color: AppColors.royalGold.withValues(alpha: 0.1))),
              ),
              child: Center(
                child: Image.asset(
                  'assets/images/logo.png',
                  width: 120,
                  fit: BoxFit.contain,
                ),
              ),
            ),
            ListTile(
              leading: Icon(Icons.dashboard_rounded, color: AppColors.royalGold),
              title: Text('Dashboard', style: AppTextStyles.bodyMedium),
              onTap: () {
                ref.read(navigationProvider.notifier).state = 0;
                _handleRefresh(0);
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: Icon(Icons.shopping_bag_rounded, color: AppColors.royalGold),
              title: Text('Catalog', style: AppTextStyles.bodyMedium),
              onTap: () {
                ref.read(navigationProvider.notifier).state = 4;
                _handleRefresh(4);
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: Icon(Icons.history_rounded, color: AppColors.royalGold),
              title: Text('Orders', style: AppTextStyles.bodyMedium),
              onTap: () {
                ref.read(navigationProvider.notifier).state = 1;
                _handleRefresh(1);
                Navigator.pop(context);
              },
            ),
            if (ref.watch(authProvider).user?.isAdmin ?? false) ...[
              const Divider(color: Colors.white10),
              Padding(
                padding: const EdgeInsets.only(left: 16, top: 8, bottom: 4),
                child: Text('ADMINISTRATIVE CONTROL', style: AppTextStyles.caption.copyWith(color: AppColors.royalGold, letterSpacing: 1.5, fontWeight: FontWeight.bold)),
              ),
              ListTile(
                leading: Icon(Icons.account_balance_wallet_rounded, color: AppColors.royalGold),
                title: Text('Withdrawal Requests', style: AppTextStyles.bodyMedium),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const AdminWithdrawalManagerScreen()));
                },
              ),
              ListTile(
                leading: Icon(Icons.sell_rounded, color: AppColors.royalGold),
                title: Text('Buyback Management', style: AppTextStyles.bodyMedium),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const AdminBuybackManagerScreen()));
                },
              ),
              ListTile(
                leading: Icon(Icons.show_chart_rounded, color: AppColors.royalGold),
                title: Text('Gold Price Control', style: AppTextStyles.bodyMedium),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const AdminGoldPriceScreen()));
                },
              ),
            ],
            const Divider(color: Colors.white10),
            ListTile(
              leading: Icon(Icons.logout_rounded, color: Colors.redAccent),
              title: Text('Logout', style: AppTextStyles.bodyMedium.copyWith(color: Colors.redAccent)),
              onTap: () async {
                await ref.read(authProvider.notifier).logout();
                if (mounted) Navigator.pushReplacementNamed(context, '/login');
              },
            ),
          ],
        ),
      ),
      body: IndexedStack(
        index: currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: BottomNavBar(
        currentIndex: currentIndex,
        onTap: (index) {
          ref.read(navigationProvider.notifier).state = index;
          _handleRefresh(index);
        },
      ),
    ) ;
  }
}

class _HomeDashboard extends ConsumerWidget {
  final Function(int) onTabChange;
  const _HomeDashboard({required this.onTabChange});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final homeState = ref.watch(homeProvider);
    final authState = ref.watch(authProvider);

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.background, AppColors.surface],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {
            await ref.read(homeProvider.notifier).loadDashboard();
            await ref.read(authProvider.notifier).getCurrentUser();
          },
          color: AppColors.royalGold,
          backgroundColor: AppColors.surface,
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
            slivers: [
              // Header Content
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Welcome Text (Premium Clean)
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Welcome,',
                            style: AppTextStyles.labelMedium.copyWith(
                              color: AppColors.grey,
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                          Text(
                            authState.user?.name ?? 'Alexander',
                            style: AppTextStyles.h2.copyWith(
                              color: AppColors.pureWhite,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                      ),
                      // Notification Icon (Minimal with Badge)
                      GestureDetector(
                        onTap: () => Navigator.of(context).push(
                          MaterialPageRoute(builder: (_) => const NotificationScreen()),
                        ),
                        child: Stack(
                          clipBehavior: Clip.none,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: AppColors.surface,
                                shape: BoxShape.circle,
                                border: Border.all(color: AppColors.royalGold.withOpacity(0.1)),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.1),
                                    blurRadius: 10,
                                  ),
                                ],
                              ),
                              child: Icon(Icons.notifications_none_rounded,
                                  color: AppColors.royalGold, size: 24),
                            ),
                            Consumer(
                              builder: (context, ref, child) {
                                final count = ref.watch(unreadNotificationsCountProvider);
                                if (count == 0) return const SizedBox.shrink();
                                return Positioned(
                                  top: -2,
                                  right: -2,
                                  child: Container(
                                    padding: const EdgeInsets.all(4),
                                    decoration: const BoxDecoration(
                                      color: Colors.red,
                                      shape: BoxShape.circle,
                                    ),
                                    constraints: const BoxConstraints(
                                      minWidth: 16,
                                      minHeight: 16,
                                    ),
                                    child: Text(
                                      count > 9 ? '9+' : count.toString(),
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 8,
                                        fontWeight: FontWeight.bold,
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                  ),
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                    ],
                  ).animate().fadeIn(duration: 400.ms).slideY(begin: -0.1),
                ),
              ),
  
              const SliverToBoxAdapter(child: SizedBox(height: 24)),
  
              const SliverToBoxAdapter(child: SizedBox(height: 24)),
  
              const SliverToBoxAdapter(child: SizedBox(height: 28)),
  
              // Action Buttons (Modern Pills)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Row(
                    children: [
                      Expanded(
                        child: GoldButton(
                          text: 'Buy Gold',
                          icon: Icons.add_rounded,
                          onPressed: () => Navigator.of(context).push(
                            MaterialPageRoute(builder: (_) => CatalogScreen()),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: GoldButton(
                          text: 'Buyback Program',
                          isOutlined: true,
                          onPressed: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Select an item to sell back')),
                            );
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => const OrdersScreen(onlyEligible: true)),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),
  
              const SliverToBoxAdapter(child: SizedBox(height: 32)),
  
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: _GoldPriceCard(
                    price: homeState.goldPrice,
                    change: homeState.priceChange,
                    history: homeState.priceHistory,
                    isLoading: homeState.isLoading,
                    isAdmin: authState.user?.isAdmin ?? false,
                    onRefresh: () => ref.read(homeProvider.notifier).refreshPrice(),
                  ),
                ),
              ),
  
              const SliverToBoxAdapter(child: SizedBox(height: 32)),
  
              // 🏆 The Elite Collection (Premium Filtered Assets)
              const SliverToBoxAdapter(child: _EliteCollection()),
  
              const SliverToBoxAdapter(child: SizedBox(height: 32)),
  
              // Offers Carousel (Latest Banners)
              SliverToBoxAdapter(
                child: _BannerCarousel(),
              ),
  
              const SliverToBoxAdapter(child: SizedBox(height: 32)),
  
              // Categories Section (Premium Gold, Round, Hindu God)
              SliverToBoxAdapter(
                child: _CategoryList(),
              ),
  
              const SliverToBoxAdapter(child: SizedBox(height: 32)),
  
              // Utility Actions Grid
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _SmallQuickAction(
                        icon: Icons.receipt_long_rounded,
                        label: 'Orders',
                        color: AppColors.info,
                        onTap: () => onTabChange(1),
                      ),
                      _SmallQuickAction(
                        icon: Icons.shopping_bag_rounded,
                        label: 'Shop',
                        color: AppColors.success,
                        onTap: () => onTabChange(4),
                      ),
                      _SmallQuickAction(
                        icon: Icons.people_rounded,
                        label: 'Refer & Earn',
                        color: AppColors.warning,
                        onTap: () => onTabChange(2),
                      ),
                      _SmallQuickAction(
                        icon: Icons.person_rounded,
                        label: 'Profile',
                        color: AppColors.amber,
                        onTap: () => onTabChange(3),
                      ),
                    ],
                  ).animate(delay: 400.ms).fadeIn(duration: 400.ms),
                ),
              ),
  
              const SliverToBoxAdapter(child: SizedBox(height: 32)),
  
              // Promotional Content
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: _PromoBanner(),
                ),
              ),
  
              const SliverToBoxAdapter(child: SizedBox(height: 32)),
  
              // Featured Coins section
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Row(
                    children: [
                      Container(
                        width: 4,
                        height: 20,
                        decoration: BoxDecoration(
                          gradient: AppColors.goldGradient,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text('Premium Gold Coins', style: AppTextStyles.h3.copyWith(color: AppColors.pureWhite)),
                      const Spacer(),
                      GestureDetector(
                        onTap: () => Navigator.of(context).push(
                          MaterialPageRoute(builder: (_) => CatalogScreen()),
                        ),
                        child: Text(
                          'View All',
                          style: AppTextStyles.caption.copyWith(
                            color: AppColors.royalGold,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ).animate(delay: 500.ms).fadeIn(duration: 400.ms),
                ),
              ),
  
              const SliverToBoxAdapter(child: SizedBox(height: 20)),
  
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                sliver: homeState.isLoading
                    ? SliverGrid(
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          childAspectRatio: MediaQuery.of(context).size.width > 400 ? 0.75 : 0.68,
                          mainAxisSpacing: 16,
                          crossAxisSpacing: 16,
                        ),
                        delegate: SliverChildBuilderDelegate(
                          (_, __) => ShimmerLoader.productCard(),
                          childCount: 4,
                        ),
                      )
                    : SliverGrid(
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          childAspectRatio: MediaQuery.of(context).size.width > 400 ? 0.75 : 0.68,
                          mainAxisSpacing: 16,
                          crossAxisSpacing: 16,
                        ),
                        delegate: SliverChildBuilderDelegate(
                          (context, index) {
                            final products = homeState.products.where((p) => !p.isPremium).toList();
                            final product = products[index];
                            return _ProductCard(
                              product: product,
                              onTap: () => Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) =>
                                      ProductDetailScreen(product: product),
                                ),
                              ),
                            ).animate(delay: (600 + index * 100).ms).fadeIn(duration: 400.ms).scale(begin: const Offset(0.95, 0.95));
                          },
                          childCount: homeState.products.where((p) => !p.isPremium).length > 4 ? 4 : homeState.products.where((p) => !p.isPremium).length,
                        ),
                      ),
              ),
  
            const SliverToBoxAdapter(child: SizedBox(height: 40)),
          ],
        ),
      ),
    ),
  );
}
}

// Portfolio/Balance Card Widget
class _PortfolioCard extends StatelessWidget {
  final double holdings;
  final double value;
  final bool isLoading;

  const _PortfolioCard({
    required this.holdings,
    required this.value,
    required this.isLoading,
  });

  @override
  Widget build(BuildContext context) {
    return GoldCard(
      isVibrant: false,
      blurSigma: 60,
      gradient: LinearGradient(
        colors: [
          AppColors.royalGold.withValues(alpha: 0.15),
          AppColors.surface.withValues(alpha: 0.8),
        ],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      hasGoldBorder: true,
      hasGlow: true,
      padding: const EdgeInsets.all(28),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'ACCOUNT BALANCE',
                style: AppTextStyles.labelMedium.copyWith(color: AppColors.royalGold, letterSpacing: 2, fontWeight: FontWeight.bold),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.royalGold.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.royalGold.withValues(alpha: 0.3)),
                ),
                child: Row(
                  children: [
                     Icon(Icons.shield_rounded, color: AppColors.royalGold, size: 12),
                     const SizedBox(width: 4),
                     Text(
                      'ACCOUNT BALANCE',
                      style: AppTextStyles.caption.copyWith(
                        color: AppColors.royalGold,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Text(
            isLoading ? '₹ --,---' : Formatters.currency(value),
            style: AppTextStyles.goldPrice.copyWith(
              fontSize: 42,
              color: AppColors.pureWhite,
              fontWeight: FontWeight.w900,
              letterSpacing: -0.5,
              shadows: [
                Shadow(color: AppColors.royalGold.withValues(alpha: 0.2), blurRadius: 20, offset: const Offset(0, 5))
              ],
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.success.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.success.withValues(alpha: 0.2)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.verified_rounded, color: AppColors.success, size: 14),
                const SizedBox(width: 6),
                Text(
                  '100% 24K Gold • Insured & Audited',
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.success,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          const SizedBox(height: 32),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '**** **** **** 9012',
                style: AppTextStyles.caption.copyWith(color: Colors.white38),
              ),
              const Icon(Icons.credit_card_rounded, color: Colors.white24, size: 20), 
            ],
          ),
        ],
      ),
    );
  }
}



// Asset Allocation Card (Modern Donul)
class _AssetAllocationCard extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authProvider).user;
    final total = user?.totalCollectionValue ?? 0.0;
    
    return GoldCard(
      blurSigma: 20,
      padding: const EdgeInsets.all(20),
      hasGoldBorder: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.pie_chart_outline_rounded, color: AppColors.royalGold, size: 16),
              const SizedBox(width: 8),
              Text('Asset Allocation', style: AppTextStyles.labelMedium.copyWith(color: AppColors.grey, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 20),
          Center(
            child: Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  width: 100,
                  height: 100,
                  child: CircularProgressIndicator(
                    value: total > 0 ? 0.7 : 0.0,
                    strokeWidth: 10,
                    color: AppColors.royalGold,
                    backgroundColor: AppColors.royalGold.withValues(alpha: 0.1),
                    strokeCap: StrokeCap.round,
                  ),
                ),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('70%', style: AppTextStyles.labelLarge.copyWith(fontWeight: FontWeight.bold, color: AppColors.royalGold)),
                    Text('Gold', style: AppTextStyles.caption.copyWith(fontSize: 8, color: AppColors.grey)),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          _AllocationLabel(
            label: 'Physical Holdings', 
            value: total > 0 ? '70%' : '0%', 
            color: AppColors.royalGold
          ),
          const SizedBox(height: 8),
          _AllocationLabel(
            label: 'Vault Reserves', 
            value: total > 0 ? '30%' : '0%', 
            color: AppColors.royalGold.withValues(alpha: 0.3)
          ),
        ],
      ),
    );
  }
}

class _AllocationLabel extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _AllocationLabel({required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(width: 8, height: 8, decoration: BoxDecoration(shape: BoxShape.circle, color: color)),
        const SizedBox(width: 6),
        Text(label, style: AppTextStyles.caption.copyWith(fontSize: 9)),
        const Spacer(),
        Text(value, style: AppTextStyles.caption.copyWith(fontSize: 9, fontWeight: FontWeight.bold, color: AppColors.pureWhite)),
      ],
    );
  }
}

// Gold Price Card (Refined side-by-side)
class _GoldPriceCard extends StatelessWidget {
  final double price;
  final double change;
  final List<double> history;
  final bool isLoading;
  final bool isAdmin;
  final VoidCallback onRefresh;

  const _GoldPriceCard({
    required this.price,
    required this.change,
    required this.history,
    required this.isLoading,
    this.isAdmin = false,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    final isUp = change >= 0;
    return GoldCard(
      isVibrant: false,
      blurSigma: 30,
      gradient: LinearGradient(
        colors: [
          AppColors.surface,
          (isUp ? AppColors.success : AppColors.error).withValues(alpha: 0.05),
        ],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      padding: const EdgeInsets.all(24),
      hasGoldBorder: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(Icons.query_stats_rounded, color: AppColors.royalGold, size: 16),
                  const SizedBox(width: 8),
                  Text('Market Statistics', style: AppTextStyles.labelMedium.copyWith(color: AppColors.grey, fontWeight: FontWeight.bold)),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: (isUp ? AppColors.success : AppColors.error).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    Icon(isUp ? Icons.arrow_upward_rounded : Icons.arrow_downward_rounded, color: isUp ? AppColors.success : AppColors.error, size: 12),
                    const SizedBox(width: 4),
                    Text(
                      '${isUp ? '+' : ''}${change.toStringAsFixed(1)}%',
                      style: AppTextStyles.caption.copyWith(color: isUp ? AppColors.success : AppColors.error, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Text(
            Formatters.currency(price),
            style: AppTextStyles.h2.copyWith(fontWeight: FontWeight.w900, color: AppColors.pureWhite, fontSize: 32),
          ),
          Text(
            'Live Per Gram Rate (24K)',
            style: AppTextStyles.caption.copyWith(color: AppColors.grey, letterSpacing: 1),
          ),
          const SizedBox(height: 28),
          // Sparkline Placeholder
          SizedBox(
            height: 50,
            width: double.infinity,
            child: CustomPaint(
              painter: _SparklinePainter(
                data: history,
                color: (isUp ? AppColors.success : AppColors.error).withValues(alpha: 0.3),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SparklinePainter extends CustomPainter {
  final List<double> data;
  final Color color;
  _SparklinePainter({required this.data, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    if (data.isEmpty) return;

    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;

    final path = Path();
    
    final double max = data.reduce((a, b) => a > b ? a : b);
    final double min = data.reduce((a, b) => a < b ? a : b);
    final double range = max - min == 0 ? 1 : max - min;
    
    final double stepX = size.width / (data.length - 1);
    
    for (int i = 0; i < data.length; i++) {
      final double x = i * stepX;
      final double y = size.height - ((data[i] - min) / range * size.height * 0.8 + size.height * 0.1);
      
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// Small Clean Quick Action
class _SmallQuickAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _SmallQuickAction({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: color.withValues(alpha: 0.12)),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(height: 10),
          Text(label, style: AppTextStyles.caption.copyWith(fontSize: 10)),
        ],
      ),
    );
  }
}

// Product Card
class _ProductCard extends StatelessWidget {
  final dynamic product;
  final VoidCallback onTap;

  const _ProductCard({required this.product, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Ink(
          decoration: BoxDecoration(
            color: AppColors.cardDark,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.royalGold.withValues(alpha: 0.05)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.15),
                blurRadius: 18,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Image area
              Expanded(
                flex: 5,
                child: Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        AppColors.surface,
                        AppColors.cardDarkAlt.withValues(alpha: 0.3),
                      ],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                  ),
                  child: Stack(
                    children: [
                      Center(
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: GoldImage(
                                  imageUrl: product.image,
                                  width: double.infinity,
                                  height: double.infinity,
                                  fit: BoxFit.contain,
                                )
                        ),
                      ),
                      Positioned(
                        top: 8,
                        right: 8,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: AppColors.royalGold.withValues(alpha: 0.3)),
                          ),
                          child: Text(
                            '${product.weight.toInt()}g',
                            style: AppTextStyles.caption.copyWith(
                              color: AppColors.royalGold,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              // Info area
              Expanded(
                flex: 3,
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        product.name,
                        style: AppTextStyles.labelMedium.copyWith(color: AppColors.pureWhite, fontWeight: FontWeight.bold),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        '${product.purity} · ${product.fineness}',
                        style: AppTextStyles.caption.copyWith(fontSize: 10, color: AppColors.grey),
                      ),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            Formatters.currency(product.price),
                            style: AppTextStyles.priceTag.copyWith(fontSize: 16),
                          ),
                          if (product.oldPrice != null) ...[
                            const SizedBox(width: 4),
                            Text(
                              Formatters.currency(product.oldPrice!),
                              style: AppTextStyles.caption.copyWith(
                                decoration: TextDecoration.lineThrough,
                                fontSize: 10,
                                color: AppColors.grey,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Promo Banner Component
class _PromoBanner extends StatelessWidget {
  const _PromoBanner();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            Color(0xFF8B0000), // Velvet Red
            Color(0xFF5A0000), // Richer Crimson
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF8B0000).withValues(alpha: 0.2),
            blurRadius: 20,
            spreadRadius: -4,
            offset: const Offset(0, 8),
          ),
        ],
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    'FESTIVE OFFER',
                    style: AppTextStyles.labelSmall.copyWith(color: Colors.white),
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  '0% Making\nCharges',
                  style: AppTextStyles.h2.copyWith(height: 1.1),
                ),
              ],
            ),
          ),
          SizedBox(width: 16),
          // Graphic motif
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withValues(alpha: 0.1),
              border: Border.all(color: AppColors.royalGold.withValues(alpha: 0.5)),
            ),
            child: Icon(
              Icons.discount_rounded,
              color: AppColors.royalGold,
              size: 32,
            ),
          ).animate(onPlay: (c) => c.repeat(reverse: true))
           .slideY(begin: -0.1, end: 0.1, duration: 2000.ms, curve: Curves.easeInOut),
        ],
      ),
    ).animate(delay: 350.ms).fadeIn(duration: 400.ms).slideX(begin: 0.05);
  }
}

// --- NEW PREMIUM DASHBOARD WIDGETS ---

class _BannerCarousel extends StatefulWidget {
  @override
  State<_BannerCarousel> createState() => _BannerCarouselState();
}

class _BannerCarouselState extends State<_BannerCarousel> {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  Timer? _timer;

  final List<String> _banners = [
    'assets/images/banner_1.png',
    'assets/images/banner_2.png',
    'assets/images/banner_3.png',
    'assets/images/banner_4.png',
  ];

  @override
  void initState() {
    super.initState();
    _resetTimer();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  void _resetTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 3), (timer) {
      if (_pageController.hasClients) {
        final nextPage = (_currentPage + 1) % _banners.length;
        _pageController.animateToPage(
          nextPage,
          duration: const Duration(milliseconds: 800),
          curve: Curves.easeInOutCubic,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          height: 180,
          child: PageView.builder(
            controller: _pageController,
            onPageChanged: (index) {
              setState(() => _currentPage = index);
              _resetTimer();
            },
            itemCount: _banners.length,
            itemBuilder: (context, index) {
              return Container(
                margin: const EdgeInsets.symmetric(horizontal: 24),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.08),
                      blurRadius: 15,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: GoldImage(
                    imageUrl: _banners[index],
                    fit: BoxFit.cover,
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(_banners.length, (index) {
            return AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              margin: const EdgeInsets.symmetric(horizontal: 4),
              height: 6,
              width: _currentPage == index ? 24 : 6,
              decoration: BoxDecoration(
                color: _currentPage == index ? AppColors.royalGold : AppColors.grey.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(3),
              ),
            );
          }),
        ),
      ],
    );
  }
}

class _CategoryList extends ConsumerWidget {
  const _CategoryList();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final categoriesAsync = ref.watch(categoriesProvider);

    return categoriesAsync.when(
      data: (categories) {
        if (categories.isEmpty) return const SizedBox.shrink();
        
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 4,
                    height: 18,
                    decoration: BoxDecoration(
                      gradient: AppColors.goldGradient,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Exclusive Categories',
                    style: AppTextStyles.h3.copyWith(
                      fontSize: 18,
                      color: AppColors.pureWhite,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              ...categories.map((cat) => Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: _CategoryItem(
                  label: cat.name,
                  icon: Icons.workspace_premium,
                  description: 'Certified 24K ${cat.name}',
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => CatalogScreen(initialCategoryId: cat.id)),
                  ),
                ),

              )).toList(),
            ],
          ),
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }
}

class _CategoryItem extends StatelessWidget {
  final String label;
  final String? imagePath;
  final IconData? icon;
  final String description;
  final VoidCallback onTap;

  const _CategoryItem({
    required this.label,
    this.imagePath,
    this.icon,
    required this.description,
    required this.onTap,
  });


  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: AppColors.royalGold.withValues(alpha: 0.12)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 70,
              height: 70,
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.royalGold.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(16),
              ),
              child: icon != null 
                ? Icon(icon, color: AppColors.royalGold, size: 32)
                : Image.asset(
                    imagePath!,
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) => Icon(
                      Icons.monetization_on_rounded,
                      color: AppColors.royalGold,
                      size: 32,
                    ),
                  ),
            ),

            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: AppTextStyles.h4.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppColors.pureWhite,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: AppTextStyles.caption.copyWith(
                      color: AppColors.grey,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios_rounded,
              color: AppColors.royalGold.withValues(alpha: 0.5),
              size: 16,
            ),
          ],
        ),
      ),
    );
  }
}
class _EliteCollection extends ConsumerWidget {
  const _EliteCollection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final products = ref.watch(homeProvider).products.where((p) => p.isPremium).toList();
    
    if (products.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                   Text('ELITE COLLECTION', style: AppTextStyles.labelSmall.copyWith(color: AppColors.royalGold, letterSpacing: 2, fontWeight: FontWeight.bold)),
                   const SizedBox(height: 4),
                   Text('Curated Masterpieces', style: AppTextStyles.h4),
                ],
              ),
              TextButton(
                onPressed: () {
                   Navigator.of(context).push(MaterialPageRoute(builder: (_) => const CatalogScreen()));
                },
                child: Text('View All', style: AppTextStyles.labelMedium.copyWith(color: AppColors.royalGold)),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        SizedBox(
          height: 260,
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            scrollDirection: Axis.horizontal,
            itemCount: products.length,
            itemBuilder: (context, index) {
              final product = products[index];
              return _EliteProductCard(product: product);
            },
          ),
        ),
      ],
    );
  }
}

class _EliteProductCard extends StatelessWidget {
  final ProductModel product;
  const _EliteProductCard({required this.product});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 220,
      margin: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.royalGold.withValues(alpha: 0.3), width: 1),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.royalGold.withValues(alpha: 0.1),
            AppColors.deepBlack,
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.royalGold.withValues(alpha: 0.1),
            blurRadius: 20,
            spreadRadius: -5,
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => ProductDetailScreen(product: product))),
          borderRadius: BorderRadius.circular(24),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Center(
                    child: Hero(
                      tag: 'elite_${product.id}',
                      child: Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.royalGold.withValues(alpha: 0.3),
                              blurRadius: 40,
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                        child: GoldImage(
                          imageUrl: product.imageUrl ?? '',
                          fit: BoxFit.contain,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Flexible(
                  child: Text(
                    product.name,
                    style: AppTextStyles.labelLarge.copyWith(fontWeight: FontWeight.bold),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Flexible(
                      child: Text(
                        '${product.weight}g · ${product.purity}',
                        style: AppTextStyles.caption.copyWith(color: AppColors.grey),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      Formatters.currency(product.price),
                      style: AppTextStyles.labelLarge.copyWith(color: AppColors.royalGold, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  decoration: BoxDecoration(
                    color: AppColors.royalGold.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.royalGold.withValues(alpha: 0.2)),
                  ),
                  child: Center(
                    child: Text('BUY ELITE', style: AppTextStyles.labelSmall.copyWith(color: AppColors.royalGold, fontWeight: FontWeight.bold)),
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
