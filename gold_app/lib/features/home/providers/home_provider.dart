import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/home_repository.dart';
import '../../product/data/models/product_model.dart';

final homeRepositoryProvider = Provider<HomeRepository>((ref) => HomeRepository());

class HomeState {
  final double goldPrice; // sellPrice
  final double buyPrice;
  final double priceChange;
  final List<ProductModel> products;
  final List<double> priceHistory;
  final bool isLoading;
  final String? error;

  HomeState({
    this.goldPrice = 0,
    this.buyPrice = 0,
    this.priceChange = 0,
    this.products = const [],
    this.priceHistory = const [],
    this.isLoading = false,
    this.error,
  });

  HomeState copyWith({
    double? goldPrice,
    double? buyPrice,
    double? priceChange,
    List<ProductModel>? products,
    List<double>? priceHistory,
    bool? isLoading,
    String? error,
  }) {
    return HomeState(
      goldPrice: goldPrice ?? this.goldPrice,
      buyPrice: buyPrice ?? this.buyPrice,
      priceChange: priceChange ?? this.priceChange,
      products: products ?? this.products,
      priceHistory: priceHistory ?? this.priceHistory,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

class HomeNotifier extends StateNotifier<HomeState> {
  final HomeRepository _repository;
  Timer? _timer;

  HomeNotifier(this._repository) : super(HomeState()) {
    _startPolling();
  }

  void _startPolling() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 60), (_) => refreshPrice());
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> loadDashboard() async {
    state = state.copyWith(isLoading: true);
    try {
      final results = await Future.wait([
        _repository.getGoldPriceData(),
        _repository.getGoldPriceChange(),
        _repository.getProducts(),
        _repository.getGoldPriceHistory(),
      ]);

      final priceData = results[0] as Map<String, double>;
      state = state.copyWith(
        goldPrice: priceData['sellPrice'],
        buyPrice: priceData['buyPrice'],
        priceChange: results[1] as double,
        products: results[2] as List<ProductModel>,
        priceHistory: results[3] as List<double>,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  /// Refresh only price-related data (Optimized for polling)
  Future<void> refreshPrice() async {
    try {
      final results = await Future.wait([
        _repository.getGoldPriceData(),
        _repository.getGoldPriceChange(),
        _repository.getGoldPriceHistory(),
      ]);

      final priceData = results[0] as Map<String, double>;
      state = state.copyWith(
        goldPrice: priceData['sellPrice'],
        buyPrice: priceData['buyPrice'],
        priceChange: results[1] as double,
        priceHistory: results[2] as List<double>,
      );
    } catch (_) {
      // Fail silently for polling
    }
  }

  /// Explicitly refresh product listing
  Future<void> refreshProducts() async {
    try {
      final products = await _repository.getProducts();
      state = state.copyWith(products: products);
    } catch (_) {}
  }
}

final homeProvider = StateNotifierProvider<HomeNotifier, HomeState>((ref) {
  return HomeNotifier(ref.watch(homeRepositoryProvider));
});
