import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Palette HOME — AppTheme (vert foncé, or, crème).
/// Design haut de gamme : simplicité, confiance, spiritualité.
class HomeColors {
  HomeColors._();

  // ── Primaire (charte graphique ANIS)
  static const Color primary = AppTheme.primaryGreen;
  static const Color primaryDark = AppTheme.darkGreen;
  static const Color primaryLight = Color(0xFFE8F5F0);

  // ── Accents
  static const Color accentGold = AppTheme.accentGold;

  // ── Surfaces
  static const Color surface = AppTheme.creamLight;
  static const Color card = AppTheme.white;
  static const Color white = AppTheme.white;

  // ── Texte
  static const Color textPrimary = Color(0xFF1A2A22);
  static const Color textSecondary = Color(0xFF6B7B73);
  static const Color textMuted = Color(0xFF9CA8A2);

  // ── Utilitaires
  static const Color divider = Color(0xFFE8EDEA);
  static const Color success = Color(0xFF0E5E46);

  // ── Avatars (tons verts raffinés)
  static const List<Color> avatarColors = [
    Color(0xFFA7C4BC),
    Color(0xFF8B9D94),
    Color(0xFF9CAF88),
    Color(0xFFB8C9B8),
  ];

  // ── Ombres Stitch AI (douces, multicouches, premium)
  static const List<BoxShadow> cardShadow = [
    BoxShadow(
      color: Color(0x06000000),
      blurRadius: 30,
      offset: Offset(0, 8),
    ),
    BoxShadow(
      color: Color(0x04000000),
      blurRadius: 12,
      offset: Offset(0, 4),
    ),
  ];

  static const List<BoxShadow> softShadow = [
    BoxShadow(
      color: Color(0x08000000),
      blurRadius: 24,
      offset: Offset(0, 6),
    ),
  ];

  // ── Style Stitch AI (radius généreux)
  static const double radiusCard = 28.0;
  static const double radiusIconBlock = 24.0;
  static const double radiusButton = 20.0;
}
