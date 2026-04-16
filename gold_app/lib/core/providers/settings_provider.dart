import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../network/api_service.dart';

class SettingsState {
  final double referralReward;
  final double minRefund;
  final double gstRate;
  final double globalDiscount;
  final double makingCharge;
  final double makingGst;
  final int deliveryDays;
  final String latestVersion;
  final String minVersion;
  final bool isLoading;
  final String? error;

  SettingsState({
    this.referralReward = 500.0,
    this.minRefund = 1000.0,
    this.gstRate = 3.0,
    this.globalDiscount = 0.0,
    this.makingCharge = 0.0,
    this.makingGst = 0.0,
    this.deliveryDays = 7,
    this.latestVersion = '1.0.0',
    this.minVersion = '1.0.0',
    this.isLoading = false,
    this.error,
  });

  SettingsState copyWith({
    double? referralReward,
    double? minRefund,
    double? gstRate,
    double? globalDiscount,
    double? makingCharge,
    double? makingGst,
    int? deliveryDays,
    String? latestVersion,
    String? minVersion,
    bool? isLoading,
    String? error,
  }) {
    return SettingsState(
      referralReward: referralReward ?? this.referralReward,
      minRefund: minRefund ?? this.minRefund,
      gstRate: gstRate ?? this.gstRate,
      globalDiscount: globalDiscount ?? this.globalDiscount,
      makingCharge: makingCharge ?? this.makingCharge,
      makingGst: makingGst ?? this.makingGst,
      deliveryDays: deliveryDays ?? this.deliveryDays,
      latestVersion: latestVersion ?? this.latestVersion,
      minVersion: minVersion ?? this.minVersion,
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
        minRefund: _toDouble(data['min_withdrawal'], 1000.0),
        gstRate: _toDouble(data['gst_rate'], 3.0),
        globalDiscount: _toDouble(data['global_discount_percent'], 0.0),
        makingCharge: _toDouble(data['making_charge_percent'], 0.0),
        makingGst: _toDouble(data['gst_on_making_percent'], 0.0),
        deliveryDays: (data['delivery_days'] as num?)?.toInt() ?? 7,
        latestVersion: data['app_latest_version']?.toString() ?? '1.0.0',
        minVersion: data['app_min_version']?.toString() ?? '1.0.0',
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
