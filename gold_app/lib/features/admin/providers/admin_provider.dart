import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/api_service.dart';
import '../../product/data/models/product_model.dart';

class AdminState {
  final bool isAuthenticated;
  final bool isLoading;
  final List<dynamic> allOrders;
  final List<ProductModel> products;
  final List<dynamic> users;
  final List<dynamic> categories;
  final double totalRevenue;
  final double totalWeight;
  final int pendingOrdersCount;
  final double commissionRate;
  final int deliveryTimeDays;
  final int orderIntervalMinutes;
  final double gstRate;
  final String searchQuery;
  final String weightFilter; // 'all', '0.5', '1', '2', '5', '10'
  final String? error;

  AdminState({
    this.isAuthenticated = false,
    this.isLoading = false,
    this.allOrders = const [],
    this.products = const [],
    this.users = const [],
    this.categories = const [],
    this.totalRevenue = 0.0,
    this.totalWeight = 0.0,
    this.pendingOrdersCount = 0,
    this.commissionRate = 2.5,
    this.deliveryTimeDays = 5,
    this.orderIntervalMinutes = 15,
    this.gstRate = 3.0,
    this.searchQuery = '',
    this.weightFilter = 'all',
    this.error,
  });

  AdminState copyWith({
    bool? isAuthenticated,
    bool? isLoading,
    List<dynamic>? allOrders,
    List<ProductModel>? products,
    List<dynamic>? users,
    List<dynamic>? categories,
    double? totalRevenue,
    double? totalWeight,
    int? pendingOrdersCount,
    double? commissionRate,
    int? deliveryTimeDays,
    int? orderIntervalMinutes,
    double? gstRate,
    String? searchQuery,
    String? weightFilter,
    String? error,
  }) {
    return AdminState(
      isAuthenticated: isAuthenticated ?? this.isAuthenticated,
      isLoading: isLoading ?? this.isLoading,
      allOrders: allOrders ?? this.allOrders,
      products: products ?? this.products,
      users: users ?? this.users,
      categories: categories ?? this.categories,
      totalRevenue: totalRevenue ?? this.totalRevenue,
      totalWeight: totalWeight ?? this.totalWeight,
      pendingOrdersCount: pendingOrdersCount ?? this.pendingOrdersCount,
      commissionRate: commissionRate ?? this.commissionRate,
      deliveryTimeDays: deliveryTimeDays ?? this.deliveryTimeDays,
      orderIntervalMinutes: orderIntervalMinutes ?? this.orderIntervalMinutes,
      gstRate: gstRate ?? this.gstRate,
      searchQuery: searchQuery ?? this.searchQuery,
      weightFilter: weightFilter ?? this.weightFilter,
      error: error,
    );
  }
}

class AdminNotifier extends StateNotifier<AdminState> {
  AdminNotifier() : super(AdminState());

  Future<bool> login(String pin) async {
    state = state.copyWith(isLoading: true, error: null);

    await Future.delayed(const Duration(seconds: 1));

    if (pin == '1234') {
      state = state.copyWith(isAuthenticated: true);
      await loadInitialData();
      return true;
    } else {
      state = state.copyWith(isLoading: false, error: 'Invalid Admin PIN');
      return false;
    }
  }

  Future<void> loadInitialData() async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      print('🚀 Loading Admin Dashboard Data...');

      /// ✅ PARALLEL API CALLS (FAST)
      final results = await Future.wait([
        ApiService().getProducts(),
        ApiService().getAdminOrders(),
        ApiService().getAdminUsers(),
        ApiService().getAdminStats(),
        ApiService().getCategories(),
      ]);

      final productsResponse = results[0];
      final ordersResponse = results[1];
      final usersResponse = results[2];
      final statsResponse = results[3];
      final categoriesResponse = results[4];

      /// =======================
      /// ✅ STATS
      /// =======================
      final stats = statsResponse.data['data'];
      final totalRevenue = (stats['totalSales'] as num?)?.toDouble() ?? 0.0;
      final totalWeight = (stats['totalWeight'] as num?)?.toDouble() ?? 0.0;
      final pendingOrdersCount = (stats['pendingOrders'] as num?)?.toInt() ?? 0;

      /// =======================
      /// ✅ PRODUCTS
      /// =======================
      List<ProductModel> products = [];
      try {
        final productsData = productsResponse.data['data']?['products'];
        if (productsData is List) {
          products = productsData.map((p) => ProductModel.fromJson(p as Map<String, dynamic>)).toList();
        }
      } catch (e) {
        print('⚠️ Products parsing failed: $e');
      }

      /// =======================
      /// ✅ CATEGORIES
      /// =======================
      List<dynamic> categories = categoriesResponse.data['data'] ?? [];

      /// =======================
      /// ✅ ORDERS & USERS
      /// =======================
      List<dynamic> orders = ordersResponse.data['data'] ?? [];
      List<dynamic> users = usersResponse.data['data'] ?? [];

      /// =======================
      /// ✅ FINAL STATE UPDATE
      /// =======================
      state = state.copyWith(
        products: products,
        allOrders: orders,
        users: users,
        categories: categories,
        totalRevenue: totalRevenue,
        totalWeight: totalWeight,
        pendingOrdersCount: pendingOrdersCount,
        isLoading: false,
      );

      print('🏁 Admin Data Load Complete');
    } catch (e) {
      print('❌ Critical error: $e');
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> updateKycStatus(String userId, String status) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      await ApiService().updateUserKyc(userId, status);
      await loadInitialData();
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<bool> createCategory(Map<String, dynamic> categoryData) async {
    try {
      await ApiService().createCategory(categoryData);
      await loadInitialData();
      return true;
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return false;
    }
  }

  Future<bool> deleteCategory(String id) async {
    try {
      await ApiService().deleteCategory(id);
      await loadInitialData();
      return true;
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return false;
    }
  }

  Future<bool> addProduct(Map<String, dynamic> productData) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      await ApiService().createProduct(productData);
      await loadInitialData();
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return false;
    }
  }

  Future<bool> updateProduct(String productId, Map<String, dynamic> productData) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      await ApiService().updateProduct(productId, productData);
      await loadInitialData();
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return false;
    }
  }

  Future<bool> deleteProduct(String productId) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      await ApiService().deleteProduct(productId);
      await loadInitialData();
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return false;
    }
  }

  Future<void> updateOrderStatus(String orderId, String status) async {
    final updatedOrders = state.allOrders.map((order) {
      if (order['id'] == orderId) {
        return {...order, 'status': status};
      }
      return order;
    }).toList();

    state = state.copyWith(allOrders: updatedOrders);
  }

  Future<void> updateUserStatus(String userId, String status) async {
    final updatedUsers = state.users.map((user) {
      if (user['id'] == userId) {
        return {...user, 'status': status};
      }
      return user;
    }).toList();

    state = state.copyWith(users: updatedUsers);
  }

  void updateSearchQuery(String query) {
    state = state.copyWith(searchQuery: query);
  }

  void updateWeightFilter(String filter) {
    state = state.copyWith(weightFilter: filter);
  }

  List<ProductModel> get filteredProducts {
    return state.products.where((p) {
      // 1. Search Query
      final matchesSearch = p.name.toLowerCase().contains(state.searchQuery.toLowerCase()) ||
          (p.description?.toLowerCase().contains(state.searchQuery.toLowerCase()) ?? false);

      // 2. Weight Filter
      bool matchesWeight = true;
      if (state.weightFilter != 'all') {
        final filterVal = double.tryParse(state.weightFilter) ?? 0.0;
        matchesWeight = p.weight == filterVal;
      }

      return matchesSearch && matchesWeight;
    }).toList();
  }

  Future<void> updateConfigs({
    double? commissionRate,
    int? deliveryTimeDays,
    int? orderIntervalMinutes,
    double? gstRate,
  }) async {
    state = state.copyWith(
      commissionRate: commissionRate ?? state.commissionRate,
      deliveryTimeDays: deliveryTimeDays ?? state.deliveryTimeDays,
      orderIntervalMinutes: orderIntervalMinutes ?? state.orderIntervalMinutes,
      gstRate: gstRate ?? state.gstRate,
    );
  }

  void logout() {
    state = AdminState();
  }
}

final adminProvider = StateNotifierProvider<AdminNotifier, AdminState>((ref) {
  return AdminNotifier();
});
