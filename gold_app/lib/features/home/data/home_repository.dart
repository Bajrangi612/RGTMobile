import '../../../core/network/api_service.dart';
import '../../product/data/models/product_model.dart';

class HomeRepository {
  Future<Map<String, double>> getGoldPriceData() async {
    try {
      final response = await ApiService().getGoldPrice();
      if (response.statusCode == 200) {
        final data = response.data['data'];
        return {
          'sellPrice': double.tryParse(data['livePrice']?.toString() ?? '0') ?? 0.0,
          'buyPrice': double.tryParse(data['buyPrice']?.toString() ?? '0') ?? 0.0,
        };
      }
      return {'sellPrice': 0.0, 'buyPrice': 0.0};
    } catch (e) {
      return {'sellPrice': 0.0, 'buyPrice': 0.0};
    }
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
      final response = await ApiService().getGoldPriceHistory(limit: 2);
      if (response.statusCode == 200) {
        final List history = response.data['data']['history'];
        if (history.length >= 2) {
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
