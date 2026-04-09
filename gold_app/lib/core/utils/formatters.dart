import 'package:intl/intl.dart';

class Formatters {
  Formatters._();

  // Currency formatter (₹1,23,456.00)
  static String currency(dynamic amount) {
    final double value = _toDouble(amount);
    final formatter = NumberFormat.currency(
      locale: 'en_IN',
      symbol: '₹',
      decimalDigits: 0,
    );
    return formatter.format(value);
  }

  // Currency with decimals (₹1,23,456.50)
  static String currencyPrecise(dynamic amount) {
    final double value = _toDouble(amount);
    final formatter = NumberFormat.currency(
      locale: 'en_IN',
      symbol: '₹',
      decimalDigits: 2,
    );
    return formatter.format(value);
  }

  static double _toDouble(dynamic value) {
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0.0;
    return 0.0;
  }

  // Price per gram (₹7,200/g)
  static String pricePerGram(double price) {
    return '${currency(price)}/g';
  }

  // Weight (5.0g)
  static String weight(double grams) {
    if (grams == grams.roundToDouble()) {
      return '${grams.toInt()}g';
    }
    return '${grams}g';
  }

  // Date (15/01/2025) 
  static String date(String isoDate) {
    try {
      final dt = DateTime.parse(isoDate);
      return DateFormat('dd/MM/yyyy').format(dt);
    } catch (e) {
      return isoDate;
    }
  }

  // Date time (15/01/2025, 10:30 AM)
  static String dateTime(String isoDate) {
    try {
      final dt = DateTime.parse(isoDate);
      return DateFormat('dd/MM/yyyy, hh:mm a').format(dt);
    } catch (e) {
      return isoDate;
    }
  }

  // Relative time (2 days ago, just now)
  static String relativeTime(String isoDate) {
    final dt = DateTime.parse(isoDate);
    final diff = DateTime.now().difference(dt);

    if (diff.inSeconds < 60) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    if (diff.inDays < 30) return '${(diff.inDays / 7).floor()}w ago';
    return DateFormat('dd/MM').format(dt);
  }

  // Percentage (+2.3%, -1.5%)
  static String percentage(double value) {
    final prefix = value >= 0 ? '+' : '';
    return '$prefix${value.toStringAsFixed(2)}%';
  }

  // Phone masking (****3210)
  static String maskedPhone(String phone) {
    if (phone.length < 4) return phone;
    final last4 = phone.substring(phone.length - 4);
    return '****$last4';
  }

  // Aadhaar masking (XXXX XXXX 1234)
  static String maskedAadhaar(String aadhaar) {
    if (aadhaar.length < 4) return aadhaar;
    final last4 = aadhaar.substring(aadhaar.length - 4);
    return 'XXXX XXXX $last4';
  }

  // Countdown days
  static String deliveryCountdown(dynamic deliveryDate) {
    if (deliveryDate == null) return 'Pending';
    
    DateTime? dt;
    if (deliveryDate is DateTime) {
      dt = deliveryDate;
    } else if (deliveryDate is String) {
      dt = DateTime.tryParse(deliveryDate);
    }
    
    if (dt == null) return 'Pending';
    
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final delivery = DateTime(dt.year, dt.month, dt.day);
    final diff = delivery.difference(today).inDays;

    if (diff < 0) return 'Arrived';
    if (diff == 0) return 'Today';
    if (diff == 1) return 'Tomorrow';
    return '$diff days left';
  }
}
