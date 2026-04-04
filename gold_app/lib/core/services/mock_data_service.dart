import 'dart:math';
import '../constants/app_constants.dart';

class MockDataService {
  static final _random = Random();

  // Simulate API delay
  static Future<void> simulateDelay([int? ms]) async {
    await Future.delayed(
      Duration(milliseconds: ms ?? AppConstants.apiDelayMedium),
    );
  }

  // Generate mock JWT token
  static String generateToken() {
    return 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.mock_${DateTime.now().millisecondsSinceEpoch}';
  }

  // Generate referral code
  static String generateReferralCode() {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    return 'RG${List.generate(6, (_) => chars[_random.nextInt(chars.length)]).join()}';
  }

  // Generate order ID
  static String generateOrderId() {
    return 'ORD${DateTime.now().millisecondsSinceEpoch.toString().substring(5)}';
  }

  // Mock gold price (per gram)
  static double getGoldPrice() {
    // Base price around ₹7,200/gram with small fluctuation
    return 7200.0 + (_random.nextDouble() * 200 - 100);
  }

  // Mock gold price change percentage
  static double getGoldPriceChange() {
    return (_random.nextDouble() * 4 - 2); // -2% to +2%
  }

  // Mock product list
  static List<Map<String, dynamic>> getProducts() {
    final basePrice = getGoldPrice();
    return [
      {
        'id': 'prod_1g',
        'name': '1 Gram Gold Coin',
        'weight': 1.0,
        'weightUnit': 'gram',
        'purity': '24K',
        'fineness': '999.9',
        'price': (basePrice * 1).roundToDouble(),
        'oldPrice': (basePrice * 1 * 1.05).roundToDouble(),
        'images': [
          'assets/images/gold_coin_1g.png',
        ],
        'description': 'Pure 24K gold coin, BIS hallmarked. Perfect for daily investment.',
        'inStock': true,
      },
      {
        'id': 'prod_2g',
        'name': '2 Gram Gold Coin',
        'weight': 2.0,
        'weightUnit': 'gram',
        'purity': '24K',
        'fineness': '999.9',
        'price': (basePrice * 2).roundToDouble(),
        'oldPrice': (basePrice * 2 * 1.05).roundToDouble(),
        'images': [
          'assets/images/gold_coin_1g.png',
        ],
        'description': 'Pure 24K gold coin, BIS hallmarked. Great value for regular investors.',
        'inStock': true,
      },
      {
        'id': 'prod_5g',
        'name': '5 Gram Gold Coin',
        'weight': 5.0,
        'weightUnit': 'gram',
        'purity': '24K',
        'fineness': '999.9',
        'price': (basePrice * 5).roundToDouble(),
        'oldPrice': (basePrice * 5 * 1.05).roundToDouble(),
        'images': [
          'assets/images/gold_coin_5g.png',
        ],
        'description': 'Pure 24K gold coin, BIS hallmarked. Popular choice for serious investors.',
        'inStock': true,
      },
      {
        'id': 'prod_10g',
        'name': '10 Gram Gold Coin',
        'weight': 10.0,
        'weightUnit': 'gram',
        'purity': '24K',
        'fineness': '999.9',
        'price': (basePrice * 10).roundToDouble(),
        'oldPrice': (basePrice * 10 * 1.05).roundToDouble(),
        'images': [
          'assets/images/gold_coin_5g.png',
        ],
        'description': 'Pure 24K gold coin, BIS hallmarked. Premium investment choice.',
        'inStock': true,
      },
      {
        'id': 'prod_20g',
        'name': '20 Gram Gold Coin',
        'weight': 20.0,
        'weightUnit': 'gram',
        'purity': '24K',
        'fineness': '999.9',
        'price': (basePrice * 20).roundToDouble(),
        'oldPrice': (basePrice * 20 * 1.05).roundToDouble(),
        'images': [
          'assets/images/gold_coin_20g.png',
        ],
        'description': 'Pure 24K gold coin, BIS hallmarked. Exceptional value for high-volume investors.',
        'inStock': true,
      },
      {
        'id': 'prod_50g',
        'name': '50 Gram Gold Coin',
        'weight': 50.0,
        'weightUnit': 'gram',
        'purity': '24K',
        'fineness': '999.9',
        'price': (basePrice * 50).roundToDouble(),
        'oldPrice': (basePrice * 50 * 1.05).roundToDouble(),
        'images': [
          'assets/images/gold_coin_50g.png',
        ],
        'description': 'Pure 24K gold coin, BIS hallmarked. The ultimate store of wealth and premium asset.',
        'inStock': true,
      },
      {
        'id': 'prod_lakshmi_ganesh_10g',
        'name': '10g Lakshmi Ganesh Gold Coin',
        'weight': 10.0,
        'weightUnit': 'gram',
        'purity': '24K',
        'fineness': '999.9',
        'price': (basePrice * 10).roundToDouble(),
        'oldPrice': (basePrice * 10 * 1.05).roundToDouble(),
        'images': [
          'assets/images/gold_coin_lakshmi_ganesh.png',
        ],
        'description': 'Pure 24K gold coin featuring Goddess Lakshmi and Lord Ganesha. Perfect for auspicious occasions and gifting.',
        'inStock': true,
      },
      {
        'id': 'prod_kuber_10g',
        'name': '10g Lord Kuber Gold Coin',
        'weight': 10.0,
        'weightUnit': 'gram',
        'purity': '24K',
        'fineness': '999.9',
        'price': (basePrice * 10).roundToDouble(),
        'oldPrice': (basePrice * 10 * 1.05).roundToDouble(),
        'images': [
          'assets/images/gold_coin_kuber.png',
        ],
        'description': 'Pure 24K gold coin featuring Lord Kuber, the god of wealth. Bring prosperity into your life with this premium investment.',
        'inStock': true,
      },
      {
        'id': 'prod_durga_5g',
        'name': '5g Durga Maa Gold Coin',
        'weight': 5.0,
        'weightUnit': 'gram',
        'purity': '24K',
        'fineness': '999.9',
        'price': (basePrice * 5).roundToDouble(),
        'oldPrice': (basePrice * 5 * 1.05).roundToDouble(),
        'image': 'assets/images/gold_coin_durga.png',
        'description': 'Pure 24K gold coin featuring Goddess Durga riding a lion. A symbol of strength and protection.',
        'inStock': true,
      },
      {
        'id': 'prod_bar_100g',
        'name': '100g Pure Gold Bar',
        'weight': 100.0,
        'weightUnit': 'gram',
        'purity': '24K',
        'fineness': '999.9',
        'price': (basePrice * 100).roundToDouble(),
        'oldPrice': (basePrice * 100 * 1.05).roundToDouble(),
        'image': 'assets/images/gold_coin_100g.png',
        'description': 'Pure 24K 100g Gold Bar / Biscuit. Unmatched wealth preservation and liquidity for heavyweight investors.',
        'inStock': true,
      },
      {
        'id': 'prod_radhe_krishna_5g',
        'name': '5g Radhe Krishna Gold Coin',
        'weight': 5.0,
        'weightUnit': 'gram',
        'purity': '24K',
        'fineness': '999.9',
        'price': (basePrice * 5).roundToDouble(),
        'oldPrice': (basePrice * 5 * 1.05).roundToDouble(),
        'image': 'assets/images/gold_coin_radhe_krishna.png',
        'description': 'Pure 24K gold coin featuring the divine pair of Radha and Krishna. Perfect for gifting on anniversaries or festivals.',
        'inStock': true,
      },
      {
        'id': 'prod_wedding_10g',
        'name': '10g Shubh Vivah Gold Coin',
        'weight': 10.0,
        'weightUnit': 'gram',
        'purity': '24K',
        'fineness': '999.9',
        'price': (basePrice * 10).roundToDouble(),
        'oldPrice': (basePrice * 10 * 1.05).roundToDouble(),
        'image': 'assets/images/gold_coin_wedding.png',
        'description': 'Pure 24K "Shubh Vivah" Wedding gold coin. An elegant and traditional blessing for newlywed couples.',
        'inStock': true,
      },
      {
        'id': 'prod_sovereign_8g',
        'name': '8g Sovereign Gold Coin',
        'weight': 8.0,
        'weightUnit': 'gram',
        'purity': '22K',
        'fineness': '916.0',
        'price': (basePrice * 8 * 0.916).roundToDouble(),
        'oldPrice': (basePrice * 8 * 0.916 * 1.05).roundToDouble(),
        'image': 'assets/images/gold_coin_sovereign.png',
        'description': 'Classic 22K Sovereign gold coin. A regal asset combining historical prestige with solid investment value.',
        'inStock': true,
      },
    ];
  }

  // Mock user data
  static Map<String, dynamic> getUserData() {
    return {
      'id': 'user_001',
      'name': 'Rahul Sharma',
      'phone': '+91 98765 43210',
      'email': 'rahul.sharma@email.com',
      'referralCode': 'RGXK7M2N',
      'kycStatus': 'verified', // pending, verified, rejected
      'bankStatus': 'verified', // pending, verified, rejected
      'orderCount': 2,
      'totalInvestment': 45600.0,
      'passKeySet': true,
      'createdAt': '2025-01-15T10:30:00Z',
    };
  }

  // Mock orders
  static List<Map<String, dynamic>> getOrders() {
    return [
      {
        'id': 'ORD89234561',
        'productId': 'prod_5g',
        'productName': '5 Gram Gold Coin',
        'weight': 5.0,
        'customerName': 'Rahul Sharma',
        'total': 37080.0, // Incl. 3% GST
        'price': 36000.0,
        'status': 'processing', 
        'date': '2025-03-30',
        'orderDate': DateTime.now().subtract(Duration(days: 2)).toIso8601String(),
        'estimatedDelivery': DateTime.now().add(Duration(days: 5)).toIso8601String(),
        'referralCode': 'RGXK7M2N',
        'referralCommission': 500.0,
        'paymentMethod': 'UPI',
        'canCancel': true,
        'canResell': true,
      },
      {
        'id': 'ORD89234102',
        'productId': 'prod_2g',
        'productName': '2 Gram Gold Coin',
        'weight': 2.0,
        'customerName': 'Priya Patel',
        'total': 14832.0,
        'price': 14400.0,
        'status': 'delivered',
        'date': '2025-03-15',
        'orderDate': DateTime.now().subtract(Duration(days: 15)).toIso8601String(),
        'estimatedDelivery': DateTime.now().subtract(Duration(days: 8)).toIso8601String(),
        'deliveredDate': DateTime.now().subtract(Duration(days: 9)).toIso8601String(),
        'referralCode': null,
        'referralCommission': 0.0,
        'paymentMethod': 'Bank Transfer',
        'canCancel': false,
        'canResell': false,
      },
      {
        'id': 'ORD89234999',
        'productId': 'prod_10g',
        'productName': '10 Gram Gold Coin',
        'weight': 10.0,
        'customerName': 'Sneha Reddy',
        'total': 74160.0,
        'price': 72000.0,
        'status': 'pending', 
        'date': '2025-04-01',
        'orderDate': DateTime.now().toIso8601String(),
        'estimatedDelivery': DateTime.now().add(const Duration(days: 7)).toIso8601String(),
        'paymentMethod': 'UPI',
        'canCancel': true,
        'canResell': false,
      },
      {
        'id': 'ORD89234888',
        'productId': 'prod_1g',
        'productName': '1 Gram Gold Coin',
        'weight': 1.0,
        'customerName': 'Vikram Singh',
        'total': 7416.0,
        'price': 7200.0,
        'status': 'shipped', 
        'date': '2025-03-29',
        'orderDate': DateTime.now().subtract(const Duration(days: 3)).toIso8601String(),
        'estimatedDelivery': DateTime.now().add(const Duration(days: 2)).toIso8601String(),
        'paymentMethod': 'Bank Transfer',
        'canCancel': false,
        'canResell': false,
      },
    ];
  }

  // Mock transactions
  static List<Map<String, dynamic>> getTransactions() {
    return [
      {
        'id': 'txn_001',
        'type': 'purchase',
        'description': '5 Gram Gold Coin Purchase',
        'amount': -36000.0,
        'date': DateTime.now().subtract(Duration(days: 2)).toIso8601String(),
        'status': 'completed',
      },
      {
        'id': 'txn_002',
        'type': 'referral',
        'description': 'Referral Commission - ORD89234561',
        'amount': 500.0,
        'date': DateTime.now().subtract(Duration(days: 2)).toIso8601String(),
        'status': 'completed',
      },
      {
        'id': 'txn_003',
        'type': 'purchase',
        'description': '2 Gram Gold Coin Purchase',
        'amount': -14400.0,
        'date': DateTime.now().subtract(Duration(days: 15)).toIso8601String(),
        'status': 'completed',
      },
      {
        'id': 'txn_004',
        'type': 'resell',
        'description': 'Gold Coin Resell - 1g',
        'amount': 7350.0,
        'date': DateTime.now().subtract(Duration(days: 30)).toIso8601String(),
        'status': 'completed',
      },
    ];
  }

  // NEW: Mock users for Admin
  static List<Map<String, dynamic>> getAllUsers() {
    return [
      {
        'id': 'user_001',
        'name': 'Rahul Sharma',
        'phone': '+91 98765 43210',
        'email': 'rahul.sharma@email.com',
        'kycStatus': 'verified',
        'status': 'active',
        'joinedDate': '2025-01-15',
      },
      {
        'id': 'user_002',
        'name': 'Priya Patel',
        'phone': '+91 87654 32109',
        'email': 'priya.patel@email.com',
        'kycStatus': 'pending',
        'status': 'active',
        'joinedDate': '2025-02-10',
      },
      {
        'id': 'user_003',
        'name': 'Amit Kumar',
        'phone': '+91 76543 21098',
        'email': 'amit.kumar@email.com',
        'kycStatus': 'rejected',
        'status': 'blocked',
        'joinedDate': '2025-03-05',
      },
      {
        'id': 'user_004',
        'name': 'Sneha Reddy',
        'phone': '+91 91234 56789',
        'email': 'sneha.reddy@email.com',
        'kycStatus': 'verified',
        'status': 'active',
        'joinedDate': '2025-03-12',
      },
      {
        'id': 'user_005',
        'name': 'Vikram Singh',
        'phone': '+91 99887 76655',
        'email': 'vikram.singh@email.com',
        'kycStatus': 'pending',
        'status': 'active',
        'joinedDate': '2025-03-25',
      },
      {
        'id': 'user_006',
        'name': 'Anjali Gupta',
        'phone': '+91 88776 65544',
        'email': 'anjali.gupta@email.com',
        'kycStatus': 'verified',
        'status': 'active',
        'joinedDate': '2025-03-28',
      },
    ];
  }

  // NEW: System Configurations
  static Map<String, dynamic> getSystemConfigs() {
    return {
      'commissionRate': 2.5,
      'deliveryTimeDays': 5,
      'orderIntervalMinutes': 15,
      'gstRate': 3.0,
    };
  }
}
