import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../product/presentation/providers/product_providers.dart';
import '../../product/data/models/product_model.dart';
import '../../product/presentation/widgets/checkout_sheet.dart';
import '../../auth/providers/auth_provider.dart';
import '../../admin/screens/admin_product_manager.dart';
import '../screens/product_detail_screen.dart';
import '../../../widgets/gold_image.dart';
import '../../../widgets/shimmer_loader.dart';
import '../../../core/utils/formatters.dart';

class CatalogScreen extends ConsumerStatefulWidget {
  final String? initialCategoryId;
  const CatalogScreen({super.key, this.initialCategoryId});

  @override
  ConsumerState<CatalogScreen> createState() => _CatalogScreenState();
}

class _CatalogScreenState extends ConsumerState<CatalogScreen> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    if (widget.initialCategoryId != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ref.read(selectedCategoryIdProvider.notifier).state =
            widget.initialCategoryId;
      });
    }

    _scrollController.addListener(() {
      if (_scrollController.position.pixels >= 
          _scrollController.position.maxScrollExtent - 200) {
        ref.read(productsProvider.notifier).loadMore();
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final productState = ref.watch(productsProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        title: Text(
          'ROYAL COLLECTION',
          style: AppTextStyles.h3.copyWith(
            color: AppColors.royalGold,
            letterSpacing: 2,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: Container(
        decoration: BoxDecoration(gradient: AppColors.darkGradient),
        child: Column(
          children: [
            const _CategoryBar(),
            Expanded(
              child: _buildBody(productState),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBody(ProductState state) {
    if (state.isLoading && state.products.isEmpty) {
      return GridView.builder(
        padding: const EdgeInsets.all(20),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: MediaQuery.of(context).size.width > 400 ? 2 : 2,
          childAspectRatio: MediaQuery.of(context).size.width > 400 ? 0.72 : 0.60,
          mainAxisSpacing: 16,
          crossAxisSpacing: 16,
        ),
        itemCount: 4,
        itemBuilder: (context, index) => ShimmerLoader.productCard(),
      );
    }

    if (state.error != null && state.products.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, color: Colors.red, size: 48),
            const SizedBox(height: 16),
            Text(state.error!, style: const TextStyle(color: Colors.white70)),
            const SizedBox(height: 8),
            TextButton(
              onPressed: () => ref.invalidate(productsProvider),
              child: const Text('Retry', style: TextStyle(color: Color(0xFFFFD700))),
            ),
          ],
        ),
      );
    }

    if (state.products.isEmpty) {
      return const Center(
        child: Text('No products available', style: TextStyle(color: Colors.white70)),
      );
    }

    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(productsProvider);
      },
      color: AppColors.royalGold,
      child: GridView.builder(
        controller: _scrollController,
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(20),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: MediaQuery.of(context).size.width > 400 ? 2 : 2,
          childAspectRatio: MediaQuery.of(context).size.width > 400 ? 0.72 : 0.60,
          mainAxisSpacing: 16,
          crossAxisSpacing: 16,
        ),
        itemCount: state.products.length + (state.isLoadingMore ? 2 : 0),
        itemBuilder: (context, index) {
          if (index >= state.products.length) {
            return ShimmerLoader.productCard();
          }
          final product = state.products[index];
          return _CatalogProductCard(product: product)
            .animate()
            .fadeIn(delay: Duration(milliseconds: 50 * (index % 10)))
            .scale(begin: const Offset(0.9, 0.9));
        },
      ),
    );
  }
}

//////////////////////////////////////////////////////////////
/// CATEGORY BAR
//////////////////////////////////////////////////////////////

class _CategoryBar extends ConsumerStatefulWidget {
  const _CategoryBar({Key? key}) : super(key: key);

  @override
  ConsumerState<_CategoryBar> createState() => _CategoryBarState();
}

class _CategoryBarState extends ConsumerState<_CategoryBar> {
  final ScrollController _scrollController = ScrollController();

  void _scrollToSelected(int index) {
    const double itemWidth = 120;
    final double offset = (index * itemWidth) - 40;

    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        offset.clamp(0.0, _scrollController.position.maxScrollExtent),
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final categoriesAsync = ref.watch(categoriesProvider);
    final selectedId = ref.watch(selectedCategoryIdProvider);

    return categoriesAsync.when(
      data: (categories) {
        return Container(
          height: 65,
          margin: const EdgeInsets.symmetric(vertical: 10),
          child: ListView.builder(
            controller: _scrollController,
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: categories.length + 1,
            itemBuilder: (context, index) {
              final isAll = index == 0;
              final category = isAll ? null : categories[index - 1];
              final isSelected = isAll
                  ? selectedId == null
                  : selectedId == category?.id;

              return GestureDetector(
                onTap: () {
                  ref.read(selectedCategoryIdProvider.notifier).state =
                      category?.id;
                  _scrollToSelected(index);
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  margin: const EdgeInsets.only(right: 12),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppColors.royalGold
                        : AppColors.cardDark.withOpacity(0.9),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isSelected
                          ? AppColors.royalGold
                          : AppColors.royalGold.withOpacity(0.6),
                      width: 1.2,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: isSelected
                            ? AppColors.royalGold.withOpacity(0.4)
                            : Colors.black.withOpacity(0.25),
                        blurRadius: isSelected ? 12 : 6,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Center(
                    child: Text(
                      isAll ? 'ALL' : (category?.name ?? '').toUpperCase(),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: isSelected
                            ? Colors.black
                            : Colors.orange,
                        fontWeight: isSelected
                            ? FontWeight.bold
                            : FontWeight.w500,
                        fontSize: 12,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        );
      },
      loading: () => const SizedBox(
        height: 65,
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (_, __) => const SizedBox.shrink(),
    );
  }
}

//////////////////////////////////////////////////////////////
/// PRODUCT CARD
//////////////////////////////////////////////////////////////

class _CatalogProductCard extends ConsumerWidget {
  final ProductModel product;

  const _CatalogProductCard({required this.product});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pricing = product.pricing;
    // final isAdmin = ref.watch(authProvider).user?.isAdmin ?? false;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: product.isActive ? () => Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => ProductDetailScreen(product: product),
          ),
        ) : null,
        borderRadius: BorderRadius.circular(16),
        child: Ink(
          width: double.infinity,
          height: double.infinity,
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
          child: ColorFiltered(
            colorFilter: ColorFilter.mode(
              product.isActive ? Colors.transparent : Colors.grey,
              product.isActive ? BlendMode.dst : BlendMode.saturation,
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
                            imageUrl: product.imageUrl ?? '',
                            width: double.infinity,
                            height: double.infinity,
                            fit: BoxFit.contain,
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
                      // Inactive Badge
                      if (!product.isActive)
                      Positioned(
                        top: 8,
                        left: 8,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.grey.withValues(alpha: 0.8),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            'UNAVAILABLE',
                            style: AppTextStyles.caption.copyWith(color: Colors.white, fontSize: 8),
                          ),
                        ),
                      )
                      else if (product.stock <= 0)
                      // In Stock Badge (Optional, keeping small)
                      Positioned(
                        top: 8,
                        left: 8,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.red.withValues(alpha: 0.8),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            'OUT OF STOCK',
                            style: AppTextStyles.caption.copyWith(color: Colors.white, fontSize: 8),
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
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (pricing != null)
                            Text(
                              Formatters.currency(pricing.marketPrice),
                              style: AppTextStyles.caption.copyWith(
                                decoration: TextDecoration.lineThrough,
                                color: Colors.white24,
                                fontSize: 10,
                              ),
                            ),
                          Text(
                            Formatters.currency(pricing?.total ?? 0),
                            style: AppTextStyles.priceTag.copyWith(fontSize: 16),
                          ),
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
      ),
    );
}
}

//////////////////////////////////////////////////////////////
/// BADGE & PLACEHOLDER
//////////////////////////////////////////////////////////////

class _Badge extends StatelessWidget {
  final String text;
  final Color color;
  final IconData? icon;

  const _Badge({required this.text, required this.color, this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.6),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withOpacity(0.5)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, color: color, size: 10),
            const SizedBox(width: 4),
          ],
          Text(
            text,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.bold,
              fontSize: 8,
            ),
          ),
        ],
      ),
    );
  }
}

class _PlaceholderIcon extends StatelessWidget {
  const _PlaceholderIcon();

  @override
  Widget build(BuildContext context) {
    return Icon(
      Icons.workspace_premium,
      color: const Color(0xFFFFD700).withOpacity(0.2),
      size: 48,
    );
  }
}
