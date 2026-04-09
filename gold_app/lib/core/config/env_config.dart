import 'package:flutter/foundation.dart';

class EnvConfig {
  EnvConfig._();

  /// Default to localhost for development if no --dart-define is provided
  static const String _defaultUrl = 'http://localhost:4000/api';
  
  /// Official production URL
  static const String _prodUrl = 'http://o1qp4x36ni2pggogwxgzntcz.91.108.111.194.sslip.io/api';

  static String get baseUrl {
    // Check if a URL was passed via --dart-define=API_URL=...
    const String definedUrl = String.fromEnvironment('API_URL');
    if (definedUrl.isNotEmpty) return definedUrl;

    // Fallback to kReleaseMode check
    if (kReleaseMode) {
      return _prodUrl;
    }

    return _defaultUrl;
  }

  static bool get isProduction => kReleaseMode;
}
