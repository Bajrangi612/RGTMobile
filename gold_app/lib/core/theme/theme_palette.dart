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
    primary: const Color(0xFFD4AF37), // Metallic Champagne Gold
    secondary: const Color(0xFFA68542), // Muted Burnished Gold
    background: const Color(0xFF05070A), // Midnight Obsidian
    surface: const Color(0xFF0E1217), // Deep Navy Surface
    card: const Color(0xFF151921), // Subtle Obsidian Card
    cardAlt: const Color(0xFF1C222D), // Elevated Obsidian Card
    textPrimary: const Color(0xFFFFFFFF),
    textSecondary: const Color(0xFFB0B3B8), // Soft muted text
    textMuted: const Color(0xFF7D828A), // Deep muted text
    border: const Color(0x1AFFFFFF), // Subtler border
    bgGradient: const LinearGradient(
      colors: [Color(0xFF05070A), Color(0xFF0C0E14)],
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
    ),
    cardGradient: const LinearGradient(
      colors: [Color(0xFF1C222D), Color(0xFF151921)],
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
