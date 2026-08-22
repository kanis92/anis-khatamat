import 'package:flutter/material.dart';

import '../core/providers/font_provider.dart';
import 'tokens/anis_colors.dart';
import 'tokens/anis_typography.dart';

/// Extensions de thème du design system ANIS.
///
/// Le DS s'installe comme `ThemeExtension` plutôt que comme singleton statique :
/// c'est ce qui permettra au mode sombre de basculer sans qu'aucun écran ne
/// contienne de test de `brightness`.
class AnisThemeExtensions {
  AnisThemeExtensions._();

  static List<ThemeExtension<dynamic>> light(AppFont font) {
    final colors = AnisColors.light();
    return [colors, AnisTypography.fromFont(font, colors)];
  }

  static List<ThemeExtension<dynamic>> dark(AppFont font) {
    final colors = AnisColors.dark();
    return [colors, AnisTypography.fromFont(font, colors)];
  }
}

/// Accès aux tokens depuis un `BuildContext`.
///
/// `context.anisColors.actionPrimary` remplace toute couleur écrite en dur.
extension AnisThemeAccess on BuildContext {
  AnisColors get anisColors => AnisColors.of(this);

  AnisTypography get anisText => AnisTypography.of(this);
}
