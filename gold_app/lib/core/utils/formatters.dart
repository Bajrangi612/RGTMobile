import 'package:intl/intl.dart';

class Formatters {
  Formatters._();

  // Currency formatter (₹1,23,456.00)
  static String currency(double amount) {
    final formatter = NumberFormat.currency(
      locale: 'en_IN',
      symbol: '₹',
      decimalDigits: 0,
    );
    return formatter.format(amount);
  }

  // Currency with decimals (₹1,23,456.50)
  static String currencyPrecise(double amount) {
    final formatter = NumberFormat.currency(
      locale: 'en_IN',
      symbol: '₹',
      decimalDigits: 2,
    );
    return formatter.format(amount);
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

  // Date (15 Jan 2025)
  static String date(String isoDate) {
    final dt = DateTime.parse(isoDate);
    return DateFormat('dd MMM yyyy').format(dt);
  }

  // Date time (15 Jan 2025, 10:30 AM)
  static String dateTime(String isoDate) {
    final dt = DateTime.parse(isoDate);
    return DateFormat('dd MMM yyyy, hh:mm a').format(dt);
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
    return DateFormat('dd MMM').format(dt);
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
  static String deliveryCountdown(String deliveryDate) {
    final dt = DateTime.parse(deliveryDate);
    final diff = dt.difference(DateTime.now());
    if (diff.isNegative) return 'Delivered';
    if (diff.inDays == 0) return 'Today';
    if (diff.inDays == 1) return '1 day';
    return '${diff.inDays} days';
  }
}
