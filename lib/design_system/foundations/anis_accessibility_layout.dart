import 'package:flutter/material.dart';

/// Palier de mise en page selon l'échelle de texte système.
///
/// Basé sur [TextScaler] (référence 12 pt) — sans clamp global ni réduction
/// de l'accessibilité utilisateur.
enum AnisAccessibilityTextMode { normal, large, extreme }

/// Seuils sémantiques partagés par l'en-tête, la navigation et le scaffold.
abstract final class AnisAccessibilityLayout {
  AnisAccessibilityLayout._();

  static const double _referenceSize = 12;
  static const double _largeThreshold = 15;
  static const double _extremeThreshold = 20;

  static AnisAccessibilityTextMode modeOf(BuildContext context) {
    final scaled = MediaQuery.textScalerOf(context).scale(_referenceSize);
    if (scaled >= _extremeThreshold) return AnisAccessibilityTextMode.extreme;
    if (scaled >= _largeThreshold) return AnisAccessibilityTextMode.large;
    return AnisAccessibilityTextMode.normal;
  }

  static bool isLargeOrAbove(BuildContext context) =>
      modeOf(context) != AnisAccessibilityTextMode.normal;

  static bool isExtreme(BuildContext context) =>
      modeOf(context) == AnisAccessibilityTextMode.extreme;
}
