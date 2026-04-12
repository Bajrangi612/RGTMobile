import 'package:intl/intl.dart';
import '../../../product/data/models/product_model.dart';
import '../../../../widgets/status_badge.dart';
import 'order_status_history_model.dart';

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
  final double? orderWeight;
  final String? referralCode;
  final String? invoiceNo;
  final DateTime? deliveryDate;
  final double? goldPriceAtPurchase;
  final String? invoiceUrl;
  final List<OrderStatusHistoryModel> statusHistory;
  final String? customerName;
  final String? customerPhone;
  final String? customerAddress;
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
    this.orderWeight,
    this.referralCode,
    this.invoiceNo,
    this.deliveryDate,
    this.goldPriceAtPurchase,
    this.invoiceUrl,
    this.statusHistory = const [],
    this.customerName,
    this.customerPhone,
    this.customerAddress,
    required this.createdAt,
  });

  factory OrderModel.fromJson(Map<String, dynamic> json) {
    double parseDouble(dynamic value) {
      if (value == null) return 0.0;
      if (value is num) return value.toDouble();
      if (value is String) return double.tryParse(value) ?? 0.0;
      return 0.0;
    }

    return OrderModel(
      id: json['id'] ?? '',
      userId: json['userId'] ?? '',
      productId: json['productId'] ?? '',
      product: json['product'] != null ? ProductModel.fromJson(json['product']) : null,
      quantity: json['quantity'] ?? 1,
      amount: parseDouble(json['amount']),
      gst: parseDouble(json['gst']),
      total: parseDouble(json['total']),
      status: json['status'] ?? 'PENDING',
      paymentId: json['paymentId'],
      orderWeight: json['weight'] != null ? parseDouble(json['weight']) : null,
      referralCode: json['referralCode'],
      invoiceNo: json['invoiceNo'],
      deliveryDate: json['deliveryDate'] != null ? DateTime.parse(json['deliveryDate']) : null,
      goldPriceAtPurchase: json['goldPriceAtPurchase'] != null ? parseDouble(json['goldPriceAtPurchase']) : null,
      invoiceUrl: json['invoiceUrl'],
      customerName: json['user']?['name'],
      customerPhone: json['user']?['phone'],
      customerAddress: json['user']?['address'],
      statusHistory: json['statusHistory'] != null 
        ? (json['statusHistory'] as List).map((h) => OrderStatusHistoryModel.fromJson(h)).toList()
        : [],
      createdAt: json['createdAt'] != null ? DateTime.parse(json['createdAt']) : DateTime.now(),
    );
  }

  // UI COMPATIBILITY GETTERS
  String get productName => product?.name ?? 'Gold Coin';
  double get weight => orderWeight ?? product?.weight ?? 1.0;
  double get price => amount;
  double get gstAmount => gst;
  double get totalPrice => total;
  String get orderDate => createdAt.toIso8601String();
  String get estimatedDelivery => deliveryDate != null 
    ? DateFormat('dd/MM/yyyy').format(deliveryDate!)
    : '5-7 Business Days';
    
  String? get deliveredDate => status.toUpperCase() == 'PICKED' ? 'Picked' : null;
  double get referralCommission => 0.0;
  String get paymentMethod => 'Online (Razorpay)';
  
  bool get canCancel => 
    status.toUpperCase() == 'ORDER_PLACED' || 
    status.toUpperCase() == 'ORDER_CONFIRMED' || 
    status.toUpperCase() == 'PREPARING_ORDER' ||
    status.toUpperCase() == 'PROCESSING' ||
    status.toUpperCase() == 'QUALITY_CHECKING';

  bool get canResell => 
    status.toUpperCase() == 'READY_FOR_PICKUP' || 
    status.toUpperCase() == 'DELIVERED';
  
  bool get isActive => 
    !isCancelled && !isResold && status.toUpperCase() != 'REFUNDED' && status.toUpperCase() != 'PICKED_UP' && status.toUpperCase() != 'PICKED';
    
  bool get isDelivered => status.toUpperCase() == 'DELIVERED';
  bool get isCancelled => status.toUpperCase() == 'ORDER_CANCELLED';
  bool get isResold => status.toUpperCase() == 'SOLD_BACK' || status.toUpperCase() == 'RESOLD';

  StatusType get statusType => statusFromString(status);

  OrderModel copyWith({
    String? id,
    String? userId,
    String? productId,
    ProductModel? product,
    int? quantity,
    double? amount,
    double? gst,
    double? total,
    String? status,
    String? paymentId,
    double? orderWeight,
    String? referralCode,
    String? invoiceNo,
    DateTime? deliveryDate,
    double? goldPriceAtPurchase,
    DateTime? createdAt,
  }) {
    return OrderModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      productId: productId ?? this.productId,
      product: product ?? this.product,
      quantity: quantity ?? this.quantity,
      amount: amount ?? this.amount,
      gst: gst ?? this.gst,
      total: total ?? this.total,
      status: status ?? this.status,
      paymentId: paymentId ?? this.paymentId,
      orderWeight: orderWeight ?? this.orderWeight,
      referralCode: referralCode ?? this.referralCode,
      invoiceNo: invoiceNo ?? this.invoiceNo,
      deliveryDate: deliveryDate ?? this.deliveryDate,
      goldPriceAtPurchase: goldPriceAtPurchase ?? this.goldPriceAtPurchase,
      createdAt: createdAt ?? this.createdAt,
    );
  }

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
      'invoiceNo': invoiceNo,
      'createdAt': createdAt.toIso8601String(),
    };
  }
}
