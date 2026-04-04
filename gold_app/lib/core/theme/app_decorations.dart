import 'package:flutter/material.dart';
import 'dart:ui';
import 'app_colors.dart';

class AppDecorations {
  AppDecorations._();

  // Glassmorphic Card
  static BoxDecoration get glassCard => BoxDecoration(
        color: AppColors.glassWhite,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.glassBorder, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 20,
            offset: Offset(0, 8),
          ),
        ],
      );

  // Gold Accent Card
  static BoxDecoration get goldCard => BoxDecoration(
        color: AppColors.cardDark,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppColors.royalGold.withOpacity(0.3),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.royalGold.withOpacity(0.08),
            blurRadius: 20,
            offset: Offset(0, 4),
          ),
          BoxShadow(
            color: Colors.black.withOpacity(0.4),
            blurRadius: 20,
            offset: Offset(0, 8),
          ),
        ],
      );

  // Premium Dark Card
  static BoxDecoration get darkCard => BoxDecoration(
        gradient: AppColors.cardGradient,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white.withOpacity(0.06),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 16,
            offset: Offset(0, 6),
          ),
        ],
      );

  // Gold Gradient Button
  static BoxDecoration get goldButton => BoxDecoration(
        gradient: AppColors.goldGradient,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: AppColors.royalGold.withOpacity(0.3),
            blurRadius: 16,
            offset: Offset(0, 6),
          ),
        ],
      );

  // Disabled Button
  static BoxDecoration get disabledButton => BoxDecoration(
        color: AppColors.darkGrey,
        borderRadius: BorderRadius.circular(14),
      );

  // Input Field
  static InputDecoration inputDecoration({
    required String label,
    String? hint,
    Widget? prefix,
    Widget? suffix,
  }) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      labelStyle: TextStyle(color: AppColors.grey, fontSize: 14),
      hintStyle: TextStyle(color: AppColors.darkGrey, fontSize: 14),
      prefixIcon: prefix,
      suffixIcon: suffix,
      filled: true,
      fillColor: AppColors.cardDark,
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: AppColors.glassBorder, width: 1),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: AppColors.royalGold, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: AppColors.error, width: 1),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: AppColors.error, width: 1.5),
      ),
    );
  }

  // Bottom Sheet
  static BoxDecoration get bottomSheet => BoxDecoration(
        color: AppColors.charcoal,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        border: Border.all(color: AppColors.glassBorder, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.5),
            blurRadius: 30,
            offset: Offset(0, -10),
          ),
        ],
      );

  // Page background
  static BoxDecoration get pageBackground => BoxDecoration(
        gradient: AppColors.darkGradient,
      );

  // Gold glow effect
  static List<BoxShadow> get goldGlow => [
        BoxShadow(
          color: AppColors.royalGold.withOpacity(0.2),
          blurRadius: 24,
          spreadRadius: 2,
        ),
      ];
}
