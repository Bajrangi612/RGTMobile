import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/product_model.dart';
import '../../data/models/category_model.dart';
import '../../../order/data/models/order_model.dart';
import '../../data/repositories/product_repository.dart';

final productRepositoryProvider = Provider((ref) => ProductRepository());

final categoriesProvider = FutureProvider<List<CategoryModel>>((ref) async {
  final repository = ref.watch(productRepositoryProvider);
  return await repository.getCategories();
});

final selectedCategoryIdProvider = StateProvider<String?>((ref) => null);

final productsProvider = FutureProvider<List<ProductModel>>((ref) async {
  final repository = ref.watch(productRepositoryProvider);
  final categoryId = ref.watch(selectedCategoryIdProvider);
  return await repository.getProducts(categoryId: categoryId);
});

class PurchaseState {
  final bool isLoading;
  final String? error;
  final OrderModel? completedOrder;

  PurchaseState({
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

class PurchaseNotifier extends StateNotifier<PurchaseState> {
  final ProductRepository _repository;

  PurchaseNotifier(this._repository) : super(PurchaseState());

  Future<Map<String, dynamic>?> initiatePurchase(String productId, int quantity, {String? referralCode}) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final data = await _repository.initiateOrder(productId, quantity, referralCode: referralCode);
      state = state.copyWith(isLoading: false);
      return data;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return null;
    }
  }

  Future<void> verifyPayment({
    required String orderId,
  }) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final order = await _repository.confirmPayment(
        orderId: orderId,
      );
      state = state.copyWith(isLoading: false, completedOrder: order);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }
}

final purchaseProvider = StateNotifierProvider<PurchaseNotifier, PurchaseState>((ref) {
  final repository = ref.watch(productRepositoryProvider);
  return PurchaseNotifier(repository);
});
