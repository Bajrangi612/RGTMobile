import 'package:flutter/material.dart';
import 'theme_palette.dart';

class AppColors {
  AppColors._();

  // Global instance to hold current palette
  static ThemePalette _palette = ThemePalette.light;

  // Method to update palette - called from main.dart root
  static void updatePalette(ThemePalette newPalette) {
    _palette = newPalette;
  }

  // Primary Gold Palette
  static Color get royalGold => _palette.primary;
  static Color get darkGold => _palette.secondary;
  static const Color lightGold = Color(0xFFFFF8DC);
  static const Color amber = Color(0xFFFFBF00);

  // Background & Surface
  static Color get background => _palette.background;
  static Color get surface => _palette.surface;
  static Color get deepBlack => _palette.background; // Legacy compatibility
  static const Color charcoal = Color(0xFF131320);
  static const Color darkSurface = Color(0xFF101726);
  static Color get cardDark => _palette.card;
  static Color get cardDarkAlt => _palette.cardAlt;

  // Text
  static Color get pureWhite => _palette.textPrimary;
  static Color get offWhite => _palette.textSecondary;
  static Color get grey => _palette.textMuted;
  static const Color lightGrey = Color(0xFFB0B0B0);
  static const Color darkGrey = Color(0xFF3A3A4A);

  // Status
  static const Color success = Color(0xFF2E7D32);
  static const Color error = Color(0xFFD32F2F);
  static const Color warning = Color(0xFFF9A825);
  static const Color info = Color(0xFF1976D2);
  static const Color pending = Color(0xFFFBC02D);

  // Gradients — "Satin Luxury Gold"
  static LinearGradient get goldGradient => const LinearGradient(
        colors: [Color(0xFFD4AF37), Color(0xFFF2D17E), Color(0xFFB8860B)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      );

  static LinearGradient get darkGradient => _palette.bgGradient;

  static LinearGradient get cardGradient => _palette.cardGradient;

  static const LinearGradient successGradient = LinearGradient(
    colors: [Color(0xFF34C759), Color(0xFF30D158)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // Glass Effect Colors — High Transparency
  static Color get glassWhite => Colors.white.withOpacity(0.4);
  static Color get glassBorder => Colors.white.withOpacity(0.12);
  static Color get glassGold => const Color(0xFFD4AF37).withOpacity(0.1);
}
