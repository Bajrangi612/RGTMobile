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
    primary: const Color(0xFFFFD700), // Electric Neon Gold
    secondary: const Color(0xFFFF8C00), // Vivid Amber
    background: const Color(0xFF080B15), // Deep Cosmic Obsidian
    surface: const Color(0xFF0E121F), // Deep Indigo Surface
    card: const Color(0xFF151B2E), // Glassy Indigo Card
    cardAlt: const Color(0xFF1C243D), // Elevated Indigo Card
    textPrimary: const Color(0xFFFFFFFF),
    textSecondary: const Color(0xFFB0B3B8), 
    textMuted: const Color(0xFF7D828A), 
    border: const Color(0x1A64B5F6), // Subtle Blue border for depth
    bgGradient: const LinearGradient(
      colors: [Color(0xFF080B15), Color(0xFF0F1426)],
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
    ),
    cardGradient: const LinearGradient(
      colors: [Color(0xFF1C243D), Color(0xFF151B2E)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
  );

  static final ThemePalette vibrant = ThemePalette(
    primary: const Color(0xFFFFD700), 
    secondary: const Color(0xFF00E5FF), // Electric Cyan
    background: const Color(0xFF0A0E21), // Midnight Navy
    surface: const Color(0xFF1A1F3D), 
    card: const Color(0xFF242B55), 
    cardAlt: const Color(0xFF2E376E), 
    textPrimary: const Color(0xFFFFFFFF),
    textSecondary: const Color(0xFFE0E0E0),
    textMuted: const Color(0xFFB0BEC5),
    border: const Color(0x3300E5FF),
    bgGradient: const LinearGradient(
      colors: [Color(0xFF0A0E21), Color(0xFF151B40)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
    cardGradient: const LinearGradient(
      colors: [Color(0xFF2E376E), Color(0xFF242B55)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
  );

  static final ThemePalette light = ThemePalette(
    primary: const Color(0xFFD4AF37), // Metallic Champagne Gold
    secondary: const Color(0xFFC5A059), // Burnished Gold
    background: const Color(0xFFFBFBFB), // Premium Clean White
    surface: const Color(0xFFFFFFFF),
    card: const Color(0xFFFFFFFF),
    cardAlt: const Color(0xFFF5F7FA), // Soft Light Grey
    textPrimary: const Color(0xFF121417), // Deep Graphite
    textSecondary: const Color(0xFF4B5563), // Slate Grey
    textMuted: const Color(0xFF9CA3AF), // Muted Grey
    border: const Color(0x0F000000), // Very subtel border
    bgGradient: const LinearGradient(
      colors: [Color(0xFFFBFBFB), Color(0xFFFFFFFF)],
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
    ),
    cardGradient: const LinearGradient(
      colors: [Color(0xFFFFFFFF), Color(0xFFF9FAFB)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
  );
}
