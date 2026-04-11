import '../../../../core/network/api_service.dart';
import '../models/product_model.dart';
import '../models/category_model.dart';
import '../../../order/data/models/order_model.dart';

class ProductRepository {
  final ApiService _apiService = ApiService();

  /**
   * Fetch gold coin products from the backend, optionally filtered by category
   */
  Future<List<ProductModel>> getProducts({String? categoryId, bool includeInactive = false, int page = 1, int limit = 50}) async {
    try {
      final response = await _apiService.getProducts(categoryId: categoryId, includeInactive: includeInactive, page: page, limit: limit);
      final List<dynamic> data = response.data['data']['products'];
      return data.map((json) => ProductModel.fromJson(json)).toList();
    } catch (e) {
      rethrow;
    }
  }

  /**
   * Fetch all categories from the backend
   */
  Future<List<CategoryModel>> getCategories({bool includeInactive = false}) async {
    try {
      final response = await _apiService.getCategories(includeInactive: includeInactive);
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
    required String paymentId,
    required String signature,
  }) async {
    try {
      final response = await _apiService.verifyPayment(
        orderId: orderId,
        razorpayPaymentId: paymentId,
        razorpaySignature: signature,
      );
      return OrderModel.fromJson(response.data['data']['order']);
    } catch (e) {
      rethrow;
    }
  }

  /**
   * Cancel an order
   */
  Future<void> cancelOrder(String orderId) async {
    try {
      await _apiService.cancelOrder(orderId);
    } catch (e) {
      rethrow;
    }
  }

  /**
   * Sell back a ready order
   */
  Future<void> sellBackOrder(String orderId) async {
    try {
      await _apiService.sellBackOrder(orderId);
    } catch (e) {
      rethrow;
    }
  }

  /**
   * Cancel buyback request
   */
  Future<void> cancelBuyback(String orderId) async {
    try {
      await _apiService.cancelBuyback(orderId);
    } catch (e) {
      rethrow;
    }
  }

  /**
   * Get purchase history
   */
  Future<List<OrderModel>> getMyOrders({int page = 1, int limit = 50}) async {
    try {
      final response = await _apiService.get('/orders/my', queryParameters: {'page': page, 'limit': limit});
      final List<dynamic> data = response.data['data']['orders'];
      return data.map((json) => OrderModel.fromJson(json)).toList();
    } catch (e) {
      rethrow;
    }
  }
}
