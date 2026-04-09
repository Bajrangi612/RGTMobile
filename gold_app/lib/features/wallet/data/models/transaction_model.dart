class TransactionModel {
  final String id;
  final String userId;
  final String type; // 'PURCHASE', 'REFERRAL', 'resell', 'refund', 'WITHDRAWAL'
  final double amount;
  final String status;
  final String description;
  final String? invoiceNo;
  final DateTime date;

  TransactionModel({
    required this.id,
    required this.userId,
    required this.type,
    required this.amount,
    required this.status,
    required this.description,
    this.invoiceNo,
    required this.date,
  });

  factory TransactionModel.fromJson(Map<String, dynamic> json) {
    return TransactionModel(
      id: json['id'] ?? '',
      userId: json['userId'] ?? '',
      type: (json['type'] ?? '').toString().toLowerCase(),
      amount: double.tryParse(json['amount'].toString()) ?? 0.0,
      status: json['status'] ?? 'COMPLETED',
      description: json['description'] ?? '',
      invoiceNo: json['invoiceNo'],
      date: DateTime.parse(json['createdAt'] ?? DateTime.now().toIso8601String()),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'type': type.toUpperCase(),
      'amount': amount,
      'status': status,
      'description': description,
      'invoiceNo': invoiceNo,
      'createdAt': date.toIso8601String(),
    };
  }
}
