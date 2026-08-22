import 'package:flutter/material.dart';

import '../anis_theme.dart';
import '../tokens/anis_effects.dart';
import '../tokens/anis_geometry.dart';

/// Rub' el hizb (U+06DE) — même point de code que `kRubElHizbGlyph` du lecteur
/// Mushaf, redéclaré ici pour que le design system ne dépende pas des écrans.
///
/// Ce glyphe est déjà rendu en production par `MushafHizbBadge` avec les polices
/// d'interface de l'application : son affichage est donc vérifié.
const String kAnisSignatureGlyph = '\u06DE';

/// Rôle sémantique d'une marque de signature.
///
/// La géométrie du rub' el hizb (۞) est la signature secondaire d'ANIS. Elle
/// n'est pas un ornement libre : elle **désigne toujours un repère de lecture**
/// — un Hizb, une Khatma, une progression, un accomplissement.
///
/// Elle est donc interdite en décoration de fond, en séparateur, en puce de
/// liste ou en remplissage d'espace vide. Sur un écran donné, deux occurrences
/// suffisent.
enum AnisSignatureRole {
  /// Marque d'identité, en tête d'écran.
  brand,

  /// Repère de Hizb ou de Khatma accolé à une donnée.
  marker,

  /// Accomplissement.
  accomplishment,
}

/// Marque de signature ANIS — le glyphe ۞ tokenisé.
///
/// Purement décoratif du point de vue de l'accessibilité : le glyphe est exclu
/// de l'arbre sémantique, car un lecteur d'écran qui énonce « ornement arabe »
/// avant chaque numéro de Hizb dégrade la lecture.
class AnisSignatureMark extends StatelessWidget {
  const AnisSignatureMark({
    super.key,
    this.role = AnisSignatureRole.marker,
    this.size,
    this.color,
  });

  final AnisSignatureRole role;
  final double? size;
  final Color? color;

  double get _size {
    if (size != null) return size!;
    switch (role) {
      case AnisSignatureRole.brand:
        return AnisIconSize.md;
      case AnisSignatureRole.marker:
        return AnisIconSize.sm;
      case AnisSignatureRole.accomplishment:
        return AnisIconSize.lg;
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.anisColors;
    return ExcludeSemantics(
      child: Text(
        kAnisSignatureGlyph,
        style: TextStyle(
          fontSize: _size,
          height: 1,
          color: color ?? colors.accentGold,
        ),
        // Le glyphe ne doit jamais suivre l'échelle de texte : il est aligné
        // sur des icônes, pas sur du contenu lisible.
        textScaler: TextScaler.noScaling,
      ),
    );
  }
}

/// Pastille de signature : le glyphe dans un cercle de menthe légère.
///
/// Sert de marque d'identité en tête d'écran et de repère d'accomplissement.
class AnisSignatureBadge extends StatelessWidget {
  const AnisSignatureBadge({
    super.key,
    this.role = AnisSignatureRole.brand,
    this.diameter = 40,
  });

  final AnisSignatureRole role;
  final double diameter;

  @override
  Widget build(BuildContext context) {
    final colors = context.anisColors;
    return Container(
      width: diameter,
      height: diameter,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: colors.actionPrimary.withValues(alpha: AnisOpacity.subtleFill),
        border: Border.all(
          color: colors.accentGold.withValues(alpha: AnisOpacity.mediumFill),
        ),
      ),
      alignment: Alignment.center,
      child: AnisSignatureMark(
        role: role,
        size: diameter * 0.5,
        color: colors.accentGoldText,
      ),
    );
  }
}
