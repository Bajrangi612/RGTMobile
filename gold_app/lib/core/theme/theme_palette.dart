import 'package:flutter/material.dart';

class ThemePalette {
  final Color primary;
  final Color secondary;
  final Color background;
  final Color surface;
  final Color card;
  final Color cardAlt;
  final Color textPrimary;
  final Color textSecondary;
  final Color textMuted;
  final Color border;
  final LinearGradient bgGradient;
  final LinearGradient cardGradient;

  ThemePalette({
    required this.primary,
    required this.secondary,
    required this.background,
    required this.surface,
    required this.card,
    required this.cardAlt,
    required this.textPrimary,
    required this.textSecondary,
    required this.textMuted,
    required this.border,
    required this.bgGradient,
    required this.cardGradient,
  });

  static final ThemePalette dark = ThemePalette(
    primary: Color(0xFFFFD700),
    secondary: Color(0xFFDAA520),
    background: Color(0xFF0A0A0F),
    surface: Color(0xFF14141F),
    card: Color(0xFF1A1A26),
    cardAlt: Color(0xFF222233),
    textPrimary: Color(0xFFFFFFFF),
    textSecondary: Color(0xFFE0E0E0),
    textMuted: Color(0xFF9E9EAE),
    border: Color(0x1FFFFFFF),
    bgGradient: LinearGradient(
      colors: [Color(0xFF0A0A0F), Color(0xFF12121E)],
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
    ),
    cardGradient: LinearGradient(
      colors: [Color(0xFF222233), Color(0xFF1A1A26)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
  );

  static final ThemePalette light = ThemePalette(
    primary: Color(0xFFD4AF37), // Metallic Champagne Gold
    secondary: Color(0xFFE8C170), // Soft Gold
    background: Color(0xFFFFFDF5), // Soft Ivory
    surface: Color(0xFFFFFFFF),
    card: Color(0xFFFFFFFF),
    cardAlt: Color(0xFFFDFBF0),
    textPrimary: Color(0xFF1A1A1A), // Deep Charcoal for high contrast
    textSecondary: Color(0xFF454545),
    textMuted: Color(0xFF8E8E93),
    border: Color(0x1F000000),
    bgGradient: LinearGradient(
      colors: [Color(0xFFFFFDF5), Color(0xFFFFFFFF)],
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
    ),
    cardGradient: LinearGradient(
      colors: [Color(0xFFFFFFFF), Color(0xFFFDFBF0)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
  );
}
