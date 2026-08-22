import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../design_system/anis_theme.dart';
import '../providers/font_provider.dart';

/// Thème de l'application ANIS — La Compagnie du Coran
/// Palette officielle : Simplicité • Confiance • Spiritualité
/// Couleurs de la charte graphique
class AppTheme {
  /// Vert foncé principal — #0E5E46
  static const Color primaryGreen = Color(0xFF0E5E46);
  /// Or — #D4AF37 (accents, icônes, highlights)
  static const Color accentGold = Color(0xFFD4AF37);
  /// Vert très foncé — #0B2E25 (fond sombre, gradient)
  static const Color darkGreen = Color(0xFF0B2E25);
  /// Blanc — #FFFFFF
  static const Color white = Color(0xFFFFFFFF);
  /// Rétrocompatibilité
  static const Color darkNavy = Color(0xFF0B2E25);
  static const Color cream = Color(0xFFF5F0E8);
  /// Crème très léger (fond clair)
  static const Color creamLight = Color(0xFFFAF8F5);
  /// Pour gradient AppBar (vert principal → vert foncé)
  static const Color teal = Color(0xFF0B2E25);

  /// Thème Mushaf pour femmes — rose vif et bleu clair vif
  static const Color mushafWomenRose = Color(0xFFE91E63);   // Rose vif (Material Pink)
  static const Color mushafWomenBlue = Color(0xFF03A9F4);   // Bleu clair vif (Material Light Blue)
  static const Color mushafWomenCream = Color(0xFFFDF5F8);

  /// Couleur pour les noms personnalisés (réservation pour autrui, sans compte)
  static const Color customNameColor = Color(0xFFFF6D00); // Orange vif

  /// Badge Hizb réservé — fluorescent pour distinguer visuellement
  static const Color hizbReservedBadge = Color(0xFF39FF14); // Vert fluorescent

  /// Fond pour les zones de texte arabe (parchemin / manuscrit)
  static const Color arabicBackground = Color(0xFFF5F0E8);

  /// Construit la TextTheme selon la police sélectionnée
  static TextTheme _buildTextTheme(AppFont font, TextTheme base) {
    switch (font) {
      case AppFont.cairo:
        return GoogleFonts.cairoTextTheme(base);
      case AppFont.tajawal:
        return GoogleFonts.tajawalTextTheme(base);
      case AppFont.readexPro:
        return GoogleFonts.readexProTextTheme(base);
      case AppFont.almarai:
        return GoogleFonts.almaraiTextTheme(base);
    }
  }

  /// Police arabe religieuse (Amiri — style naskhi, texte du douaa/Coran)
  /// Indépendante du choix UI car c'est un texte sacré
  static TextStyle arabicTextStyle({
    double fontSize = 20,
    FontWeight fontWeight = FontWeight.normal,
    Color? color,
    double height = 1.7,
  }) =>
      GoogleFonts.amiri(
        fontSize: fontSize,
        fontWeight: fontWeight,
        color: color,
        height: height,
      );

  /// Police arabe pour les noms, listes et éléments UI arabes
  /// Utilise la police sélectionnée (Cairo par défaut)
  static TextStyle arabicUiStyle({
    AppFont font = AppFont.cairo,
    double fontSize = 16,
    FontWeight fontWeight = FontWeight.normal,
    Color? color,
    double height = 1.5,
  }) {
    switch (font) {
      case AppFont.cairo:
        return GoogleFonts.cairo(
            fontSize: fontSize, fontWeight: fontWeight, color: color, height: height);
      case AppFont.tajawal:
        return GoogleFonts.tajawal(
            fontSize: fontSize, fontWeight: fontWeight, color: color, height: height);
      case AppFont.readexPro:
        return GoogleFonts.readexPro(
            fontSize: fontSize, fontWeight: fontWeight, color: color, height: height);
      case AppFont.almarai:
        return GoogleFonts.almarai(
            fontSize: fontSize, fontWeight: fontWeight, color: color, height: height);
    }
  }

  /// Retourne un TextStyle dans la police donnée (pour les aperçus)
  static TextStyle sampleStyle(AppFont font, {double fontSize = 16}) {
    switch (font) {
      case AppFont.cairo:
        return GoogleFonts.cairo(fontSize: fontSize);
      case AppFont.tajawal:
        return GoogleFonts.tajawal(fontSize: fontSize);
      case AppFont.readexPro:
        return GoogleFonts.readexPro(fontSize: fontSize);
      case AppFont.almarai:
        return GoogleFonts.almarai(fontSize: fontSize);
    }
  }

  // ─── Thèmes dynamiques ────────────────────────────────────────────────────

  static ThemeData buildLightTheme(AppFont font) {
    final base = ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primaryGreen,
        brightness: Brightness.light,
        primary: primaryGreen,
        secondary: accentGold,
      ),
    );
    return base.copyWith(
      textTheme: _buildTextTheme(font, base.textTheme).copyWith(
        titleLarge: _buildTextTheme(font, base.textTheme).titleLarge?.copyWith(fontWeight: FontWeight.w800),
        titleMedium: _buildTextTheme(font, base.textTheme).titleMedium?.copyWith(fontWeight: FontWeight.w700),
      ),
      iconTheme: IconThemeData(color: Colors.grey[700], size: 24),
      scaffoldBackgroundColor: creamLight, // Fond très clair pour faire ressortir les cartes blanches
      appBarTheme: const AppBarTheme(
        elevation: 0,
        centerTitle: true,
        backgroundColor: primaryGreen,
        foregroundColor: Colors.white,
        systemOverlayStyle: SystemUiOverlayStyle.light,
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: Colors.black.withValues(alpha: 0.05)),
        ),
        color: Colors.white,
        surfaceTintColor: Colors.transparent,
        margin: EdgeInsets.zero,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryGreen,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.grey[50],
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        selectedItemColor: primaryGreen,
        unselectedItemColor: Colors.grey,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
      ),
      // Tokens du design system ANIS. Purement additif : les thèmes de
      // composants Material ci-dessus restent inchangés, donc les écrans non
      // encore migrés conservent exactement leur apparence actuelle.
      extensions: AnisThemeExtensions.light(font),
    );
  }

  static ThemeData buildDarkTheme(AppFont font) {
    final base = ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primaryGreen,
        brightness: Brightness.dark,
        primary: primaryGreen,
        secondary: accentGold,
        surface: const Color(0xFF071A15), // Fond encore plus sombre
      ),
    );
    return base.copyWith(
      textTheme: _buildTextTheme(font, base.textTheme).copyWith(
        titleLarge: _buildTextTheme(font, base.textTheme).titleLarge?.copyWith(fontWeight: FontWeight.w800),
        titleMedium: _buildTextTheme(font, base.textTheme).titleMedium?.copyWith(fontWeight: FontWeight.w700),
      ),
      iconTheme: IconThemeData(color: Colors.grey[400], size: 24),
      scaffoldBackgroundColor: const Color(0xFF071A15),
      appBarTheme: const AppBarTheme(
        elevation: 0,
        centerTitle: true,
        backgroundColor: darkNavy,
        foregroundColor: Colors.white,
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: Colors.white.withValues(alpha: 0.06)),
        ),
        color: const Color(0xFF0D2921),
        surfaceTintColor: Colors.transparent,
        margin: EdgeInsets.zero,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryGreen,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFF0D2921),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        selectedItemColor: accentGold,
        unselectedItemColor: Colors.grey,
        backgroundColor: Color(0xFF071A15),
        type: BottomNavigationBarType.fixed,
        elevation: 0,
      ),
      extensions: AnisThemeExtensions.dark(font),
    );
  }

  // Rétrocompatibilité — utilisent Cairo par défaut
  static ThemeData get lightTheme => buildLightTheme(AppFont.cairo);
  static ThemeData get darkTheme => buildDarkTheme(AppFont.cairo);
}
