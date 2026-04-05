import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

class AppTextStyles {
  AppTextStyles._();

  // Headings — Outfit
  static TextStyle get h1 => GoogleFonts.outfit(
        fontSize: 34,
        fontWeight: FontWeight.w700,
        color: AppColors.pureWhite,
        letterSpacing: -0.2, // Slightly more open for luxury feel
      );

  static TextStyle get h2 => GoogleFonts.outfit(
        fontSize: 26,
        fontWeight: FontWeight.w600,
        color: AppColors.pureWhite,
        letterSpacing: -0.1,
      );

  static TextStyle get h3 => GoogleFonts.outfit(
        fontSize: 22,
        fontWeight: FontWeight.w600,
        color: AppColors.pureWhite,
      );

  static TextStyle get h4 => GoogleFonts.outfit(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: AppColors.pureWhite,
        letterSpacing: 0.1,
      );

  // Body — Inter (Remains for high readability)
  static TextStyle get bodyLarge => GoogleFonts.inter(
        fontSize: 16,
        fontWeight: FontWeight.w500,
        color: AppColors.offWhite,
        height: 1.4,
      );

  static TextStyle get bodyMedium => GoogleFonts.inter(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        color: AppColors.offWhite,
        height: 1.5,
      );

  static TextStyle get bodySmall => GoogleFonts.inter(
        fontSize: 12,
        fontWeight: FontWeight.w400,
        color: AppColors.lightGrey,
      );

  // Labels — Outfit for a punchy modern feel
  static TextStyle get labelLarge => GoogleFonts.outfit(
        fontSize: 15,
        fontWeight: FontWeight.w600,
        color: AppColors.pureWhite,
        letterSpacing: 0.8, // Elegant tracking
      );

  static TextStyle get labelMedium => GoogleFonts.outfit(
        fontSize: 13,
        fontWeight: FontWeight.w500,
        color: AppColors.grey,
      );

  static TextStyle get labelSmall => GoogleFonts.outfit(
        fontSize: 11,
        fontWeight: FontWeight.w500,
        color: AppColors.grey,
        letterSpacing: 0.5,
      );

  // Special Styles
  static TextStyle get goldTitle => GoogleFonts.outfit(
        fontSize: 30,
        fontWeight: FontWeight.w700,
        foreground: Paint()
          ..shader = AppColors.goldGradient.createShader(
            const Rect.fromLTWH(0, 0, 400, 50),
          ),
      );

  static TextStyle get goldPrice => GoogleFonts.outfit(
        fontSize: 38,
        fontWeight: FontWeight.w700,
        color: AppColors.pureWhite,
        letterSpacing: -1.0,
      );

  static TextStyle get priceTag => GoogleFonts.outfit(
        fontSize: 24,
        fontWeight: FontWeight.w700,
        color: AppColors.royalGold,
      );

  static TextStyle get caption => GoogleFonts.outfit(
        fontSize: 12,
        fontWeight: FontWeight.w400,
        color: AppColors.grey,
        letterSpacing: 0.2,
      );

  static TextStyle get button => GoogleFonts.outfit(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: AppColors.pureWhite,
        letterSpacing: 1.2, // Premium button tracking
      );

  static TextStyle get buttonSmall => GoogleFonts.poppins(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: AppColors.deepBlack,
      );
}

extension TextStyleExtensions on TextStyle {
  TextStyle scaled(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    double factor = 1.0;
    if (width > 600) factor = 1.1;
    if (width < 360) factor = 0.9;
    return copyWith(fontSize: (fontSize ?? 14) * factor);
  }
}
