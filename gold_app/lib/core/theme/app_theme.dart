import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

class AppTheme {
  AppTheme._();

  static ThemeData get lightTheme {
    return _buildTheme(Brightness.light);
  }

  static ThemeData get darkTheme {
    return _buildTheme(Brightness.dark);
  }

  static ThemeData _buildTheme(Brightness brightness) {
    final isDark = brightness == Brightness.dark;
    
    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      scaffoldBackgroundColor: AppColors.deepBlack,
      primaryColor: AppColors.royalGold,

      colorScheme: ColorScheme(
        brightness: brightness,
        primary: AppColors.royalGold,
        onPrimary: isDark ? AppColors.deepBlack : AppColors.pureWhite,
        secondary: AppColors.darkGold,
        onSecondary: AppColors.deepBlack,
        surface: AppColors.cardDark,
        onSurface: AppColors.pureWhite,
        error: AppColors.error,
        onError: AppColors.pureWhite,
      ),

      // AppBar
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        systemOverlayStyle: SystemUiOverlayStyle.dark,
        titleTextStyle: GoogleFonts.poppins(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: AppColors.pureWhite,
        ),
        iconTheme: IconThemeData(color: AppColors.royalGold),
      ),

      // Cards
      cardTheme: CardThemeData(
        color: AppColors.cardDark,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: AppColors.pureWhite.withOpacity(0.06)),
        ),
      ),

      // Bottom Nav
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: AppColors.cardDark,
        selectedItemColor: AppColors.royalGold,
        unselectedItemColor: AppColors.grey,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
      ),

      // Input fields
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.cardDark,
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
        labelStyle: TextStyle(color: AppColors.grey),
        hintStyle: TextStyle(color: AppColors.grey.withOpacity(0.5)),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: AppColors.pureWhite.withOpacity(0.12)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: AppColors.royalGold, width: 1.5),
        ),
      ),

      // Text
      textTheme: TextTheme(
        headlineLarge: GoogleFonts.poppins(fontSize: 32, fontWeight: FontWeight.w700, color: AppColors.pureWhite),
        headlineMedium: GoogleFonts.poppins(fontSize: 24, fontWeight: FontWeight.w600, color: AppColors.pureWhite),
        headlineSmall: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.w600, color: AppColors.pureWhite),
        bodyLarge: GoogleFonts.inter(fontSize: 16, color: AppColors.pureWhite),
        bodyMedium: GoogleFonts.inter(fontSize: 14, color: AppColors.offWhite),
        bodySmall: GoogleFonts.inter(fontSize: 12, color: AppColors.grey),
        labelLarge: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.pureWhite),
      ),
    );
  }
}
