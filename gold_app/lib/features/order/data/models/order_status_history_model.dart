import 'package:gold_app/core/utils/formatters.dart';

class OrderStatusHistoryModel {
  final String id;
  final String status;
  final String? notes;
  final DateTime createdAt;

  OrderStatusHistoryModel({
    required this.id,
    required this.status,
    this.notes,
    required this.createdAt,
  });

  factory OrderStatusHistoryModel.fromJson(Map<String, dynamic> json) {
    return OrderStatusHistoryModel(
      id: json['id'] ?? '',
      status: json['status'] ?? '',
      notes: json['notes'],
      createdAt: json['createdAt'] != null 
        ? DateTime.parse(json['createdAt']) 
        : Formatters.nowIST,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'status': status,
      'notes': notes,
      'createdAt': createdAt.toIso8601String(),
    };
  }
}
