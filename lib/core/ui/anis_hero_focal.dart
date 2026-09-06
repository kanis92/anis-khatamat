import 'package:flutter/painting.dart';

/// Géométrie intrinsèque du hero `assets/images/anis_header.png`.
///
/// Asset mesuré : 1074 × 504 (ratio ≈ 2.13).
/// Sujet (marque A + ANIS + Mushaf + orbite or) **centré** dans l'image.
/// Les bords sont du fond teal + étincelles / flare — pas de texte intégré.
///
/// FR/EN : plein cadre [BoxFit.cover] + [ltr], composition déjà validée.
/// AR : ne pas recadrer par Alignment. On compose deux régions physiques
/// (logo à gauche, salut à droite) pour qu'elles ne puissent pas se chevaucher.
class AnisHeroFocal {
  AnisHeroFocal._();

  static const Size assetSize = Size(1074, 504);

  /// Alignment LTR validé : sujet centré, légèrement haut.
  static const Alignment ltr = Alignment(0, -0.15);

  /// Part de largeur physique réservée à la marque (AR).
  static const int arabicLogoFlex = 5;

  /// Part de largeur physique réservée au salut / date / prière (AR).
  static const int arabicCopyFlex = 6;

  static bool usesSplitComposition(String languageCode) =>
      languageCode == 'ar';
}
