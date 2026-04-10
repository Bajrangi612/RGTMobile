import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/api_service.dart';
import '../../../core/services/storage_service.dart';
import '../../../core/constants/app_constants.dart';
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
  final String orderSearchQuery;
  final String weightFilter;
  final int lowStockThreshold;
  final List<dynamic> allTransactions;
  final List<dynamic> withdrawalRequests;
  final String? error;

  AdminState({
    this.isAuthenticated = false,
    this.isLoading = false,
    this.allOrders = const [],
    this.products = const [],
    this.users = const [],
    this.categories = const [],
    this.allTransactions = const [],
    this.totalRevenue = 0.0,
    this.totalWeight = 0.0,
    this.pendingOrdersCount = 0,
    this.commissionRate = 2.5,
    this.deliveryTimeDays = 5,
    this.orderIntervalMinutes = 15,
    this.gstRate = 3.0,
    this.searchQuery = '',
    this.orderSearchQuery = '',
    this.weightFilter = 'all',
    this.lowStockThreshold = 10,
    this.withdrawalRequests = const [],
    this.error,
  });

  AdminState copyWith({
    bool? isAuthenticated,
    bool? isLoading,
    List<dynamic>? allOrders,
    List<ProductModel>? products,
    List<dynamic>? users,
    List<dynamic>? categories,
    List<dynamic>? allTransactions,
    double? totalRevenue,
    double? totalWeight,
    int? pendingOrdersCount,
    double? commissionRate,
    int? deliveryTimeDays,
    int? orderIntervalMinutes,
    double? gstRate,
    String? searchQuery,
    String? orderSearchQuery,
    String? weightFilter,
    int? lowStockThreshold,
    List<dynamic>? withdrawalRequests,
    String? error,
  }) {
    return AdminState(
      isAuthenticated: isAuthenticated ?? this.isAuthenticated,
      isLoading: isLoading ?? this.isLoading,
      allOrders: allOrders ?? this.allOrders,
      products: products ?? this.products,
      users: users ?? this.users,
      categories: categories ?? this.categories,
      allTransactions: allTransactions ?? this.allTransactions,
      totalRevenue: totalRevenue ?? this.totalRevenue,
      totalWeight: totalWeight ?? this.totalWeight,
      pendingOrdersCount: pendingOrdersCount ?? this.pendingOrdersCount,
      commissionRate: commissionRate ?? this.commissionRate,
      deliveryTimeDays: deliveryTimeDays ?? this.deliveryTimeDays,
      orderIntervalMinutes: orderIntervalMinutes ?? this.orderIntervalMinutes,
      gstRate: gstRate ?? this.gstRate,
      searchQuery: searchQuery ?? this.searchQuery,
      orderSearchQuery: orderSearchQuery ?? this.orderSearchQuery,
      weightFilter: weightFilter ?? this.weightFilter,
      lowStockThreshold: lowStockThreshold ?? this.lowStockThreshold,
      withdrawalRequests: withdrawalRequests ?? this.withdrawalRequests,
      error: error,
    );
  }
}

class AdminNotifier extends StateNotifier<AdminState> {
  AdminNotifier() : super(AdminState());

  Future<bool> login(String pin) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final response = await ApiService().post('/auth/admin-login', data: {'pin': pin});
      
      if (response.statusCode == 200) {
        final data = response.data['data'];
        final token = data['token'];
        
        if (token != null) {
          await StorageService.write(AppConstants.tokenKey, token);
        }

        state = state.copyWith(isAuthenticated: true, isLoading: false);
        await loadInitialData();
        return true;
      } else {
        state = state.copyWith(isLoading: false, error: 'Invalid Admin PIN');
        return false;
      }
    } catch (e) {
      state = state.copyWith(isLoading: false, error: 'Authorization Failed: ${e.toString()}');
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
        ApiService().getAdminTransactions(),
      ]);

      final productsResponse = results[0];
      final ordersResponse = results[1];
      final usersResponse = results[2];
      final statsResponse = results[3];
      final categoriesResponse = results[4];
      final transactionsResponse = results[5];

      /// =======================
      /// ✅ STATS
      /// =======================
      final stats = statsResponse.data['data'];
      final totalRevenue = _toDouble(stats['totalSales']);
      final totalWeight = _toDouble(stats['totalWeight']);
      final pendingOrdersCount = int.tryParse(stats['pendingOrders']?.toString() ?? '0') ?? 0;

      /// =======================
      /// ✅ PRODUCTS
      /// =======================
      List<ProductModel> products = [];
      try {
        final dynamic rawProducts = productsResponse.data['data'];
        print('📦 Products Data type: ${rawProducts.runtimeType}');
        final productsData = rawProducts is Map ? rawProducts['products'] : null;
        if (productsData is List) {
          products = productsData.map((p) => ProductModel.fromJson(p as Map<String, dynamic>)).toList();
          print('✅ Parsed ${products.length} products');
        } else {
          print('⚠️ productsData is not a List: ${productsData.runtimeType}');
        }
      } catch (e) {
        print('⚠️ Products parsing failed: $e');
      }

      /// =======================
      /// ✅ CATEGORIES
      /// =======================
      List<dynamic> categories = [];
      try {
        final dynamic rawCat = categoriesResponse.data['data'];
        print('📂 Categories Data type: ${rawCat.runtimeType}');
        final catData = rawCat is Map ? rawCat['categories'] : null;
        if (catData is List) {
          categories = catData;
          print('✅ Parsed ${categories.length} categories');
        } else {
          print('⚠️ catData is not a List: ${catData.runtimeType}');
        }
      } catch (e) {
        print('⚠️ Categories parsing failed: $e');
      }

      /// =======================
      /// ✅ ORDERS & USERS
      /// =======================
      List<dynamic> orders = [];
      try {
        final dynamic rawOrders = ordersResponse.data['data'];
        final ordersData = rawOrders is Map ? rawOrders['orders'] : null;
        if (ordersData is List) orders = ordersData;
      } catch (e) { print('⚠️ Orders parsing failed: $e'); }

      List<dynamic> users = [];
      try {
        final dynamic rawUsers = usersResponse.data['data'];
        final usersData = rawUsers is Map ? rawUsers['users'] : null;
        if (usersData is List) users = usersData;
      } catch (e) { print('⚠️ Users parsing failed: $e'); }

      List<dynamic> transactions = [];
      try {
        final dynamic rawTxns = transactionsResponse.data['data'];
        final txnsData = rawTxns is Map ? rawTxns['transactions'] : null;
        if (txnsData is List) transactions = txnsData;
      } catch (e) { print('⚠️ Transactions parsing failed: $e'); }

      /// =======================
      /// ✅ FINAL STATE UPDATE
      /// =======================
      state = state.copyWith(
        products: products,
        allOrders: orders,
        users: users,
        categories: categories,
        allTransactions: transactions,
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

  Future<void> updateBankStatus(String userId, String status) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      await ApiService().updateUserBank(userId, status);
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
    // Optimistic Update
    final originalOrders = state.allOrders;
    final updatedOrders = originalOrders.map((o) {
      if (o['id'] == orderId) {
        return {...o, 'status': status};
      }
      return o;
    }).toList();
    
    state = state.copyWith(allOrders: updatedOrders);

    try {
      await ApiService().updateOrderStatus(orderId, status);
      await loadInitialData(); // Confirm with server
    } catch (e) {
      // Rollback on error
      state = state.copyWith(allOrders: originalOrders, error: e.toString());
    }
  }

  Future<void> updateUserStatus(String userId, String status) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      // Assuming we have an updateStatus endpoint for user, or use KYC endpoint if it's related
      await ApiService().updateUserKyc(userId, status); 
      await loadInitialData();
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  void updateSearchQuery(String query) {
    state = state.copyWith(searchQuery: query);
  }

  void updateOrderSearchQuery(String query) {
    state = state.copyWith(orderSearchQuery: query);
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
    int? lowStockThreshold,
  }) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      if (deliveryTimeDays != null) {
        await ApiService().updateAdminSettings({'delivery_days': deliveryTimeDays});
      }
      
      state = state.copyWith(
        commissionRate: commissionRate ?? state.commissionRate,
        deliveryTimeDays: deliveryTimeDays ?? state.deliveryTimeDays,
        orderIntervalMinutes: orderIntervalMinutes ?? state.orderIntervalMinutes,
        gstRate: gstRate ?? state.gstRate,
        lowStockThreshold: lowStockThreshold ?? state.lowStockThreshold,
        isLoading: false,
      );
      
      await loadInitialData();
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<bool> updateGoldPrice(double buyPrice, double sellPrice) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      await ApiService().updateGoldPrice(buyPrice, sellPrice);
      await loadInitialData();
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return false;
    }
  }

  void logout() {
    state = AdminState();
  }

  double _toDouble(dynamic value) {
    if (value is num) return value.toDouble();
    return double.tryParse(value?.toString() ?? '0') ?? 0.0;
  }

  // --- Withdrawal Management ---

  Future<void> fetchWithdrawals() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final response = await ApiService().get('/admin/withdrawals');
      state = state.copyWith(
        withdrawalRequests: response.data['data']['requests'],
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<bool> updateWithdrawalStatus(String id, String status, {String? notes}) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      await ApiService().patch('/admin/withdrawals/$id/status', data: {
        'status': status,
        if (notes != null) 'adminNotes': notes,
      });
      await fetchWithdrawals(); // Refresh
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return false;
    }
  }
}


final adminProvider = StateNotifierProvider<AdminNotifier, AdminState>((ref) {
  return AdminNotifier();
});
