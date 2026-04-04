import '../../../core/network/api_service.dart';
import '../../../core/services/storage_service.dart';
import '../../../core/constants/app_constants.dart';
import 'models/user_model.dart';

class AuthRepository {
  // Send OTP
  Future<String?> sendOtp(String phone) async {
    try {
      print('🚀 Sending OTP to: $phone');
      final response = await ApiService().post('/auth/send-otp', data: {'mobile': phone});
      print('✅ OTP Response: ${response.statusCode} - ${response.data}');
      if (response.statusCode == 200) {
        final data = response.data['data'];
        return data['mockCode']?.toString();
      }
      return null;
    } catch (e) {
      print('❌ OTP Error: $e');
      return null;
    }
  }

  // Verify OTP
  Future<UserModel?> verifyOtp(String phone, String otp) async {
    try {
      final response = await ApiService().post('/auth/verify-otp', data: {
        'mobile': phone,
        'otp': otp,
      });

      if (response.statusCode == 200) {
        final data = response.data['data'];
        final token = data['token'];
        final userData = data['user'];

        if (token != null) {
          await StorageService.write(AppConstants.tokenKey, token);
        }

        // Map backend fields to Flutter UserModel
        final Map<String, dynamic> mappedUser = {
          ...Map<String, dynamic>.from(userData),
          'phone': userData['contactNo'] ?? phone,
          'totalInvestment': (userData['goldAdvanceAmount'] ?? 0.0).toDouble(),
          'kycStatus': 'verified', // Placeholder, update as per backend schema
          'bankStatus': 'verified',
          'isAdmin': userData['role'] == 'ADMIN',
          'registerRequired': data['registerRequired'] ?? false,
        };

        return UserModel.fromJson(mappedUser);
      }
    } catch (e) {
      return null;
    }
    return null;
  }

  // Check if logged in
  Future<bool> isLoggedIn() async {
    final token = await StorageService.read(AppConstants.tokenKey);
    return token != null && token.isNotEmpty;
  }

  // Get current user
  Future<UserModel> getCurrentUser() async {
    try {
      // In a real app, we might need a specific /me endpoint or similar
      // For now, we use a placeholder or assume the token handles it
      final response = await ApiService().get('/auth/lookup-referrer?mobile=9999999999'); // Placeholder
      return UserModel.fromJson(response.data);
    } catch (e) {
      // Return empty user on error
      return UserModel(
        id: '', name: '', phone: '', referralCode: '', kycStatus: '', 
        bankStatus: '', orderCount: 0, totalInvestment: 0, 
        passKeySet: false, createdAt: ''
      );
    }
  }

  // Logout
  Future<void> logout() async {
    await StorageService.clearAll();
  }
}
