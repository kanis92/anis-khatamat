import 'package:flutter/material.dart';

/// Échelle d'élévation.
///
/// La direction artistique demande des ombres « extrêmement douces » : une
/// seule couche, très diffuse, très transparente. Le relief vient du trait et
/// du contraste de surface, pas de l'ombre — ce qui coûte aussi moins cher au
/// GPU que les ombres multicouches de l'ancienne palette Home.
class AnisElevation {
  AnisElevation._();

  static const List<BoxShadow> none = <BoxShadow>[];

  /// Élément posé : tuiles, lignes de liste, pastilles.
  static List<BoxShadow> subtle(Color shadow) => [
        BoxShadow(
          color: shadow.withValues(alpha: 0.04),
          blurRadius: 8,
          offset: const Offset(0, 2),
        ),
      ];

  /// Carte standard.
  static List<BoxShadow> soft(Color shadow) => [
        BoxShadow(
          color: shadow.withValues(alpha: 0.05),
          blurRadius: 18,
          offset: const Offset(0, 6),
        ),
      ];

  /// Carte principale d'un écran, élément qui doit se détacher franchement.
  static List<BoxShadow> raised(Color shadow) => [
        BoxShadow(
          color: shadow.withValues(alpha: 0.07),
          blurRadius: 28,
          offset: const Offset(0, 10),
        ),
      ];
}

/// Opacités nommées.
///
/// Interdit d'écrire `withValues(alpha: 0.23)` dans un écran : si un besoin
/// n'est pas couvert ici, c'est le token qui doit évoluer.
class AnisOpacity {
  AnisOpacity._();

  /// Élément désactivé.
  static const double disabled = 0.38;

  /// Survol / pression sur une surface claire.
  static const double pressed = 0.08;
  static const double hover = 0.04;

  /// Remplissage très léger derrière une icône ou un badge.
  static const double subtleFill = 0.08;

  /// Remplissage moyen (état actif discret).
  static const double mediumFill = 0.14;

  /// Voile modal.
  static const double scrim = 0.32;

  /// Trait décoratif posé sur une surface pleine.
  static const double onInverseTrack = 0.25;
}
