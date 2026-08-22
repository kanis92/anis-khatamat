import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Thème de l'application ANIS Khatamat
/// Couleurs inspirées de l'élégance islamique : vert, or, bleu nuit
class AppTheme {
  static const Color primaryGreen = Color(0xFF0D6B4C);
  static const Color accentGold = Color(0xFFD4A853);
  static const Color darkNavy = Color(0xFF1A2B3D);
  static const Color cream = Color(0xFFF5F0E8);

  static const Color darkGreen = Color(0xFF0B2E25);
  static const Color white = Color(0xFFFFFFFF);
  static const Color creamLight = Color(0xFFFAF8F5);
  static const Color mushafWomenRose = Color(0xFFE91E63);
  static const Color mushafWomenBlue = Color(0xFF03A9F4);
  static const Color mushafWomenCream = Color(0xFFFDF5F8);
  static const Color customNameColor = Color(0xFFFF6D00);
  static const Color hizbReservedBadge = Color(0xFF39FF14);

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primaryGreen,
        brightness: Brightness.light,
        primary: primaryGreen,
        secondary: accentGold,
      ),
      scaffoldBackgroundColor: cream,
      appBarTheme: const AppBarTheme(
        elevation: 0,
        centerTitle: true,
        backgroundColor: primaryGreen,
        foregroundColor: Colors.white,
        systemOverlayStyle: SystemUiOverlayStyle.light,
      ),
      cardTheme: CardThemeData(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        color: Colors.white,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryGreen,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        selectedItemColor: primaryGreen,
        unselectedItemColor: Colors.grey,
        type: BottomNavigationBarType.fixed,
      ),
    );
  }

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primaryGreen,
        brightness: Brightness.dark,
        primary: primaryGreen,
        secondary: accentGold,
        surface: darkNavy,
      ),
      scaffoldBackgroundColor: darkNavy,
      appBarTheme: const AppBarTheme(
        elevation: 0,
        centerTitle: true,
        backgroundColor: darkNavy,
        foregroundColor: Colors.white,
      ),
      cardTheme: CardThemeData(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        color: const Color(0xFF243447),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryGreen,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        selectedItemColor: accentGold,
        unselectedItemColor: Colors.grey,
        backgroundColor: darkNavy,
        type: BottomNavigationBarType.fixed,
      ),
    );
  }
}
