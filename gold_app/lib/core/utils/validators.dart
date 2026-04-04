class Validators {
  Validators._();

  // Phone number (10 digits)
  static String? phone(String? value) {
    if (value == null || value.isEmpty) return 'Phone number is required';
    final cleaned = value.replaceAll(RegExp(r'[^0-9]'), '');
    if (cleaned.length != 10) return 'Enter valid 10-digit phone number';
    return null;
  }

  // OTP (6 digits)
  static String? otp(String? value) {
    if (value == null || value.isEmpty) return 'OTP is required';
    if (value.length != 6) return 'Enter 6-digit OTP';
    if (!RegExp(r'^[0-9]{6}$').hasMatch(value)) return 'Invalid OTP';
    return null;
  }

  // Aadhaar (12 digits)
  static String? aadhaar(String? value) {
    if (value == null || value.isEmpty) return 'Aadhaar number is required';
    final cleaned = value.replaceAll(RegExp(r'[^0-9]'), '');
    if (cleaned.length != 12) return 'Enter valid 12-digit Aadhaar number';
    return null;
  }

  // Bank account number
  static String? accountNumber(String? value) {
    if (value == null || value.isEmpty) return 'Account number is required';
    if (value.length < 9 || value.length > 18) {
      return 'Enter valid account number (9-18 digits)';
    }
    if (!RegExp(r'^[0-9]+$').hasMatch(value)) return 'Only digits allowed';
    return null;
  }

  // Confirm account number
  static String? confirmAccountNumber(String? value, String original) {
    final error = accountNumber(value);
    if (error != null) return error;
    if (value != original) return 'Account numbers do not match';
    return null;
  }

  // IFSC Code
  static String? ifsc(String? value) {
    if (value == null || value.isEmpty) return 'IFSC code is required';
    if (!RegExp(r'^[A-Z]{4}0[A-Z0-9]{6}$').hasMatch(value.toUpperCase())) {
      return 'Enter valid IFSC code (e.g., SBIN0001234)';
    }
    return null;
  }

  // Name
  static String? name(String? value) {
    if (value == null || value.trim().isEmpty) return 'Name is required';
    if (value.trim().length < 2) return 'Name must be at least 2 characters';
    if (!RegExp(r'^[a-zA-Z\s]+$').hasMatch(value)) {
      return 'Name can only contain letters';
    }
    return null;
  }

  // Referral code (optional)
  static String? referralCode(String? value) {
    if (value == null || value.isEmpty) return null; // Optional
    if (value.length < 6) return 'Invalid referral code';
    return null;
  }

  // Passkey (4 digits)
  static String? passKey(String? value) {
    if (value == null || value.isEmpty) return 'Passkey is required';
    if (value.length != 4) return 'Enter 4-digit passkey';
    if (!RegExp(r'^[0-9]{4}$').hasMatch(value)) return 'Only digits allowed';
    return null;
  }
}
