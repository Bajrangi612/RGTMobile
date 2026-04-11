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
        // In production, mockCode will be null/absent. 
        // We should return a non-null string to indicate success.
        return data['mockCode']?.toString() ?? 'SUCCESS';
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
          'totalCollectionValue': (userData['goldAdvanceAmount'] ?? 0.0).toDouble(),
          'orderCount': userData['orderCount'] ?? 0,
          'kycStatus': (userData['kycStatus'] ?? 'PENDING').toString().toLowerCase(),
          'bankStatus': (userData['bankStatus'] ?? 'PENDING').toString().toLowerCase(),
          'isAdmin': userData['role'] == 'ADMIN',
          'registerRequired': userData['registerRequired'] ?? false,
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
      final response = await ApiService().getMe();
      if (response.statusCode == 200) {
        final userData = response.data['data']['user'];
        final Map<String, dynamic> mappedUser = {
          ...Map<String, dynamic>.from(userData),
          'phone': userData['contactNo'] ?? userData['phone'] ?? '',
          'totalCollectionValue': (userData['goldAdvanceAmount'] ?? 0.0).toDouble(),
          'orderCount': userData['orderCount'] ?? 0,
          'kycStatus': (userData['kycStatus'] ?? 'PENDING').toString().toLowerCase(),
          'bankStatus': (userData['bankStatus'] ?? 'PENDING').toString().toLowerCase(),
          'isAdmin': userData['role'] == 'ADMIN',
          'registerRequired': userData['registerRequired'] ?? false,
        };
        return UserModel.fromJson(mappedUser);
      }
      throw Exception('Failed to fetch user');
    } catch (e) {
      // Return empty user on error
      return UserModel(
        id: '', name: '', phone: '', referralCode: '', kycStatus: '', 
        bankStatus: '', orderCount: 0, totalCollectionValue: 0, 
        passKeySet: false, createdAt: ''
      );
    }
  }

  // Logout
  Future<void> logout() async {
    await StorageService.clearAll();
  }

  // Update Profile
  Future<UserModel?> updateProfile({
    required String name,
    String? email,
    String? address,
    String? aadharNo,
    String? panNo,
    String? bankAccountNo,
    String? bankHolderName,
    String? bankIfsc,
    String? bankName,
  }) async {
    try {
      final response = await ApiService().updateProfile({
        'name': name,
        if (email != null) 'email': email,
        if (address != null) 'address': address,
        if (aadharNo != null) 'aadharNo': aadharNo,
        if (panNo != null) 'panNo': panNo,
        if (bankAccountNo != null) 'bankAccountNo': bankAccountNo,
        if (bankHolderName != null) 'bankHolderName': bankHolderName,
        if (bankIfsc != null) 'bankIfsc': bankIfsc,
        if (bankName != null) 'bankName': bankName,
      });

      if (response.statusCode == 200) {
        final userData = response.data['data']['user'];
        final Map<String, dynamic> mappedUser = {
          ...Map<String, dynamic>.from(userData),
          'phone': userData['contactNo'] ?? userData['phone'] ?? '',
          'totalCollectionValue': (userData['goldAdvanceAmount'] ?? 0.0).toDouble(),
          'orderCount': userData['orderCount'] ?? 0,
          'kycStatus': (userData['kycStatus'] ?? 'PENDING').toString().toLowerCase(),
          'bankStatus': (userData['bankStatus'] ?? 'PENDING').toString().toLowerCase(),
          'isAdmin': userData['role'] == 'ADMIN',
          'registerRequired': false,
        };
        return UserModel.fromJson(mappedUser);
      }
      return null;
    } catch (e) {
      return null;
    }
  }
}
