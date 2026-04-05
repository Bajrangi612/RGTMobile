import '../../../../core/network/api_service.dart';
import '../models/product_model.dart';
import '../models/category_model.dart';
import '../../../order/data/models/order_model.dart';

class ProductRepository {
  final ApiService _apiService = ApiService();

  /**
   * Fetch gold coin products from the backend, optionally filtered by category
   */
  Future<List<ProductModel>> getProducts({String? categoryId}) async {
    try {
      final response = await _apiService.getProducts(categoryId: categoryId);
      final List<dynamic> data = response.data['data']['products'];
      return data.map((json) => ProductModel.fromJson(json)).toList();
    } catch (e) {
      rethrow;
    }
  }

  /**
   * Fetch all categories from the backend
   */
  Future<List<CategoryModel>> getCategories() async {
    try {
      final response = await _apiService.getCategories();
      final List<dynamic> data = response.data['data']['categories'];
      return data.map((json) => CategoryModel.fromJson(json)).toList();
    } catch (e) {
      rethrow;
    }
  }

  /**
   * Initiate a purchase order
   */
  Future<Map<String, dynamic>> initiateOrder(String productId, int quantity, {String? referralCode}) async {
    try {
      final response = await _apiService.createOrder(productId, quantity, referralCode: referralCode);
      return response.data['data'];
    } catch (e) {
      rethrow;
    }
  }

  /**
   * Verify payment signature
   */
  Future<OrderModel> confirmPayment({
    required String orderId,
  }) async {
    try {
      final response = await _apiService.verifyPayment(
        orderId: orderId,
      );
      return OrderModel.fromJson(response.data['data']['order']);
    } catch (e) {
      rethrow;
    }
  }

  /**
   * Get purchase history
   */
  Future<List<OrderModel>> getMyOrders() async {
    try {
      final response = await _apiService.get('/orders/my');
      final List<dynamic> data = response.data['data']['orders'];
      return data.map((json) => OrderModel.fromJson(json)).toList();
    } catch (e) {
      rethrow;
    }
  }
}
