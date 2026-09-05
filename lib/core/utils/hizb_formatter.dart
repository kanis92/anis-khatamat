/// Utilitaires de formatage pour progression en Hizb.
///
/// Rub' reste l'unité canonique interne (tracking, allocation, boundaries).
/// Hizb est l'unité user-facing préférée:
/// - 240 Rub' = 60 Hizb
/// - 4 Rub' = 1 Hizb
/// - 1 Rub' = ¼ Hizb
///
/// Principe: exposer des fractions exactes (¼, ½, ¾) jamais de décimales.
library;

/// Convertit un nombre de Rub' en Hizb avec fractions exactes.
///
/// Exemples:
/// - 0 Rub' → "0"
/// - 1 Rub' → "¼"
/// - 2 Rub' → "½"
/// - 3 Rub' → "¾"
/// - 4 Rub' → "1"
/// - 5 Rub' → "1¼"
/// - 49 Rub' → "12¼"
/// - 240 Rub' → "60"
String formatRubsAsHizb(int rubs) {
  if (rubs == 0) return '0';

  final fullHizbs = rubs ~/ 4;
  final remainingRubs = rubs % 4;

  if (remainingRubs == 0) {
    return '$fullHizbs';
  }

  final fraction = _formatRubFraction(remainingRubs);
  return fullHizbs == 0 ? fraction : '$fullHizbs$fraction';
}

/// Formate un progrès partiel en Hizb.
///
/// Exemples:
/// - (0, 240) → "0 / 60 Hizb"
/// - (4, 240) → "1 / 60 Hizb"
/// - (49, 240) → "12¼ / 60 Hizb"
/// - (240, 240) → "60 / 60 Hizb"
String formatProgressAsHizb(int completed, int total) {
  final completedHizb = formatRubsAsHizb(completed);
  final totalHizb = formatRubsAsHizb(total);
  return '$completedHizb / $totalHizb Hizb';
}

/// Objectif quotidien user-facing, fractions exactes.
///
/// Exemples: 8 → "2 Hizb", 10 → "2½ Hizb", 1 → "¼ Hizb"
String formatTargetAsHizb(int rubs) => '${formatRubsAsHizb(rubs)} Hizb';

/// Reste du jour, même langage que [formatTargetAsHizb].
String? formatRemainingAsHizb(int remainingRubs) {
  if (remainingRubs <= 0) return null;
  return 'Il vous reste ${formatRubsAsHizb(remainingRubs)} Hizb';
}

String _formatRubFraction(int rubs) {
  switch (rubs) {
    case 1:
      return '¼';
    case 2:
      return '½';
    case 3:
      return '¾';
    default:
      return '';
  }
}
