class KycModel {
  final String aadhaarNumber;
  final String status; // pending, verified, rejected
  final String? name;
  final DateTime? submittedAt;
  final DateTime? verifiedAt;

  KycModel({
    required this.aadhaarNumber,
    required this.status,
    this.name,
    this.submittedAt,
    this.verifiedAt,
  });

  factory KycModel.fromJson(Map<String, dynamic> json) {
    return KycModel(
      aadhaarNumber: json['aadharNo'] ?? '',
      status: (json['kycStatus'] as String?)?.toLowerCase() ?? 'pending',
      name: json['name'],
      submittedAt: json['createdAt'] != null ? DateTime.parse(json['createdAt']) : null,
      verifiedAt: null, // Verified at will be updated by Admin
    );
  }

  bool get isVerified => status == 'verified';
  bool get isPending => status == 'pending';
}

class BankModel {
  final String accountNumber;
  final String ifscCode;
  final String accountHolderName;
  final String? bankName;
  final String status;
  final DateTime? submittedAt;

  BankModel({
    required this.accountNumber,
    required this.ifscCode,
    required this.accountHolderName,
    this.bankName,
    required this.status,
    this.submittedAt,
  });

  factory BankModel.fromJson(Map<String, dynamic> json) {
    return BankModel(
      accountNumber: json['accountNumber'] ?? '',
      ifscCode: json['ifscCode'] ?? '',
      accountHolderName: json['accountHolderName'] ?? '',
      bankName: json['bankName'],
      status: json['status'] ?? 'pending',
      submittedAt: json['submittedAt'] != null ? DateTime.parse(json['submittedAt']) : null,
    );
  }

  bool get isVerified => status == 'verified';
}
