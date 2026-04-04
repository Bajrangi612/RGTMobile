import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/kyc_repository.dart';
import '../data/models/kyc_model.dart';

final kycRepositoryProvider = Provider<KycRepository>((ref) => KycRepository());

class KycState {
  final KycModel? kycData;
  final BankModel? bankData;
  final bool isLoading;
  final String? error;
  final String? bankName; // From IFSC lookup

  KycState({
    this.kycData,
    this.bankData,
    this.isLoading = false,
    this.error,
    this.bankName,
  });

  KycState copyWith({
    KycModel? kycData,
    BankModel? bankData,
    bool? isLoading,
    String? error,
    String? bankName,
  }) {
    return KycState(
      kycData: kycData ?? this.kycData,
      bankData: bankData ?? this.bankData,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      bankName: bankName ?? this.bankName,
    );
  }
}

class KycNotifier extends StateNotifier<KycState> {
  final KycRepository _repository;

  KycNotifier(this._repository) : super(KycState());

  Future<bool> submitAadhaarKyc(String aadhaarNumber) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final kyc = await _repository.submitAadhaarKyc(aadhaarNumber);
      state = state.copyWith(kycData: kyc, isLoading: false);
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: 'KYC submission failed');
      return false;
    }
  }

  Future<bool> verifyAadhaarOtp(String aadhaarNumber, String otp) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final kyc = await _repository.verifyAadhaarOtp(aadhaarNumber, otp);
      state = state.copyWith(kycData: kyc, isLoading: false);
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: 'Invalid OTP. Please try again.');
      return false;
    }
  }

  Future<bool> submitBankDetails({
    required String accountNumber,
    required String ifscCode,
    required String accountHolderName,
  }) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final bank = await _repository.submitBankDetails(
        accountNumber: accountNumber,
        ifscCode: ifscCode,
        accountHolderName: accountHolderName,
      );
      state = state.copyWith(bankData: bank, isLoading: false);
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: 'Bank submission failed');
      return false;
    }
  }

  Future<void> lookupIfsc(String ifscCode) async {
    try {
      final name = await _repository.lookupIfsc(ifscCode);
      state = state.copyWith(bankName: name);
    } catch (_) {}
  }

  Future<void> loadStatus() async {
    state = state.copyWith(isLoading: true);
    try {
      final kyc = await _repository.getKycStatus();
      final bank = await _repository.getBankStatus();
      state = state.copyWith(kycData: kyc, bankData: bank, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false);
    }
  }
}

final kycProvider = StateNotifierProvider<KycNotifier, KycState>((ref) {
  return KycNotifier(ref.watch(kycRepositoryProvider));
});
