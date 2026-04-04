import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/home_repository.dart';
import '../../product/data/models/product_model.dart';

final homeRepositoryProvider = Provider<HomeRepository>((ref) => HomeRepository());

class HomeState {
  final double goldPrice;
  final double priceChange;
  final List<ProductModel> products;
  final bool isLoading;
  final String? error;

  HomeState({
    this.goldPrice = 0,
    this.priceChange = 0,
    this.products = const [],
    this.isLoading = false,
    this.error,
  });

  HomeState copyWith({
    double? goldPrice,
    double? priceChange,
    List<ProductModel>? products,
    bool? isLoading,
    String? error,
  }) {
    return HomeState(
      goldPrice: goldPrice ?? this.goldPrice,
      priceChange: priceChange ?? this.priceChange,
      products: products ?? this.products,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

class HomeNotifier extends StateNotifier<HomeState> {
  final HomeRepository _repository;

  HomeNotifier(this._repository) : super(HomeState());

  Future<void> loadDashboard() async {
    state = state.copyWith(isLoading: true);
    try {
      // Parallelize data fetching for 2x speedup
      final results = await Future.wait([
        _repository.getGoldPrice(),
        _repository.getGoldPriceChange(),
        _repository.getProducts(),
      ]);

      state = state.copyWith(
        goldPrice: results[0] as double,
        priceChange: results[1] as double,
        products: results[2] as List<ProductModel>,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> refreshPrice() async {
    try {
      final price = await _repository.getGoldPrice();
      final change = await _repository.getGoldPriceChange();
      state = state.copyWith(goldPrice: price, priceChange: change);
    } catch (_) {}
  }
}

final homeProvider = StateNotifierProvider<HomeNotifier, HomeState>((ref) {
  return HomeNotifier(ref.watch(homeRepositoryProvider));
});
