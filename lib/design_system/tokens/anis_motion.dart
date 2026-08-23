import 'package:flutter/material.dart';

/// Échelle de mouvement ANIS.
///
/// Quatre durées, deux courbes. Le mouvement sert la continuité, l'orientation,
/// le retour d'action et la progression — jamais la décoration.
///
/// Toute animation doit passer par [durationOf] ou [isReduced] afin de
/// respecter le réglage système « Réduire les animations ». C'est la seule
/// façon fiable de le faire dans Flutter : `MediaQuery.disableAnimations`
/// reflète directement l'option d'accessibilité de la plateforme.
class AnisMotion {
  AnisMotion._();

  /// 90 ms — retour immédiat sur pression, changement d'état binaire.
  static const Duration instant = Duration(milliseconds: 90);

  /// 160 ms — apparition d'un élément local, bascule d'indicateur.
  static const Duration fast = Duration(milliseconds: 160);

  /// 240 ms — transition standard d'un bloc, entrée de contenu.
  static const Duration standard = Duration(milliseconds: 240);

  /// 360 ms — moment porteur de sens (progression, accomplissement).
  static const Duration emphasis = Duration(milliseconds: 360);

  /// Entrée de contenu : décélération franche, sans rebond.
  static const Curve enter = Curves.easeOutCubic;

  /// Transition réversible (ouverture / fermeture d'un même état).
  static const Curve reversible = Curves.easeInOut;

  /// Vrai si l'utilisateur a demandé la réduction des animations.
  static bool isReduced(BuildContext context) =>
      MediaQuery.maybeOf(context)?.disableAnimations ?? false;

  /// Durée effective : `Duration.zero` quand les animations sont réduites.
  ///
  /// Un `AnimatedContainer` avec une durée nulle applique l'état final
  /// immédiatement, ce qui préserve le résultat visuel sans le mouvement.
  static Duration durationOf(BuildContext context, Duration duration) =>
      isReduced(context) ? Duration.zero : duration;
}
