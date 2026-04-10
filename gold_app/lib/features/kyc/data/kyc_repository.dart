import '../../../core/network/api_service.dart';
import '../../../core/constants/app_constants.dart';
import 'models/kyc_model.dart';

class KycRepository {
  final ApiService _apiService = ApiService();

  // Submit Aadhaar KYC
  Future<KycModel> submitAadhaarKyc(String aadhaarNumber) async {
    final response = await _apiService.post('/users/kyc', data: {
      'aadhaarNo': aadhaarNumber,
    });
    
    return KycModel.fromJson(response.data['data']['user']);
  }

  // Verification is handled by admin manually in early production
  Future<KycModel> verifyAadhaarOtp(String aadhaarNumber, String otp) async {
    // For now, mirroring submit but we can add a specific verification endpoint if needed
    final response = await _apiService.post('/users/kyc', data: {
      'aadhaarNo': aadhaarNumber,
    });
    
    return KycModel.fromJson(response.data['data']['user']);
  }

  // Get KYC Status
  Future<KycModel?> getKycStatus() async {
    try {
      final response = await _apiService.get('/auth/me');
      if (response.statusCode == 200) {
        return KycModel.fromJson(response.data['data']['user']);
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  // Submit Bank Details
  Future<BankModel> submitBankDetails({
    required String accountNumber,
    required String ifscCode,
    required String accountHolderName,
    String? bankName,
  }) async {
    final response = await _apiService.submitBankDetails({
      'accountNumber': accountNumber,
      'ifscCode': ifscCode,
      'accountHolderName': accountHolderName,
      'bankName': bankName,
    });

    if (response.statusCode == 200) {
      return BankModel.fromJson(response.data['data']['user']);
    }
    throw Exception('Failed to submit bank details');
  }

  // Get Bank Status
  Future<BankModel?> getBankStatus() async {
    try {
      final response = await _apiService.getBankDetails();
      if (response.statusCode == 200) {
        final bankData = response.data['data']['bank'];
        if (bankData == null) return null;
        return BankModel.fromJson(bankData);
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  // IFSC Lookup (mock)
  Future<String?> lookupIfsc(String ifscCode) async {
    await Future.delayed(const Duration(milliseconds: 500));
    final banks = {
      'SBIN': 'State Bank of India',
      'HDFC': 'HDFC Bank',
      'ICIC': 'ICICI Bank',
      'KKBK': 'Kotak Mahindra Bank',
      'UTIB': 'Axis Bank',
      'PUNB': 'Punjab National Bank',
      'BARB': 'Bank of Baroda',
    };
    final prefix = ifscCode.length >= 4 ? ifscCode.substring(0, 4).toUpperCase() : '';
    return banks[prefix];
  }
}
