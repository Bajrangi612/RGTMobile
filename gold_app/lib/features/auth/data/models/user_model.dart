class UserModel {
  final String id;
  final String name;
  final String phone;
  final String? email;
  final String referralCode;
  final String kycStatus;
  final String bankStatus;
  final int orderCount;
  final double totalCollectionValue;
  final bool passKeySet;
  final String createdAt;
  final bool isAdmin;
  final bool registerRequired;
  final String? address;
  final String? aadharNo;
  final String? panNo;
  final String? dob;
  final WalletModel? wallet;

  final String? bankAccountNo;
  final String? bankHolderName;
  final String? bankIfsc;
  final String? bankName;
  final String? pin;
  final String? pinUpdatedAt;


  UserModel({

    required this.id,
    required this.name,
    required this.phone,
    this.email,
    required this.referralCode,
    required this.kycStatus,
    required this.bankStatus,
    required this.orderCount,
    required this.totalCollectionValue,
    required this.passKeySet,
    required this.createdAt,
    this.isAdmin = false,
    this.registerRequired = false,
    this.address,
    this.aadharNo,
    this.panNo,
    this.dob,
    this.wallet,
    this.bankAccountNo,
    this.bankHolderName,
    this.bankIfsc,
    this.bankName,
    this.pin,
    this.pinUpdatedAt,
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
      totalCollectionValue: (json['totalCollectionValue'] ?? 0).toDouble(),
      passKeySet: json['passKeySet'] ?? false,
      createdAt: json['createdAt'] ?? '',
      isAdmin: json['isAdmin'] ?? (json['role'] == 'ADMIN'),
      registerRequired: json['registerRequired'] ?? false,
      address: json['address'],
      aadharNo: json['aadharNo'],
      panNo: json['panNo'],
      dob: json['dob']?.toString(),
      wallet: json['wallet'] != null ? WalletModel.fromJson(json['wallet']) : null,
      bankAccountNo: json['bankAccountNo'],
      bankHolderName: json['bankHolderName'],
      bankIfsc: json['bankIfsc'],
      bankName: json['bankName'],
      pin: json['pin'],
      pinUpdatedAt: json['pinUpdatedAt'],
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
        'totalCollectionValue': totalCollectionValue,
        'passKeySet': passKeySet,
        'createdAt': createdAt,
        'isAdmin': isAdmin,
        'registerRequired': registerRequired,
        'address': address,
        'aadharNo': aadharNo,
        'panNo': panNo,
        'dob': dob,
        'wallet': wallet?.toJson(),
        'bankAccountNo': bankAccountNo,
        'bankHolderName': bankHolderName,
        'bankIfsc': bankIfsc,
        'bankName': bankName,
        'pin': pin,
        'pinUpdatedAt': pinUpdatedAt,
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
    double? totalCollectionValue,
    bool? passKeySet,
    String? createdAt,
    bool? isAdmin,
    bool? registerRequired,
    String? address,
    String? aadharNo,
    String? panNo,
    String? dob,
    WalletModel? wallet,
    String? bankAccountNo,
    String? bankHolderName,
    String? bankIfsc,
    String? bankName,
    String? pin,
    String? pinUpdatedAt,
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
      totalCollectionValue: totalCollectionValue ?? this.totalCollectionValue,
      passKeySet: passKeySet ?? this.passKeySet,
      createdAt: createdAt ?? this.createdAt,
      isAdmin: isAdmin ?? this.isAdmin,
      registerRequired: registerRequired ?? this.registerRequired,
      address: address ?? this.address,
      aadharNo: aadharNo ?? this.aadharNo,
      panNo: panNo ?? this.panNo,
      dob: dob ?? this.dob,
      wallet: wallet ?? this.wallet,
      bankAccountNo: bankAccountNo ?? this.bankAccountNo,
      bankHolderName: bankHolderName ?? this.bankHolderName,
      bankIfsc: bankIfsc ?? this.bankIfsc,
      bankName: bankName ?? this.bankName,
      pin: pin ?? this.pin,
      pinUpdatedAt: pinUpdatedAt ?? this.pinUpdatedAt,
    );


  }

  bool get isKycVerified => kycStatus == 'verified';
  bool get isBankVerified => bankStatus == 'verified';
  bool get isFullyVerified => isKycVerified && isBankVerified;

  bool get isProfileComplete => true; // Made optional as per user request

}

class WalletModel {
  final double balance;

  WalletModel({
    required this.balance,
  });

  factory WalletModel.fromJson(Map<String, dynamic> json) {
    return WalletModel(
      balance: _toDouble(json['balance']),
    );
  }

  Map<String, dynamic> toJson() => {
        'balance': balance,
      };

  static double _toDouble(dynamic value) {
    if (value is num) return value.toDouble();
    return double.tryParse(value?.toString() ?? '0') ?? 0.0;
  }
}
