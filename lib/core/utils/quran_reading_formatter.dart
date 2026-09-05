library;

/// Utilitaires de formatage pour les plans de lecture du Quran.

/// Formate un nombre de Rub' en langage Quran-reader.
///
/// **Règles :**
/// - 4 Rub' = 1 Hizb
/// - 8 Rub' = 2 Hizb
/// - 9 Rub' = 2 Hizb + ¼
/// - Jamais de décimales (ex: "0.8 Hizb")
///
/// **Exemples :**
/// - formatRubsAsReadingPace(1, 'fr') → "¼ Hizb"
/// - formatRubsAsReadingPace(4, 'fr') → "1 Hizb"
/// - formatRubsAsReadingPace(6, 'fr') → "1 Hizb + ½"
/// - formatRubsAsReadingPace(9, 'fr') → "2 Hizb + ¼"
String formatRubsAsReadingPace(int rubs, String locale) {
  if (rubs <= 0) return '0';
  
  final fullHizbs = rubs ~/ 4;
  final remainingRubs = rubs % 4;
  
  final parts = <String>[];
  
  // Full Hizb(s)
  if (fullHizbs > 0) {
    parts.add('$fullHizbs Hizb${fullHizbs > 1 ? 's' : ''}');
  }
  
  // Fractional Rub'
  if (remainingRubs > 0) {
    final fraction = _formatRubFraction(remainingRubs);
    if (fullHizbs > 0) {
      parts.add('+ $fraction');
    } else {
      parts.add(fraction);
    }
  }
  
  return parts.join(' ');
}

/// Formate 1-3 Rub' en fraction d'un Hizb.
String _formatRubFraction(int rubs) {
  switch (rubs) {
    case 1:
      return '¼ Hizb';
    case 2:
      return '½ Hizb';
    case 3:
      return '¾ Hizb';
    default:
      return '$rubs Rub\'${rubs > 1 ? 's' : ''}';
  }
}

/// Formate un pace quotidien pour affichage.
///
/// **Exemples :**
/// - formatDailyPace(8, 'fr') → "8 Rub' / jour (2 Hizb)"
/// - formatDailyPace(5, 'fr') → "5 Rub' / jour (1 Hizb + ¼)"
String formatDailyPace(int rubsPerDay, String locale) {
  final readable = formatRubsAsReadingPace(rubsPerDay, locale);
  return '$rubsPerDay Rub\' / jour ($readable)';
}
