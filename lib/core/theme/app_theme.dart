import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Nepali cultural colour palette + typography.
class NepaliColors {
  // Primary — Nepali crimson / royal red
  static const primary = Color(0xFFBF1E2E);
  static const primaryDark = Color(0xFF8C0D1A);
  static const primaryLight = Color(0xFFE84C5A);

  // Gold — inspired by Nepali jewellery & temples
  static const gold = Color(0xFFD4A017);
  static const goldLight = Color(0xFFF5C842);

  // Background — warm parchment / mountain mist
  static const background = Color(0xFFFDF6E3);
  static const surface = Color(0xFFFFFFFF);
  static const surfaceDark = Color(0xFFF2E6C8);

  // Text
  static const textPrimary = Color(0xFF1A0A0A);
  static const textSecondary = Color(0xFF5C3A1E);

  // Player colours
  static const redPlayer = Color(0xFFE53935);
  static const greenPlayer = Color(0xFF43A047);
  static const yellowPlayer = Color(0xFFFDD835);
  static const bluePlayer = Color(0xFF1E88E5);

  // Board colours
  static const boardBackground = Color(0xFFFFF8DC);
  static const boardBorder = Color(0xFF8B6914);
  static const neutralCell = Color(0xFFF5F5F0);
  static const safeCell = Color(0xFFE8F5E9);
  static const safeCellStar = Color(0xFF81C784);
  static const centrePetal = Color(0xFFFFECB3);

  // Dark Dhaka-inspired pattern accent
  static const dhakaRed = Color(0xFF8B0000);
  static const dhakaGreen = Color(0xFF006400);
  static const dhakaGold = Color(0xFFB8860B);

  static Color playerColor(int index) {
    switch (index) {
      case 0:
        return redPlayer;
      case 1:
        return greenPlayer;
      case 2:
        return yellowPlayer;
      case 3:
        return bluePlayer;
      default:
        return Colors.grey;
    }
  }

  static Color playerColorLight(int index) {
    switch (index) {
      case 0:
        return redPlayer.withValues(alpha: 0.25);
      case 1:
        return greenPlayer.withValues(alpha: 0.25);
      case 2:
        return yellowPlayer.withValues(alpha: 0.25);
      case 3:
        return bluePlayer.withValues(alpha: 0.25);
      default:
        return Colors.grey.withValues(alpha: 0.2);
    }
  }
}

class AppTheme {
  static ThemeData get light {
    final base = ThemeData.light(useMaterial3: true);
    return base.copyWith(
      colorScheme: ColorScheme.fromSeed(
        seedColor: NepaliColors.primary,
        primary: NepaliColors.primary,
        secondary: NepaliColors.gold,
        surface: NepaliColors.surface,
        onPrimary: Colors.white,
        onSecondary: NepaliColors.textPrimary,
        onSurface: NepaliColors.textPrimary,
      ),
      scaffoldBackgroundColor: NepaliColors.background,
      textTheme: _textTheme(base.textTheme),
      appBarTheme: AppBarTheme(
        backgroundColor: NepaliColors.primary,
        foregroundColor: Colors.white,
        elevation: 4,
        centerTitle: true,
        titleTextStyle: GoogleFonts.poppins(
          color: Colors.white,
          fontSize: 22,
          fontWeight: FontWeight.bold,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: NepaliColors.primary,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          textStyle: GoogleFonts.poppins(
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
          elevation: 6,
        ),
      ),
      cardTheme: CardThemeData(
        color: NepaliColors.surface,
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(
              color: NepaliColors.gold.withValues(alpha: 0.4), width: 1),
        ),
      ),
    );
  }

  static TextTheme _textTheme(TextTheme base) {
    final nepali = GoogleFonts.poppinsTextTheme(base);
    return nepali.copyWith(
      displayLarge: nepali.displayLarge?.copyWith(
          color: NepaliColors.textPrimary, fontWeight: FontWeight.bold),
      displayMedium: nepali.displayMedium?.copyWith(
          color: NepaliColors.textPrimary, fontWeight: FontWeight.bold),
      headlineLarge: nepali.headlineLarge?.copyWith(
          color: NepaliColors.textPrimary, fontWeight: FontWeight.bold),
      headlineMedium: nepali.headlineMedium
          ?.copyWith(color: NepaliColors.primary, fontWeight: FontWeight.w700),
      titleLarge: nepali.titleLarge?.copyWith(
          color: NepaliColors.textPrimary, fontWeight: FontWeight.w600),
      bodyLarge: nepali.bodyLarge
          ?.copyWith(color: NepaliColors.textPrimary, fontSize: 16),
      bodyMedium: nepali.bodyMedium
          ?.copyWith(color: NepaliColors.textSecondary, fontSize: 14),
      labelLarge: nepali.labelLarge?.copyWith(fontWeight: FontWeight.w600),
    );
  }
}
