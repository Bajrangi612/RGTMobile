import '../../../product/data/models/product_model.dart';
import '../../../../widgets/status_badge.dart';

class OrderModel {
  final String id;
  final String userId;
  final String productId;
  final ProductModel? product;
  final int quantity;
  final double amount;
  final double gst;
  final double total;
  final String status; // String from backend
  final String? paymentId;
  final DateTime createdAt;

  OrderModel({
    required this.id,
    required this.userId,
    required this.productId,
    this.product,
    required this.quantity,
    required this.amount,
    required this.gst,
    required this.total,
    required this.status,
    this.paymentId,
    required this.createdAt,
  });

  factory OrderModel.fromJson(Map<String, dynamic> json) {
    return OrderModel(
      id: json['id'] ?? '',
      userId: json['userId'] ?? '',
      productId: json['productId'] ?? '',
      product: json['product'] != null ? ProductModel.fromJson(json['product']) : null,
      quantity: json['quantity'] ?? 1,
      amount: (json['amount'] as num?)?.toDouble() ?? 0.0,
      gst: (json['gst'] as num?)?.toDouble() ?? 0.0,
      total: (json['total'] as num?)?.toDouble() ?? 0.0,
      status: json['status'] ?? 'PENDING',
      paymentId: json['paymentId'],
      createdAt: json['createdAt'] != null ? DateTime.parse(json['createdAt']) : DateTime.now(),
    );
  }

  // UI COMPATIBILITY GETTERS
  String get productName => product?.name ?? 'Gold Coin';
  double get weight => product?.weight ?? 1.0;
  double get price => amount;
  double get gstAmount => gst;
  double get totalPrice => total;
  String get orderDate => createdAt.toIso8601String();
  String get estimatedDelivery => '5-7 Business Days';
  String? get deliveredDate => null;
  String? get referralCode => null;
  double get referralCommission => 0.0;
  String get paymentMethod => 'Online (Razorpay)';
  
  bool get canCancel => status.toUpperCase() == 'PENDING';
  bool get canResell => status.toUpperCase() == 'DELIVERED';
  
  bool get isActive => 
    status.toUpperCase() == 'PAID' || 
    status.toUpperCase() == 'PROCESSING' || 
    status.toUpperCase() == 'SHIPPED';
    
  bool get isDelivered => status.toUpperCase() == 'DELIVERED';
  bool get isCancelled => status.toUpperCase() == 'CANCELLED';

  StatusType get statusType => statusFromString(status);

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'productId': productId,
      'product': product?.toJson(),
      'quantity': quantity,
      'amount': amount,
      'gst': gst,
      'total': total,
      'status': status,
      'paymentId': paymentId,
      'createdAt': createdAt.toIso8601String(),
    };
  }
}
