import '../models/khatma.dart';
import 'my_khatmat_utils.dart';

enum KhatmaExperience { collaborative, classic }

/// Choisit l'écran de détail selon le mode Khatma (source unique).
KhatmaExperience khatmaExperienceFor(Khatma khatma) {
  return khatma.reservationMode
      ? KhatmaExperience.collaborative
      : KhatmaExperience.classic;
}

/// Valide un objet préchargé (GoRouter `extra`) : même ID uniquement.
Khatma? validatePreloadedKhatma(Khatma? preloaded, String expectedId) {
  if (preloaded == null || expectedId.isEmpty) return null;
  if (preloaded.id != expectedId) return null;
  return preloaded;
}

/// L'utilisateur appartient déjà à la Khatma (redirect join → détail).
bool userAlreadyInKhatma(
  Khatma khatma, {
  String? email,
  String? authUid,
}) {
  return userBelongsToKhatma(khatma, email: email, authUid: authUid);
}

/// Fusionne seed (extra), fetch initial et stream temps réel.
Khatma? resolveKhatmaSnapshot({
  required String khatmaId,
  Khatma? preloaded,
  Khatma? fetched,
  Khatma? streamed,
}) {
  if (streamed != null && streamed.id == khatmaId) return streamed;
  if (fetched != null && fetched.id == khatmaId) return fetched;
  return validatePreloadedKhatma(preloaded, khatmaId);
}

/// Routes `/khatma/:id` et sous-routes (hors onglet `/khatma` et distribute).
bool isKhatmaDeepLinkRoute(String location) {
  if (location == '/khatma' || location.startsWith('/khatma?')) return false;
  if (location == '/khatma/distribute') return false;
  return location.startsWith('/khatma/');
}
