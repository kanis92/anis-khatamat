/// Catégories éditoriales du recueil Ayat Fadila.
enum AyatFadilaCategory {
  protection,
  daily,
  praise,
}

/// Entrée du catalogue (contenu statique V1 — PDF plus tard).
class AyatFadilaEntry {
  const AyatFadilaEntry({
    required this.id,
    required this.category,
    required this.featured,
    required this.openSurah,
    required this.openVerse,
  });

  final String id;
  final AyatFadilaCategory category;
  final bool featured;

  /// Ouverture Mushaf (sourate / verset de départ).
  final int openSurah;
  final int openVerse;
}
