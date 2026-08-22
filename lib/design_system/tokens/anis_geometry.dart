import 'package:flutter/material.dart';

/// Échelle d'espacement — base 4, progression resserrée en bas d'échelle.
///
/// L'audit relevait 21 valeurs d'espacement distinctes dans `lib/`. Cette
/// échelle en compte 8 : tout écart doit se justifier par un token, pas par un
/// nombre écrit à la main.
class AnisSpacing {
  AnisSpacing._();

  /// 2 — séparation typographique interne (label ↔ valeur).
  static const double xxs = 2;

  /// 4 — collage d'éléments liés (icône ↔ texte court).
  static const double xs = 4;

  /// 8 — respiration minimale entre deux éléments distincts.
  static const double sm = 8;

  /// 12 — écart standard entre lignes d'un même bloc.
  static const double md = 12;

  /// 16 — padding intérieur des surfaces compactes.
  static const double lg = 16;

  /// 20 — padding horizontal de page, padding des cartes principales.
  static const double xl = 20;

  /// 24 — séparation entre deux sections.
  static const double xxl = 24;

  /// 32 — respiration ample (haut de page, blocs isolés).
  static const double xxxl = 32;

  /// Marge horizontale de page. Constante sur toute l'application.
  static const double page = xl;

  /// Écart vertical entre deux blocs consécutifs d'une page.
  static const double blockGap = lg;

  /// Écart vertical entre deux sections de page.
  static const double sectionGap = xxl;

  /// Réserve basse pour ne jamais coller la nav basse.
  static const double bottomSafe = xxxl;
}

/// Échelle de rayons.
///
/// L'audit relevait 13 rayons distincts, dont un rayon dominant (12) qui
/// n'était tokenisé nulle part. L'échelle en retient 5.
class AnisRadius {
  AnisRadius._();

  /// 10 — pastilles, petits blocs d'icône.
  static const double sm = 10;

  /// 14 — surfaces compactes, tuiles de métrique, champs.
  static const double md = 14;

  /// 20 — cartes standard, boutons pleine largeur.
  static const double lg = 20;

  /// 28 — carte principale d'un écran, feuilles.
  static const double xl = 28;

  /// Capsule.
  static const double pill = 999;

  static BorderRadius get smAll => BorderRadius.circular(sm);
  static BorderRadius get mdAll => BorderRadius.circular(md);
  static BorderRadius get lgAll => BorderRadius.circular(lg);
  static BorderRadius get xlAll => BorderRadius.circular(xl);
  static BorderRadius get pillAll => BorderRadius.circular(pill);
}

/// Épaisseurs de trait.
///
/// La direction artistique repose sur des bordures subtiles plutôt que sur des
/// ombres marquées : le trait porte la séparation, l'ombre porte l'élévation.
class AnisBorder {
  AnisBorder._();

  /// Trait de séparation standard.
  static const double hairline = 1;

  /// Trait d'emphase (état sélectionné, bordure porteuse de sens).
  static const double emphasis = 1.5;

  /// Anneau de focus clavier / lecteur d'écran.
  static const double focus = 2;

  static Border all(Color color, {double width = hairline}) =>
      Border.all(color: color, width: width);
}

/// Tailles d'icônes.
///
/// L'audit relevait 15 tailles distinctes sur 311 occurrences. L'échelle en
/// retient 5, plus la contrainte de cible tactile.
class AnisIconSize {
  AnisIconSize._();

  /// 16 — icône accolée à du texte secondaire.
  static const double sm = 16;

  /// 20 — icône dans une ligne de liste, un bouton.
  static const double md = 20;

  /// 24 — icône de navigation, action d'en-tête.
  static const double lg = 24;

  /// 32 — icône d'accès rapide, bloc illustré compact.
  static const double xl = 32;

  /// 48 — illustration d'état vide.
  static const double illustration = 48;

  /// Cible tactile minimale imposée par le design system.
  ///
  /// Aucun élément interactif ANIS ne descend sous cette valeur, quelle que
  /// soit la taille de l'icône qu'il contient.
  static const double minTapTarget = 48;
}
