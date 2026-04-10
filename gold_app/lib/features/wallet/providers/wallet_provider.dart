import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/models/transaction_model.dart';
import '../../../core/network/api_service.dart';

class WalletState {
  final double balance;
  final List<TransactionModel> transactions;
  final bool isLoading;
  final String? error;

  WalletState({
    this.balance = 0.0,
    this.transactions = const [],
    this.isLoading = false,
    this.error,
  });

  WalletState copyWith({
    double? balance,
    List<TransactionModel>? transactions,
    bool? isLoading,
    String? error,
  }) {
    return WalletState(
      balance: balance ?? this.balance,
      transactions: transactions ?? this.transactions,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

class WalletNotifier extends StateNotifier<WalletState> {
  final ApiService _apiService;

  WalletNotifier(this._apiService) : super(WalletState());

  Future<void> loadWalletDetails() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final response = await _apiService.getWalletDetails();
      if (response.statusCode == 200) {
        final data = response.data['data'];
        print('💰 [WalletNotifier] Data received: $data');
        
        final wallet = data['wallet'];
        final transactionsJson = data['transactions'] as List;
        
        final transactions = transactionsJson
            .map((json) => TransactionModel.fromJson(json))
            .toList();

        final double balance = wallet != null 
            ? (double.tryParse(wallet['balance'].toString()) ?? 0.0) 
            : 0.0;

        state = state.copyWith(
          balance: balance,
          transactions: transactions,
          isLoading: false,
        );
      } else {
        state = state.copyWith(
          isLoading: false,
          error: 'Failed to load wallet data',
        );
      }
    } catch (e, stack) {
      print('❌ [WalletNotifier] Error: $e');
      print('🥞 Stacktrace: $stack');
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  Future<bool> requestWithdrawal(double amount) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final response = await _apiService.requestWithdrawal(amount, 'BANK');
      if (response.statusCode == 200 || response.statusCode == 201) {
        await loadWalletDetails();
        return true;
      }
      state = state.copyWith(isLoading: false, error: 'Withdrawal request failed');
      return false;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return false;
    }
  }
}

final walletProvider = StateNotifierProvider<WalletNotifier, WalletState>((ref) {
  return WalletNotifier(ApiService());
});
