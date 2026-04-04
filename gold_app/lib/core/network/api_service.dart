import 'dart:typed_data';
import 'package:dio/dio.dart';
import '../services/storage_service.dart';
import '../constants/app_constants.dart';

class ApiService {
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;

  late final Dio _dio;

  // Update this to your local backend IP if testing on a physical device
  static const String baseUrl = 'http://localhost:4000/api';

  ApiService._internal() {
    _dio = Dio(
      BaseOptions(
        baseUrl: baseUrl,
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
          print(
            '🌐 [ApiService] Request: ${options.method} ${options.baseUrl}${options.path}',
          );
          if (token != null) {
            print('🔑 [ApiService] Token found: ${token.substring(0, 10)}...');
            options.headers['Authorization'] = 'Bearer $token';
          } else {
            print('⚠️ [ApiService] No token found for ${options.path}');
          }
          return handler.next(options);
        },
        onError: (DioException e, handler) {
          print(
            '❌ [ApiService] Error: ${e.response?.statusCode} - ${e.message}',
          );
          if (e.response?.data != null) {
            print('📄 [ApiService] Error data: ${e.response?.data}');
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

  Future<Response> getProducts({String? categoryId}) async {
    return await _dio.get(
      '/products',
      queryParameters: {'categoryId': ?categoryId},
    );
  }

  Future<Response> getCategories() async {
    return await _dio.get('/categories');
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

  Future<Response> updateProduct(String id, Map<String, dynamic> data) async {
    return await _dio.patch('/products/$id', data: data);
  }

  Future<Response> deleteProduct(String id) async {
    return await _dio.delete('/products/$id');
  }

  Future<Response> getAdminOrders() async {
    return await _dio.get('/orders');
  }

  Future<Response> getAdminUsers() async {
    return await _dio.get('/users');
  }

  Future<Response> updateUserKyc(String userId, String status) async {
    return await _dio.patch('/users/$userId/kyc', data: {'status': status});
  }

  Future<Response> getAdminStats() async {
    return await _dio.get('/users/stats');
  }

  Future<Response> getAdminConfigs() async {
    return await _dio.get('/configs');
  }

  Future<Response> createCategory(Map<String, dynamic> data) async {
    return await _dio.post('/categories', data: data);
  }

  Future<Response> deleteCategory(String id) async {
    return await _dio.delete('/categories/$id');
  }

  Future<Response> createOrder(String productId, int quantity) async {
    return await _dio.post(
      '/orders/start',
      data: {'productId': productId, 'quantity': quantity},
    );
  }

  Future<Response> verifyPayment({
    required String orderId,
    required String razorpayOrderId,
    required String razorpayPaymentId,
    required String razorpaySignature,
  }) async {
    return await _dio.post(
      '/orders/verify',
      data: {
        'orderId': orderId,
        'razorpayOrderId': razorpayOrderId,
        'razorpayPaymentId': razorpayPaymentId,
        'razorpaySignature': razorpaySignature,
      },
    );
  }

  Future<Response> uploadImage(Uint8List bytes, String fileName) async {
    final formData = FormData.fromMap({
      'image': MultipartFile.fromBytes(bytes, filename: fileName),
    });
    return await _dio.post('/images/upload', data: formData);
  }
}
