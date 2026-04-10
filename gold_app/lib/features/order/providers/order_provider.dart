import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../product/presentation/providers/product_providers.dart';
import '../../product/data/repositories/product_repository.dart';
import '../data/models/order_model.dart';

class OrderState {
  final List<OrderModel> orders;
  final bool isLoading;
  final String? error;

  OrderState({
    this.orders = const [],
    this.isLoading = false,
    this.error,
  });

  OrderState copyWith({
    List<OrderModel>? orders,
    bool? isLoading,
    String? error,
  }) {
    return OrderState(
      orders: orders ?? this.orders,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }

  bool get hasActiveOrder => orders.any((o) => o.isActive);
}

class OrderNotifier extends StateNotifier<OrderState> {
  final ProductRepository _repository;

  OrderNotifier(this._repository) : super(OrderState());

  Future<void> loadOrders() async {
    if (state.isLoading) return;
    state = state.copyWith(isLoading: true, error: null);
    try {
      final orders = await _repository.getMyOrders();
      state = state.copyWith(orders: orders, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<bool> cancelOrder(String orderId) async {
    // Optimistic Update
    final List<OrderModel> originalOrders = state.orders;
    final List<OrderModel> updatedOrders = originalOrders.map<OrderModel>((o) {
      if (o.id == orderId) {
        return o.copyWith(status: 'CANCELLED');
      }
      return o;
    }).toList();
    
    state = state.copyWith(orders: updatedOrders);

    try {
      await _repository.cancelOrder(orderId);
      await loadOrders(); // Confirm with server
      return true;
    } catch (e) {
      // Rollback on error
      state = state.copyWith(orders: originalOrders, error: e.toString());
      return false;
    }
  }

  Future<bool> sellBackOrder(String orderId) async {
    state = state.copyWith(isLoading: true);
    try {
      await _repository.sellBackOrder(orderId);
      await loadOrders(); // Refresh state
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return false;
    }
  }
}

final orderProvider = StateNotifierProvider<OrderNotifier, OrderState>((ref) {
  final repository = ref.watch(productRepositoryProvider);
  return OrderNotifier(repository);
});
