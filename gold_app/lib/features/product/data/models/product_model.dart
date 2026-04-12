import 'category_model.dart';

class ProductModel {
  final String id;
  final String name;
  final String? description;
  final double weight;
  final double makingCharges;
  final double fixedPrice;
  final String purity;
  final String? imageUrl;
  final int stock;
  final String? categoryId;
  final CategoryModel? category;
  final ProductPricing? pricing;
  final int pendingOrdersCount;
  final bool isPremium;
  final bool isPromoted;
  final bool isActive;

  ProductModel({
    required this.id,
    required this.name,
    this.description,
    required this.weight,
    this.makingCharges = 0.0,
    this.fixedPrice = 0.0,
    required this.purity,
    this.imageUrl,
    required this.stock,
    this.categoryId,
    this.category,
    this.pricing,
    this.pendingOrdersCount = 0,
    this.isPremium = false,
    this.isPromoted = false,
    this.isActive = true,
  });

  factory ProductModel.fromJson(Map<String, dynamic> json) {
    return ProductModel(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      description: json['description']?.toString(),
      weight: _toDouble(json['weight']),
      makingCharges: _toDouble(json['makingCharges']),
      fixedPrice: _toDouble(json['fixedPrice']),
      purity: json['purity']?.toString() ?? '24K',
      imageUrl: json['imageUrl']?.toString(),
      stock: _toInt(json['stock']),
      categoryId: json['categoryId']?.toString(),
      category: json['category'] != null
          ? CategoryModel.fromJson(json['category'])
          : null,
      pricing: json['pricing'] != null && json['pricing'] is Map
          ? ProductPricing.fromJson(json['pricing'] as Map<String, dynamic>)
          : null,
      pendingOrdersCount: _toInt(json['_count']?['orders']),
      isPremium: json['isPremium'] ?? false,
      isPromoted: json['isPromoted'] ?? false,
      isActive: json['isActive'] ?? true,
    );
  }

  // 🔥 SAFE CONVERTERS
  static double _toDouble(dynamic value) {
    if (value is num) return value.toDouble();
    return double.tryParse(value?.toString() ?? '0') ?? 0.0;
  }

  static int _toInt(dynamic value) {
    if (value is int) return value;
    return int.tryParse(value?.toString() ?? '0') ?? 0;
  }

  // UI GETTERS
  double get price => pricing?.total ?? 0.0;
  double? get oldPrice => null;
  List<String> get images =>
      imageUrl != null && imageUrl!.isNotEmpty ? [imageUrl!] : [];
  String get image => imageUrl ?? '';
  String get fineness => '99.9% Pure Gold';

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'weight': weight,
      'purity': purity,
      'imageUrl': imageUrl,
      'stock': stock,
      'categoryId': categoryId,
      'category': category?.toJson(),
      'pricing': pricing?.toJson(),
      'pendingOrdersCount': pendingOrdersCount,
      'isPremium': isPremium,
      'isPromoted': isPromoted,
      'isActive': isActive,
    };
  }
}

class ProductPricing {
  final double marketPrice;
  final double discountAmount;
  final double discountedGoldValue;
  final double goldGst;
  final double makingCharges;
  final double makingGst;
  final double gstAmount;
  final double total;
  final double weight;
  final double discountPercent;

  ProductPricing({
    required this.marketPrice,
    required this.discountAmount,
    required this.discountedGoldValue,
    required this.goldGst,
    required this.makingCharges,
    required this.makingGst,
    required this.gstAmount,
    required this.total,
    required this.weight,
    this.discountPercent = 0.0,
  });

  factory ProductPricing.fromJson(Map<String, dynamic> json) {
    return ProductPricing(
      marketPrice: _toDouble(json['marketPrice']),
      discountAmount: _toDouble(json['discountAmount']),
      discountedGoldValue: _toDouble(json['discountedGoldValue']),
      goldGst: _toDouble(json['goldGst']),
      makingCharges: _toDouble(json['makingCharges']),
      makingGst: _toDouble(json['makingGst']),
      gstAmount: _toDouble(json['gstAmount']),
      total: _toDouble(json['total']),
      weight: _toDouble(json['weight']),
      discountPercent: _toDouble(json['discountPercent']),
    );
  }

  static double _toDouble(dynamic value) {
    if (value is num) return value.toDouble();
    return double.tryParse(value?.toString() ?? '0') ?? 0.0;
  }

  Map<String, dynamic> toJson() {
    return {
      'marketPrice': marketPrice,
      'discountAmount': discountAmount,
      'discountedGoldValue': discountedGoldValue,
      'goldGst': goldGst,
      'makingCharges': makingCharges,
      'makingGst': makingGst,
      'gstAmount': gstAmount,
      'total': total,
      'weight': weight,
      'discountPercent': discountPercent,
    };
  }
}
