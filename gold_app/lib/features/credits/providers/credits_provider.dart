import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/models/transaction_model.dart';
import '../../../core/network/api_service.dart';

class CreditsState {
  final double balance;
  final bool isLoading;
  final String? error;
  final List<TransactionModel> transactions;
  final List<dynamic> refundRequests;

  CreditsState({
    this.balance = 0.0,
    this.isLoading = false,
    this.error,
    this.transactions = const [],
    this.refundRequests = const [],
  });

  CreditsState copyWith({
    double? balance,
    bool? isLoading,
    String? error,
    List<TransactionModel>? transactions,
    List<dynamic>? refundRequests,
  }) {
    return CreditsState(
      balance: balance ?? this.balance,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      transactions: transactions ?? this.transactions,
      refundRequests: refundRequests ?? this.refundRequests,
    );
  }
}

class CreditsNotifier extends StateNotifier<CreditsState> {
  final ApiService _apiService;

  CreditsNotifier(this._apiService) : super(CreditsState()) {
    loadCreditDetails();
    loadRefundHistory();
  }

  Future<void> loadCreditDetails() async {
    state = state.copyWith(isLoading: true);
    try {
      final response = await _apiService.getCreditDetails();
      if (response.statusCode == 200) {
        final data = response.data;
        final creditsData = data['wallet'];
        
        // Handle potentially missing credits object
        if (creditsData == null) {
          state = state.copyWith(isLoading: false, balance: 0.0);
          return;
        }

        final double balance = creditsData != null 
            ? (double.tryParse(creditsData['balance'].toString()) ?? 0.0) 
            : 0.0;
        
        final List<dynamic> txnsData = data['transactions'] ?? [];
        final transactions = txnsData.map((t) => TransactionModel.fromJson(t)).toList();
        
        state = state.copyWith(
          isLoading: false, 
          balance: balance,
          transactions: transactions,
        );
      }
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> loadRefundHistory() async {
    try {
      final response = await _apiService.getMyRefunds();
      if (response.statusCode == 200) {
        final List<dynamic> requests = response.data['withdrawals'] ?? [];
        state = state.copyWith(refundRequests: requests);
      }
    } catch (e) {
      debugPrint('⚠️ Refund history failed: $e');
    }
  }

  Future<bool> requestRefund(double amount) async {
    state = state.copyWith(isLoading: true);
    try {
      final response = await _apiService.requestRefund(amount, 'BANK');
      if (response.statusCode == 201 || response.statusCode == 200) {
        await loadCreditDetails();
        await loadRefundHistory();
        return true;
      }
      state = state.copyWith(isLoading: false, error: 'Refund request failed');
      return false;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return false;
    }
  }
}

final creditsProvider = StateNotifierProvider<CreditsNotifier, CreditsState>((ref) {
  return CreditsNotifier(ApiService());
});
