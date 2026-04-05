class UserModel {
  final String id;
  final String name;
  final String phone;
  final String? email;
  final String referralCode;
  final String kycStatus;
  final String bankStatus;
  final int orderCount;
  final double totalInvestment;
  final bool passKeySet;
  final String createdAt;
  final bool isAdmin;
  final bool registerRequired;
  final WalletModel? wallet;

  UserModel({
    required this.id,
    required this.name,
    required this.phone,
    this.email,
    required this.referralCode,
    required this.kycStatus,
    required this.bankStatus,
    required this.orderCount,
    required this.totalInvestment,
    required this.passKeySet,
    required this.createdAt,
    this.isAdmin = false,
    this.registerRequired = false,
    this.wallet,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      phone: json['phone'] ?? '',
      email: json['email'],
      referralCode: json['referralCode'] ?? '',
      kycStatus: json['kycStatus'] ?? 'pending',
      bankStatus: json['bankStatus'] ?? 'pending',
      orderCount: json['orderCount'] ?? 0,
      totalInvestment: (json['totalInvestment'] ?? 0).toDouble(),
      passKeySet: json['passKeySet'] ?? false,
      createdAt: json['createdAt'] ?? '',
      isAdmin: json['isAdmin'] ?? false,
      registerRequired: json['registerRequired'] ?? false,
      wallet: json['wallet'] != null ? WalletModel.fromJson(json['wallet']) : null,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'phone': phone,
        'email': email,
        'referralCode': referralCode,
        'kycStatus': kycStatus,
        'bankStatus': bankStatus,
        'orderCount': orderCount,
        'totalInvestment': totalInvestment,
        'passKeySet': passKeySet,
        'createdAt': createdAt,
        'isAdmin': isAdmin,
        'registerRequired': registerRequired,
        'wallet': wallet?.toJson(),
      };

  UserModel copyWith({
    String? id,
    String? name,
    String? phone,
    String? email,
    String? referralCode,
    String? kycStatus,
    String? bankStatus,
    int? orderCount,
    double? totalInvestment,
    bool? passKeySet,
    String? createdAt,
    bool? isAdmin,
    bool? registerRequired,
    WalletModel? wallet,
  }) {
    return UserModel(
      id: id ?? this.id,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      referralCode: referralCode ?? this.referralCode,
      kycStatus: kycStatus ?? this.kycStatus,
      bankStatus: bankStatus ?? this.bankStatus,
      orderCount: orderCount ?? this.orderCount,
      totalInvestment: totalInvestment ?? this.totalInvestment,
      passKeySet: passKeySet ?? this.passKeySet,
      createdAt: createdAt ?? this.createdAt,
      isAdmin: isAdmin ?? this.isAdmin,
      registerRequired: registerRequired ?? this.registerRequired,
      wallet: wallet ?? this.wallet,
    );
  }

  bool get isKycVerified => kycStatus == 'verified';
  bool get isBankVerified => bankStatus == 'verified';
  bool get isFullyVerified => isKycVerified && isBankVerified;
}

class WalletModel {
  final double balance;
  final double goldAdvance;
  final double referralRewards;

  WalletModel({
    required this.balance,
    required this.goldAdvance,
    required this.referralRewards,
  });

  factory WalletModel.fromJson(Map<String, dynamic> json) {
    return WalletModel(
      balance: _toDouble(json['balance']),
      goldAdvance: _toDouble(json['goldAdvance']),
      referralRewards: _toDouble(json['referralRewards']),
    );
  }

  Map<String, dynamic> toJson() => {
        'balance': balance,
        'goldAdvance': goldAdvance,
        'referralRewards': referralRewards,
      };

  static double _toDouble(dynamic value) {
    if (value is num) return value.toDouble();
    return double.tryParse(value?.toString() ?? '0') ?? 0.0;
  }
}
