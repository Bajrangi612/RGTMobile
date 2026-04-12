import 'dart:typed_data';
import 'package:dio/dio.dart';
import '../services/storage_service.dart';
import '../constants/app_constants.dart';
import '../config/env_config.dart';
import 'package:flutter/foundation.dart';

class ApiService {
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;

  late final Dio _dio;
  Dio get dio => _dio;

  ApiService._internal() {
    _dio = Dio(
      BaseOptions(
        baseUrl: EnvConfig.baseUrl,
        connectTimeout: const Duration(seconds: 10),
        receiveTimeout: const Duration(seconds: 10),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ),
    );

    // Authentication Interceptor
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final token = await StorageService.read(AppConstants.tokenKey);
          if (kDebugMode) {
            debugPrint('🌐 [ApiService] Request: ${options.method} ${options.baseUrl}${options.path}');
          }
          if (token != null) {
            if (kDebugMode) {
              debugPrint('🔑 [ApiService] Token attached');
            }
            options.headers['Authorization'] = 'Bearer $token';
          }
          return handler.next(options);
        },
        onError: (DioException e, handler) {
          if (kDebugMode) {
            debugPrint('❌ [ApiService] Error: ${e.response?.statusCode} - ${e.message}');
            if (e.response?.data != null) {
              debugPrint('📄 [ApiService] Error data: ${e.response?.data}');
            }
          }
          
          // Try to extract the error message from the response body
          if (e.response?.data != null && e.response?.data is Map) {
            final data = e.response?.data as Map;
            if (data.containsKey('message')) {
              // Create a custom error message for the exception
              e = e.copyWith(message: data['message']);
            }
          }
          
          return handler.next(e);
        },
      ),
    );
  }

  Dio get client => _dio;

  // Convenience methods
  Future<Response> get(
    String path, {
    Map<String, dynamic>? queryParameters,
  }) async {
    return await _dio.get(path, queryParameters: queryParameters);
  }

  Future<Response> logout() async {
    return await _dio.post('/auth/logout');
  }

  // --- NOTIFICATIONS ---
  
  Future<Response> updateFcmToken(String token) async {
    return await _dio.post(
      '/notifications/token',
      data: {'token': token},
    );
  }

  Future<Response> getMe() async {
    return await _dio.get('/auth/me');
  }

  Future<Response> post(String path, {dynamic data}) async {
    return await _dio.post(path, data: data);
  }

  Future<Response> patch(String path, {dynamic data}) async {
    return await _dio.patch(path, data: data);
  }

  Future<Response> delete(String path, {dynamic data}) async {
    return await _dio.delete(path, data: data);
  }

  // ─── Products & Orders ──────────────────────────────────────────────────

  Future<Response> getProducts({String? categoryId, bool includeInactive = false, int page = 1, int limit = 50}) async {
    final Map<String, dynamic> params = {};
    if (categoryId != null) params['categoryId'] = categoryId;
    if (includeInactive) params['includeInactive'] = 'true';
    params['page'] = page;
    params['limit'] = limit;
    
    return await _dio.get('/products', queryParameters: params);
  }

  Future<Response> getGoldPrice() async {
    return await _dio.get('/products/price');
  }

  Future<Response> getGoldPriceHistory({int limit = 24}) async {
    return await _dio.get('/products/price-history', queryParameters: {'limit': limit});
  }

  Future<Response> getCategories({bool includeInactive = false}) async {
    return await _dio.get(
      '/categories',
      queryParameters: includeInactive ? {'includeInactive': 'true'} : null,
    );
  }

  Future<Response> createProduct(Map<String, dynamic> data) async {
    return await _dio.post('/products', data: data);
  }

  Future<Response> updateProduct(String id, Map<String, dynamic> data) async {
    return await _dio.patch('/products/$id', data: data);
  }

  Future<Response> deleteProduct(String id) async {
    return await _dio.delete('/products/$id');
  }

  Future<Response> updateOrderStatus(String id, String status) async {
    return await _dio.patch('/orders/$id/status', data: {'status': status});
  }

  Future<Response> getAdminOrders({int page = 1, int limit = 50}) async {
    return await _dio.get('/orders', queryParameters: {'page': page, 'limit': limit});
  }

  Future<Response> getAdminUsers() async {
    return await _dio.get('/users');
  }

  Future<Response> updateUserKyc(String userId, String status) async {
    return await _dio.patch('/users/$userId/kyc', data: {'status': status});
  }

  Future<Response> updateUserBank(String userId, String status) async {
    return await _dio.patch(
      '/users/$userId/bank-status',
      data: {'status': status},
    );
  }

  Future<Response> updateProfile(Map<String, dynamic> data) async {
    return await _dio.patch('/users/profile', data: data);
  }

  Future<Response> getAdminStats() async {
    return await _dio.get('/admin/stats');
  }

  Future<Response> getAdminTransactions() async {
    return await _dio.get('/admin/transactions');
  }

  Future<Response> updateAdminSettings(Map<String, dynamic> data) async {
    return await _dio.post('/admin/settings', data: data);
  }

  Future<Response> getAdminConfigs() async {
    return await _dio.get('/configs');
  }

  // ─── Bank & KYC ─────────────────────────────────────────────────────────

  Future<Response> submitBankDetails(Map<String, dynamic> data) async {
    return await _dio.post('/bank/submit', data: data);
  }

  Future<Response> getBankDetails() async {
    return await _dio.get('/bank/my');
  }

  Future<Response> getKycStatus() async {
    return await _dio.get(
      '/users/kyc/status',
    ); // Verify if this and /auth/me is enough
  }

  Future<Response> createCategory(Map<String, dynamic> data) async {
    return await _dio.post('/categories', data: data);
  }

  Future<Response> deleteCategory(String id) async {
    return await _dio.delete('/categories/$id');
  }

  Future<Response> createOrder(
    String productId,
    int quantity, {
    String? referralCode,
  }) async {
    return await _dio.post(
      '/orders/start',
      data: {
        'productId': productId,
        'quantity': quantity,
        'referralCode': referralCode,
      },
    );
  }

  Future<Response> verifyPayment({
    required String orderId,
    required String razorpayPaymentId,
    required String razorpaySignature,
  }) async {
    return await _dio.post(
      '/orders/verify',
      data: {
        'orderId': orderId,
        'razorpayPaymentId': razorpayPaymentId,
        'razorpaySignature': razorpaySignature,
      },
    );
  }

  Future<Response> cancelOrder(String orderId) async {
    return await _dio.put('/orders/$orderId/cancel');
  }

  Future<Response> sellBackOrder(String orderId) async {
    return await _dio.put('/orders/$orderId/sell-back');
  }

  Future<Response> uploadImage(Uint8List bytes, String fileName) async {
    final formData = FormData.fromMap({
      'image': MultipartFile.fromBytes(bytes, filename: fileName),
    });
    return await _dio.post('/images/upload', data: formData);
  }

  Future<Response> updateGoldPrice(double buyPrice, double sellPrice) async {
    return await _dio.post(
      '/products/price',
      data: {'buyPrice': buyPrice, 'sellPrice': sellPrice},
    );
  }

  // ─── Wallet & Transactions ──────────────────────────────────────────────

  Future<Response> getWalletDetails() async {
    return await _dio.get('/wallet/details');
  }

  Future<Response> requestWithdrawal(double amount, String type) async {
    return await _dio.post(
      '/wallet/withdraw',
      data: {'amount': amount, 'type': type},
    );
  }

  Future<Response> getMyWithdrawals({int page = 1, int limit = 50}) async {
    return await _dio.get('/wallet/my-withdrawals', queryParameters: {'page': page, 'limit': limit});
  }  /**
   * Cancel buyback request
   */
  Future<Response> cancelBuyback(String orderId) async {
    return await _dio.put('/orders/$orderId/cancel-buyback');
  }

  /**
   * Check if a referral code is valid and get the referee's name
   */
  Future<Response> verifyReferralCode(String code) async {
    return await _dio.get('/auth/referral-check/$code');
  }
}
