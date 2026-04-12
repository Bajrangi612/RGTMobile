import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../network/api_service.dart';

class SettingsState {
  final double referralReward;
  final double minWithdrawal;
  final double gstRate;
  final double globalDiscount;
  final int deliveryDays;
  final bool isLoading;
  final String? error;

  SettingsState({
    this.referralReward = 500.0,
    this.minWithdrawal = 1000.0,
    this.gstRate = 3.0,
    this.globalDiscount = 0.0,
    this.deliveryDays = 7,
    this.isLoading = false,
    this.error,
  });

  SettingsState copyWith({
    double? referralReward,
    double? minWithdrawal,
    double? gstRate,
    double? globalDiscount,
    int? deliveryDays,
    bool? isLoading,
    String? error,
  }) {
    return SettingsState(
      referralReward: referralReward ?? this.referralReward,
      minWithdrawal: minWithdrawal ?? this.minWithdrawal,
      gstRate: gstRate ?? this.gstRate,
      globalDiscount: globalDiscount ?? this.globalDiscount,
      deliveryDays: deliveryDays ?? this.deliveryDays,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

class SettingsNotifier extends StateNotifier<SettingsState> {
  SettingsNotifier() : super(SettingsState()) {
    loadSettings();
  }

  Future<void> loadSettings() async {
    state = state.copyWith(isLoading: true);
    try {
      final response = await ApiService().get('/configs/public');
      final data = response.data['data'];
      
      state = state.copyWith(
        referralReward: _toDouble(data['referral_reward'], 500.0),
        minWithdrawal: _toDouble(data['min_withdrawal'], 1000.0),
        gstRate: _toDouble(data['gst_rate'], 3.0),
        globalDiscount: _toDouble(data['global_discount_percent'], 0.0),
        deliveryDays: (data['delivery_days'] as num?)?.toInt() ?? 7,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  double _toDouble(dynamic value, double defaultValue) {
    if (value is num) return value.toDouble();
    return double.tryParse(value?.toString() ?? '') ?? defaultValue;
  }
}

final settingsProvider = StateNotifierProvider<SettingsNotifier, SettingsState>((ref) {
  return SettingsNotifier();
});
