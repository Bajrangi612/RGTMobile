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
import '../../../widgets/shimmer_loader.dart';
import '../../../widgets/bottom_nav_bar.dart';
import '../providers/home_provider.dart';
import '../../auth/providers/auth_provider.dart';
import '../../product/screens/product_detail_screen.dart';
import '../../product/screens/catalog_screen.dart';
import '../../order/screens/orders_screen.dart';
import '../../referral/screens/referral_screen.dart';
import '../../profile/screens/profile_screen.dart';
import '../../kyc/screens/aadhaar_kyc_screen.dart';
import '../../notifications/screens/transactions_screen.dart';
import '../../order/screens/sell_back_screen.dart';
import '../../wallet/screens/wallet_screen.dart';
import '../../admin/screens/admin_gold_price_screen.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  int _currentIndex = 0;
  late final List<Widget> _screens;

  @override
  void initState() {
    super.initState();
    _screens = [
      _HomeDashboard(onTabChange: (index) => setState(() => _currentIndex = index)),
      const OrdersScreen(),
      const ReferralScreen(),
      const ProfileScreen(),
      const CatalogScreen(),
    ];
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(homeProvider.notifier).loadDashboard();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: BottomNavBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
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
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
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
                    // Notification Icon (Minimal)
                    GestureDetector(
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => TransactionsScreen()),
                      ),
                      child: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          shape: BoxShape.circle,
                          border: Border.all(color: AppColors.royalGold.withValues(alpha: 0.1)),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.1),
                              blurRadius: 10,
                            ),
                          ],
                        ),
                        child: Icon(Icons.notifications_none_rounded,
                            color: AppColors.royalGold, size: 24),
                      ),
                    ),
                  ],
                ).animate().fadeIn(duration: 400.ms).slideY(begin: -0.1),
              ),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 24)),

            // Portfolio Balance Card (Big Dashboard Feature)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: _PortfolioCard(
                  holdings: (authState.user?.totalCollectionValue ?? 0.0) / (homeState.goldPrice > 0 ? homeState.goldPrice : 7000.0),
                  value: authState.user?.totalCollectionValue ?? 0.0,
                  isLoading: homeState.isLoading,
                ),
              ),
            ),

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
                            MaterialPageRoute(builder: (_) => const OrdersScreen()),
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
                      icon: Icons.verified_user_rounded,
                      label: 'KYC',
                      color: AppColors.warning,
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => AadhaarKycScreen()),
                      ),
                    ),
                    _SmallQuickAction(
                      icon: Icons.account_balance_wallet_rounded,
                      label: 'Wallet',
                      color: AppColors.amber,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => WalletScreen()),
                        );
                      },
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
      isVibrant: true,
      gradient: const LinearGradient(
        colors: [Color(0xFF1A1F3D), Color(0xFF2E376E), Color(0xFF151B40)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      hasGoldBorder: false,
      hasGlow: true,
      padding: const EdgeInsets.all(28),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Collection Value',
                style: AppTextStyles.labelMedium.copyWith(color: Colors.white70),
              ),
              Row(
                children: [
                   const Icon(Icons.shield_rounded, color: Color(0xFFFFD700), size: 14),
                   const SizedBox(width: 4),
                   Text(
                    'ROYAL STORE',
                    style: AppTextStyles.labelSmall.copyWith(
                      color: const Color(0xFFFFD700),
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 24),
          Text(
            isLoading ? '₹ --,---' : Formatters.currency(value),
            style: AppTextStyles.goldPrice.copyWith(
              fontSize: 34,
              color: AppColors.pureWhite,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFF00E5FF).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFF00E5FF).withValues(alpha: 0.2)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.verified_rounded, color: Color(0xFF00E5FF), size: 12),
                const SizedBox(width: 4),
                Text(
                  'Physically Secured & Insured',
                  style: AppTextStyles.caption.copyWith(
                    color: const Color(0xFF00E5FF),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
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
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Asset Allocation', style: AppTextStyles.labelMedium.copyWith(color: AppColors.grey)),
          const SizedBox(height: 16),
          Center(
            child: Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.royalGold.withValues(alpha: 0.1), width: 12),
              ),
              child: Container(
                 margin: const EdgeInsets.all(4),
                 decoration: BoxDecoration(
                   shape: BoxShape.circle,
                   gradient: SweepGradient(
                     colors: [
                       AppColors.royalGold,
                       AppColors.royalGold.withValues(alpha: 0.3),
                       AppColors.royalGold,
                     ],
                     stops: const [0.0, 0.7, 1.0],
                   ),
                 ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          _AllocationLabel(
            label: 'Physical Gold', 
            value: total > 0 ? '70%' : '0%', 
            color: AppColors.royalGold
          ),
          const SizedBox(height: 4),
          _AllocationLabel(
            label: 'Digital Gold', 
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
  final bool isLoading;
  final bool isAdmin;
  final VoidCallback onRefresh;

  const _GoldPriceCard({
    required this.price,
    required this.change,
    required this.isLoading,
    this.isAdmin = false,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    return GoldCard(
      isVibrant: true,
      gradient: const LinearGradient(
        colors: [Color(0xFFFFD700), Color(0xFFFF8C00)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Live Gold Rate', style: AppTextStyles.labelMedium.copyWith(color: AppColors.deepBlack.withValues(alpha: 0.6), fontWeight: FontWeight.bold)),
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(color: Colors.black.withValues(alpha: 0.1), shape: BoxShape.circle),
                child: Icon(Icons.trending_up_rounded, color: AppColors.deepBlack, size: 14),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                Formatters.currency(price),
                style: AppTextStyles.h3.copyWith(fontWeight: FontWeight.w900, color: AppColors.deepBlack),
              ),
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(color: Colors.black.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(4)),
                child: Text(
                  '${change >= 0 ? '+' : ''}${change.toStringAsFixed(1)}%',
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.deepBlack, 
                    fontSize: 10, 
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          // Sparkline Placeholder
          SizedBox(
            height: 40,
            width: double.infinity,
            child: CustomPaint(
              painter: _SparklinePainter(color: AppColors.deepBlack.withValues(alpha: 0.3)),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: ['1D', '1W', '1M'].map((t) => Text(t, style: AppTextStyles.caption.copyWith(fontSize: 10, color: AppColors.deepBlack.withValues(alpha: 0.5), fontWeight: FontWeight.bold))).toList(),
          ),
        ],
      ),
    );
  }
}

class _SparklinePainter extends CustomPainter {
  final Color color;
  _SparklinePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;

    final path = Path();
    path.moveTo(0, size.height * 0.8);
    path.quadraticBezierTo(size.width * 0.2, size.height * 0.2, size.width * 0.4, size.height * 0.6);
    path.quadraticBezierTo(size.width * 0.6, size.height * 0.9, size.width * 0.8, size.height * 0.1);
    path.lineTo(size.width, size.height * 0.4);

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
    return GestureDetector(
      onTap: onTap,
      child: Container(
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
                        child: product.image.isNotEmpty 
                          ? Image.network(
                              product.image,
                              width: double.infinity,
                              height: double.infinity,
                              fit: BoxFit.contain,
                              errorBuilder: (context, error, stackTrace) => Icon(
                                Icons.monetization_on_rounded,
                                size: 64,
                                color: AppColors.royalGold.withValues(alpha: 0.8),
                              ),
                            )
                          : Icon(
                              Icons.monetization_on_rounded,
                              size: 64,
                              color: AppColors.royalGold.withValues(alpha: 0.8),
                            ),
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
                  child: Image.asset(
                    _banners[index],
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => Container(
                      decoration: BoxDecoration(
                        gradient: AppColors.goldGradient,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Center(
                        child: Icon(Icons.stars_rounded, color: Colors.white, size: 48),
                      ),
                    ),
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

class _CategoryList extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final categories = [
      {'label': 'Gold Bullion', 'image': 'assets/images/gold_coin_100g.png', 'desc': 'Pure 24K Investment Bars'},
      {'label': 'Round Coins', 'image': 'assets/images/gold_coin_1g.png', 'desc': 'Classic Standard Minted Coins'},
      {'label': 'Divine Prints', 'image': 'assets/images/gold_coin_lakshmi_ganesh.png', 'desc': 'Lakshmi, Ganesha & more'},
      {'label': 'Historical Coins', 'image': 'assets/images/gold_coin_sovereign.png', 'desc': 'Regal Antique Style Coins'},
      {'label': 'Gift Collections', 'image': 'assets/images/gold_coin_wedding.png', 'desc': 'Exclusive Wedding & Festive Sets'},
    ];

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
                'Premium Collections',
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
              label: cat['label']!,
              imagePath: cat['image']!,
              description: cat['desc']!,
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => CatalogScreen()),
              ),
            ),
          )).toList(),
        ],
      ),
    );
  }
}

class _CategoryItem extends StatelessWidget {
  final String label;
  final String imagePath;
  final String description;
  final VoidCallback onTap;

  const _CategoryItem({
    required this.label,
    required this.imagePath,
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
              child: Image.asset(
                imagePath,
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
                        child: (product.imageUrl?.startsWith('http') ?? false)
                            ? Image.network(
                                product.imageUrl!,
                                fit: BoxFit.contain,
                              )
                            : Image.asset(
                                (product.imageUrl?.isNotEmpty ?? false) ? product.imageUrl! : 'assets/images/gold_coin.png',
                                fit: BoxFit.contain,
                              ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Text(product.name, style: AppTextStyles.labelLarge.copyWith(fontWeight: FontWeight.bold), maxLines: 1, overflow: TextOverflow.ellipsis),
              const SizedBox(height: 4),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('${product.weight}g · ${product.purity}', style: AppTextStyles.caption.copyWith(color: AppColors.grey)),
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
    );
  }
}
