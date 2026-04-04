import '../../../core/services/mock_data_service.dart';
import '../../../core/constants/app_constants.dart';
import '../../product/data/models/product_model.dart';

class HomeRepository {
  Future<double> getGoldPrice() async {
    await MockDataService.simulateDelay(AppConstants.apiDelayShort);
    return MockDataService.getGoldPrice();
  }

  Future<double> getGoldPriceChange() async {
    return MockDataService.getGoldPriceChange();
  }

  Future<List<ProductModel>> getProducts() async {
    await MockDataService.simulateDelay(AppConstants.apiDelayMedium);
    return MockDataService.getProducts()
        .map((json) => ProductModel.fromJson(json))
        .toList();
  }
}
