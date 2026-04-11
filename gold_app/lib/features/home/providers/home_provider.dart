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
  final bool isLoading;
  final String? error;

  HomeState({
    this.goldPrice = 0,
    this.buyPrice = 0,
    this.priceChange = 0,
    this.products = const [],
    this.isLoading = false,
    this.error,
  });

  HomeState copyWith({
    double? goldPrice,
    double? buyPrice,
    double? priceChange,
    List<ProductModel>? products,
    bool? isLoading,
    String? error,
  }) {
    return HomeState(
      goldPrice: goldPrice ?? this.goldPrice,
      buyPrice: buyPrice ?? this.buyPrice,
      priceChange: priceChange ?? this.priceChange,
      products: products ?? this.products,
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
      ]);

      final priceData = results[0] as Map<String, double>;
      state = state.copyWith(
        goldPrice: priceData['sellPrice'],
        buyPrice: priceData['buyPrice'],
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
      final results = await Future.wait([
        _repository.getGoldPriceData(),
        _repository.getGoldPriceChange(),
        _repository.getProducts(),
      ]);

      final priceData = results[0] as Map<String, double>;
      state = state.copyWith(
        goldPrice: priceData['sellPrice'],
        buyPrice: priceData['buyPrice'],
        priceChange: results[1] as double,
        products: results[2] as List<ProductModel>,
      );
    } catch (_) {}
  }
}

final homeProvider = StateNotifierProvider<HomeNotifier, HomeState>((ref) {
  return HomeNotifier(ref.watch(homeRepositoryProvider));
});
