import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../theme/theme_palette.dart';

final themeProvider = StateNotifierProvider<ThemeNotifier, ThemeMode>((ref) {
  return ThemeNotifier();
});

class ThemeNotifier extends StateNotifier<ThemeMode> {
  ThemeNotifier() : super(ThemeMode.dark); // Default to Premium Dark

  void toggleTheme() {
    state = state == ThemeMode.light ? ThemeMode.dark : ThemeMode.light;
  }

  void setTheme(ThemeMode mode) {
    state = mode;
  }
}

// Helper to provide the current palette
final paletteProvider = Provider<ThemePalette>((ref) {
  final mode = ref.watch(themeProvider);
  return mode == ThemeMode.dark ? ThemePalette.dark : ThemePalette.light;
});
