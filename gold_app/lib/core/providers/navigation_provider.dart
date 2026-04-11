import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Manages the active tab index of the main HomeScreen dashboard.
/// 0: Home Dashboard
/// 1: Orders Tab
/// 2: Referral Tab
/// 3: Profile Tab
/// 4: Catalog Tab
final navigationProvider = StateProvider<int>((ref) => 0);
