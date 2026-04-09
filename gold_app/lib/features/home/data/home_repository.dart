import '../../../core/network/api_service.dart';
import '../../product/data/models/product_model.dart';

class HomeRepository {
  Future<Map<String, double>> getGoldPriceData() async {
    try {
      final response = await ApiService().getGoldPrice();
      if (response.statusCode == 200) {
        final data = response.data['data'];
        return {
          'sellPrice': double.tryParse(data['sellPrice']?.toString() ?? '0') ?? 0.0,
          'buyPrice': double.tryParse(data['buyPrice']?.toString() ?? '0') ?? 0.0,
        };
      }
      return {'sellPrice': 0.0, 'buyPrice': 0.0};
    } catch (e) {
      return {'sellPrice': 0.0, 'buyPrice': 0.0};
    }
  }

  Future<double> getGoldPriceChange() async {
    // For now, return a random change since the backend doesn't track 24h history yet
    return (double.parse((0.5 + (DateTime.now().second % 10) / 10).toStringAsFixed(2))) * 
           (DateTime.now().minute % 2 == 0 ? 1 : -1);
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
