import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class MithaqColors {
  // Brand Palette (Mithaq)
  static const Color navy = Color(0xFF1A2B56); // Primary (Trust)
  static const Color mint = Color(0xFFA8E6CF); // Positive Accent
  static const Color pink = Color(0xFFF2D1D1); // Soft Accent

  // Light Theme
  static const Color backgroundLight = Color(0xFFF7F8FA); // off-white
  static const Color surfaceLight = Colors.white;
  static const Color textPrimaryLight = Color(0xFF1A2B56); // navy text
  static const Color textSecondaryLight = Color(0xFF4A5568);

  // Dark Theme (Navy-based, not pure black)
  static const Color backgroundDark = Color(0xFF101D3A); // deeper navy
  static const Color surfaceDark = Color(0xFF16264B); // navy surface
  static const Color textPrimaryDark = Color(0xFFF2F4F8); // near-white
  static const Color textSecondaryDark = Color(0xFFB7C0D1);

  // Utility
  static const Color error = Color(0xFFEF4444);
  static const Color outlineLight = Color(0xFFE5E7EB);
  static const Color outlineDark = Color(0xFF2A3A63);

  // Backward Compatibility Aliases
  static const Color primary = navy;
  static const Color accent = mint;
  static const Color secondary = mint;
}

class MithaqTheme {
  static ThemeData lightTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    scaffoldBackgroundColor: MithaqColors.backgroundLight,
    colorScheme: ColorScheme.fromSeed(
      seedColor: MithaqColors.navy,
      brightness: Brightness.light,
      primary: MithaqColors.navy,
      secondary: MithaqColors.mint,
      surface: MithaqColors.surfaceLight,
      error: MithaqColors.error,
    ),
    textTheme: GoogleFonts.outfitTextTheme().apply(
      bodyColor: MithaqColors.textPrimaryLight,
      displayColor: MithaqColors.textPrimaryLight,
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.transparent,
      foregroundColor: MithaqColors.navy,
      elevation: 0,
      centerTitle: true,
    ),
    dividerTheme: const DividerThemeData(
      color: MithaqColors.outlineLight,
      thickness: 1,
      space: 1,
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: MithaqColors.navy,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    ),
    chipTheme: ChipThemeData(
      backgroundColor: MithaqColors.pink.withValues(alpha: 0.35),
      labelStyle: const TextStyle(color: MithaqColors.navy),
      side: BorderSide.none,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
    ),
  );

  static ThemeData darkTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    scaffoldBackgroundColor: MithaqColors.backgroundDark,
    colorScheme: ColorScheme.fromSeed(
      seedColor: MithaqColors.navy,
      brightness: Brightness.dark,
      primary: MithaqColors.mint, // primary actions become mint on dark
      secondary: MithaqColors.pink, // secondary accent
      surface: MithaqColors.surfaceDark,
      error: MithaqColors.error,
    ),
    textTheme: GoogleFonts.outfitTextTheme(ThemeData.dark().textTheme).apply(
      bodyColor: MithaqColors.textPrimaryDark,
      displayColor: MithaqColors.textPrimaryDark,
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.transparent,
      foregroundColor: MithaqColors.textPrimaryDark,
      elevation: 0,
      centerTitle: true,
    ),
    dividerTheme: const DividerThemeData(
      color: MithaqColors.outlineDark,
      thickness: 1,
      space: 1,
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: MithaqColors.mint,
        foregroundColor: MithaqColors.navy,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    ),
    chipTheme: ChipThemeData(
      backgroundColor: MithaqColors.pink.withValues(alpha: 0.18),
      labelStyle: const TextStyle(color: MithaqColors.textPrimaryDark),
      side: const BorderSide(color: MithaqColors.outlineDark),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
    ),
  );
}
