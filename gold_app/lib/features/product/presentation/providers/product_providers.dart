import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import '../../data/models/product_model.dart';
import '../../data/models/category_model.dart';
import '../../../order/data/models/order_model.dart';
import '../../data/repositories/product_repository.dart';
import '../../../auth/providers/auth_provider.dart';

/// Repository Provider
final productRepositoryProvider = Provider<ProductRepository>(
  (ref) => ProductRepository(),
);

/// Selected Category Provider
final selectedCategoryIdProvider = StateProvider<String?>((ref) => null);

/// Categories Provider
/// Fetches all categories so that inactive ones are visible.
/// Admins can select inactive categories; customers cannot.
final categoriesProvider = FutureProvider<List<CategoryModel>>((ref) async {
  final repository = ref.watch(productRepositoryProvider);
  return await repository.getCategories(includeInactive: true);
});

class ProductState {
  final List<ProductModel> products;
  final bool isLoading;
  final bool isLoadingMore;
  final String? error;
  final int page;
  final bool hasMore;

  const ProductState({
    this.products = const [],
    this.isLoading = false,
    this.isLoadingMore = false,
    this.error,
    this.page = 1,
    this.hasMore = true,
  });

  ProductState copyWith({
    List<ProductModel>? products,
    bool? isLoading,
    bool? isLoadingMore,
    String? error,
    int? page,
    bool? hasMore,
  }) {
    return ProductState(
      products: products ?? this.products,
      isLoading: isLoading ?? this.isLoading,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      error: error,
      page: page ?? this.page,
      hasMore: hasMore ?? this.hasMore,
    );
  }
}

class ProductNotifier extends StateNotifier<ProductState> {
  final ProductRepository _repository;
  final Ref _ref;

  ProductNotifier(this._repository, this._ref) : super(const ProductState()) {
    // Automatically load products when initialized
    _loadInitial();
    
    // Listen to category changes to reload products
    _ref.listen<String?>(selectedCategoryIdProvider, (previous, next) {
      if (previous != next) {
        _loadInitial();
      }
    });
  }

  Future<void> _loadInitial() async {
    state = state.copyWith(isLoading: true, page: 1, hasMore: true, error: null);
    try {
      final categoryId = _ref.read(selectedCategoryIdProvider);
      final products = await _repository.getProducts(
        categoryId: categoryId,
        includeInactive: true,
        page: 1,
        limit: 20,
      );
      state = state.copyWith(
        isLoading: false, 
        products: products,
        hasMore: products.length == 20,
        page: 2,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> loadMore() async {
    if (state.isLoading || state.isLoadingMore || !state.hasMore) return;
    
    state = state.copyWith(isLoadingMore: true, error: null);
    try {
      final categoryId = _ref.read(selectedCategoryIdProvider);
      final moreProducts = await _repository.getProducts(
        categoryId: categoryId,
        includeInactive: true,
        page: state.page,
        limit: 20,
      );
      
      if (moreProducts.isEmpty) {
        state = state.copyWith(isLoadingMore: false, hasMore: false);
      } else {
        state = state.copyWith(
          isLoadingMore: false,
          products: [...state.products, ...moreProducts],
          page: state.page + 1,
          hasMore: moreProducts.length == 20,
        );
      }
    } catch (e) {
      state = state.copyWith(isLoadingMore: false, error: e.toString());
    }
  }
}

/// Products Provider tracking pagination state
final productsProvider = StateNotifierProvider<ProductNotifier, ProductState>((ref) {
  final repository = ref.watch(productRepositoryProvider);
  return ProductNotifier(repository, ref);
});

/// Purchase State
class PurchaseState {
  final bool isLoading;
  final String? error;
  final OrderModel? completedOrder;

  const PurchaseState({
    this.isLoading = false,
    this.error,
    this.completedOrder,
  });

  PurchaseState copyWith({
    bool? isLoading,
    String? error,
    OrderModel? completedOrder,
  }) {
    return PurchaseState(
      isLoading: isLoading ?? this.isLoading,
      error: error,
      completedOrder: completedOrder ?? this.completedOrder,
    );
  }
}

/// Purchase Notifier
class PurchaseNotifier extends StateNotifier<PurchaseState> {
  final ProductRepository _repository;

  PurchaseNotifier(this._repository) : super(const PurchaseState());

  Future<Map<String, dynamic>?> initiatePurchase(
    String productId,
    int quantity, {
    String? referralCode,
  }) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final data = await _repository.initiateOrder(
        productId,
        quantity,
        referralCode: referralCode,
      );
      state = state.copyWith(isLoading: false);
      return data;
    } on DioException catch (e) {
      state = state.copyWith(isLoading: false, error: e.message ?? e.toString());
      return null;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return null;
    }
  }

  Future<void> verifyPayment({
    required String orderId,
    required String paymentId,
    required String signature,
  }) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final order = await _repository.confirmPayment(
        orderId: orderId,
        paymentId: paymentId,
        signature: signature,
      );
      state = state.copyWith(isLoading: false, completedOrder: order);
    } on DioException catch (e) {
      state = state.copyWith(isLoading: false, error: e.message ?? e.toString());
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }
}

/// Purchase Provider
final purchaseProvider = StateNotifierProvider<PurchaseNotifier, PurchaseState>(
  (ref) {
    final repository = ref.watch(productRepositoryProvider);
    return PurchaseNotifier(repository);
  },
);
