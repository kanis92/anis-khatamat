import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Politique haptique centrale.
///
/// L'application n'avait aucun retour haptique. La règle retenue est
/// volontairement restrictive : **le retour tactile marque un engagement, pas
/// un tap**. Naviguer, ouvrir une carte ou dérouler une liste ne vibre pas.
///
/// | Intention | Méthode | Usage prévu |
/// |---|---|---|
/// | Choisir | [selection] | sélection d'un Hizb dans la grille |
/// | Confirmer | [confirm] | réservation enregistrée, objectif défini |
/// | Accomplir | [milestone] | Hizb terminé, Khatma 60/60 |
/// | Refuser | [reject] | action impossible (Hizb déjà pris) |
///
/// Les appels sont sans effet hors iOS et Android : inutile de tester la
/// plateforme dans les écrans.
class AnisHaptics {
  AnisHaptics._();

  /// Coupe-circuit global, utile en test et pour un futur réglage utilisateur.
  static bool enabled = true;

  static bool get _supported =>
      !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.iOS ||
          defaultTargetPlatform == TargetPlatform.android);

  static void _fire(Future<void> Function() effect) {
    if (!enabled || !_supported) return;
    // Le canal haptique échoue silencieusement quand le matériel ne le gère
    // pas : on ne veut jamais qu'un retour tactile fasse remonter une erreur.
    effect().catchError((_) {});
  }

  /// Choix léger dans un ensemble d'options.
  static void selection() => _fire(HapticFeedback.selectionClick);

  /// Action engageante réussie.
  static void confirm() => _fire(HapticFeedback.mediumImpact);

  /// Accomplissement marquant. À réserver aux vrais jalons.
  static void milestone() => _fire(HapticFeedback.heavyImpact);

  /// Action refusée.
  static void reject() => _fire(HapticFeedback.lightImpact);
}
