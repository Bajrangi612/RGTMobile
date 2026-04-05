import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

class StorageService {
  static const _storage = FlutterSecureStorage();

  // Write
  static Future<void> write(String key, String value) async {
    if (kIsWeb) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(key, value);
      return;
    }
    
    try {
      await _storage.write(key: key, value: value)
          .timeout(const Duration(milliseconds: 500));
    } catch (_) {}
  }

  // Read
  static Future<String?> read(String key) async {
    if (kIsWeb) {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(key);
    }

    try {
      return await _storage.read(key: key)
          .timeout(const Duration(milliseconds: 500));
    } catch (_) {
      return null;
    }
  }

  // Delete
  static Future<void> delete(String key) async {
    if (kIsWeb) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(key);
      return;
    }

    try {
      await _storage.delete(key: key)
          .timeout(const Duration(milliseconds: 500));
    } catch (_) {}
  }

  // Delete all
  static Future<void> clearAll() async {
    if (kIsWeb) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();
      return;
    }

    try {
      await _storage.deleteAll()
          .timeout(const Duration(milliseconds: 500));
    } catch (_) {}
  }

  // Check if key exists
  static Future<bool> containsKey(String key) async {
    if (kIsWeb) {
      final prefs = await SharedPreferences.getInstance();
      return prefs.containsKey(key);
    }

    try {
      return await _storage.containsKey(key: key)
          .timeout(const Duration(milliseconds: 500));
    } catch (_) {
      return false;
    }
  }
}
