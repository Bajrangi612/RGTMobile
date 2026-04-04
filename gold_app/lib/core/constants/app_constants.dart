class AppConstants {
  AppConstants._();

  // App Info
  static const String appName = 'Royal Gold';
  static const String appTagline = 'Premium Gold Trading';
  static const String appVersion = '1.0.0';

  // Business Rules
  static const int orderCooldownMinutes = 15;
  static const double referralCommission = 500.0;
  static const int deliveryDaysMin = 5;
  static const int deliveryDaysMax = 7;
  static const int maxActiveOrders = 1;
  static const int passKeyLength = 4;
  static const int otpLength = 6;
  static const int otpResendSeconds = 30;
  static const double gstRate = 0.03; // 3% GST
  static const double amlThreshold = 200000.0; // ₹2 Lakh AML verification threshold
  static const int minOrderIntervalMinutesSize = 15;

  // Gold Purity
  static const String goldPurity = '24K';
  static const String goldFineness = '999.9';
  static const String goldCertification = 'BIS Hallmarked';

  // Currency
  static const String currency = '₹';
  static const String currencyCode = 'INR';

  // Mock API Delays (milliseconds)
  static const int apiDelayShort = 400;
  static const int apiDelayMedium = 800;
  static const int apiDelayLong = 1200;

  // Storage Keys
  static const String tokenKey = 'auth_token';
  static const String refreshTokenKey = 'refresh_token';
  static const String userIdKey = 'user_id';
  static const String passKeyKey = 'pass_key';
  static const String onboardingKey = 'onboarding_complete';
  static const String lastOrderTimeKey = 'last_order_time';
}
