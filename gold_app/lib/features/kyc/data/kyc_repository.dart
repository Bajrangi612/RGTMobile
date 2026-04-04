import '../../../core/services/mock_data_service.dart';
import '../../../core/constants/app_constants.dart';
import 'models/kyc_model.dart';

class KycRepository {
  Future<KycModel> submitAadhaarKyc(String aadhaarNumber) async {
    await MockDataService.simulateDelay(AppConstants.apiDelayLong);
    return KycModel(
      aadhaarNumber: aadhaarNumber,
      status: 'pending', // Verification starts as pending
      submittedAt: DateTime.now(),
    );
  }

  // Verify Aadhaar OTP
  Future<KycModel> verifyAadhaarOtp(String aadhaarNumber, String otp) async {
    await MockDataService.simulateDelay(AppConstants.apiDelayLong);
    if (otp == '123456') { // Mock success OTP
      return KycModel(
        aadhaarNumber: aadhaarNumber,
        status: 'verified',
        name: 'Rahul Sharma',
        submittedAt: DateTime.now().subtract(const Duration(minutes: 5)),
        verifiedAt: DateTime.now(),
      );
    } else {
      throw Exception('Invalid OTP');
    }
  }

  // Get KYC Status
  Future<KycModel?> getKycStatus() async {
    await MockDataService.simulateDelay(AppConstants.apiDelayShort);
    return KycModel(
      aadhaarNumber: '123456789012',
      status: 'verified',
      name: 'Rahul Sharma',
      submittedAt: DateTime.now().subtract(Duration(days: 5)),
      verifiedAt: DateTime.now().subtract(Duration(days: 4)),
    );
  }

  // Submit Bank Details
  Future<BankModel> submitBankDetails({
    required String accountNumber,
    required String ifscCode,
    required String accountHolderName,
  }) async {
    await MockDataService.simulateDelay(AppConstants.apiDelayLong);
    return BankModel(
      accountNumber: accountNumber,
      ifscCode: ifscCode,
      accountHolderName: accountHolderName,
      bankName: 'State Bank of India',
      status: 'verified',
      submittedAt: DateTime.now(),
    );
  }

  // Get Bank Status
  Future<BankModel?> getBankStatus() async {
    await MockDataService.simulateDelay(AppConstants.apiDelayShort);
    return BankModel(
      accountNumber: '1234567890',
      ifscCode: 'SBIN0001234',
      accountHolderName: 'Rahul Sharma',
      bankName: 'State Bank of India',
      status: 'verified',
      submittedAt: DateTime.now().subtract(Duration(days: 5)),
    );
  }

  // IFSC Lookup (mock)
  Future<String?> lookupIfsc(String ifscCode) async {
    await MockDataService.simulateDelay(500);
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
