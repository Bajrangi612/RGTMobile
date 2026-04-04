import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../theme/theme_palette.dart';

final themeProvider = StateNotifierProvider<ThemeNotifier, ThemeMode>((ref) {
  return ThemeNotifier();
});

class ThemeNotifier extends StateNotifier<ThemeMode> {
  ThemeNotifier() : super(ThemeMode.light);

  void toggleTheme() {
    // Theme is now locked to Light Mode per user request
    state = ThemeMode.light;
  }

  void setTheme(ThemeMode mode) {
    state = ThemeMode.light;
  }
}

// Helper to provide the current palette
final paletteProvider = Provider<ThemePalette>((ref) {
  // Always return light palette
  return ThemePalette.light;
});
