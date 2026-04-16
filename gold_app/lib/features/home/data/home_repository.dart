import 'dart:convert';
import '../../../core/network/api_service.dart';
import '../../../core/services/storage_service.dart';
import '../../../core/constants/app_constants.dart';
import '../../product/data/models/product_model.dart';

class HomeRepository {
  Future<Map<String, double>> getGoldPriceData() async {
    try {
      final response = await ApiService().getGoldPrice();
      if (response.statusCode == 200) {
        final data = response.data['data'];
        final prices = {
          'sellPrice': double.tryParse(data['livePrice']?.toString() ?? '0') ?? 0.0,
          'buyPrice': double.tryParse(data['buyPrice']?.toString() ?? '0') ?? 0.0,
        };

        // Cache the latest prices
        await StorageService.write(AppConstants.priceDataKey, jsonEncode(prices));

        return prices;
      }
      return await _getCachedPrices();
    } catch (e) {
      return await _getCachedPrices();
    }
  }

  Future<Map<String, double>> _getCachedPrices() async {
    try {
      final cached = await StorageService.read(AppConstants.priceDataKey);
      if (cached != null) {
        final decoded = jsonDecode(cached) as Map<String, dynamic>;
        return {
          'sellPrice': (decoded['sellPrice'] ?? 0.0).toDouble(),
          'buyPrice': (decoded['buyPrice'] ?? 0.0).toDouble(),
        };
      }
    } catch (_) {}
    return {'sellPrice': 0.0, 'buyPrice': 0.0};
  }

  Future<List<double>> getGoldPriceHistory() async {
    try {
      final response = await ApiService().getGoldPriceHistory();
      if (response.statusCode == 200) {
        final List history = response.data['data']['history'];
        return history.map((e) => double.tryParse(e['price'].toString()) ?? 0.0).toList();
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  Future<double> getGoldPriceChange() async {
    try {
      // Sync happens every 2 hours, so 12 records = 24 hours
      final response = await ApiService().getGoldPriceHistory(limit: 12);
      if (response.statusCode == 200) {
        final List history = response.data['data']['history'];
        if (history.length >= 2) {
          // history is chronological: [oldest, ..., newest]
          final latest = double.tryParse(history.last['price'].toString()) ?? 0.0;
          final previous = double.tryParse(history.first['price'].toString()) ?? 0.0;
          
          if (previous == 0) return 0.0;
          return ((latest - previous) / previous) * 100;
        }
      }
      return 0.0;
    } catch (e) {
      return 0.0;
    }
  }

  Future<List<ProductModel>> getProducts() async {
    try {
      final response = await ApiService().getProducts();
      if (response.statusCode == 200) {
        final List productsJson = response.data['data']['products'];
        return productsJson.map((json) => ProductModel.fromJson(json)).toList();
      }
      return [];
    } catch (e) {
      return [];
    }
  }
}
