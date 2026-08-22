import 'package:flutter/foundation.dart';

/// Référence canonique d'un Hizb du Coran.
/// Source unique de vérité — toujours obtenue via [HizbIndexRepository].
///
/// [pageHafs] est la page du Mushaf Hafs 604 pages effectivement rendu par
/// le lecteur. [pageWarsh] est un alias de compatibilité non certifié et ne
/// doit jamais servir à piloter le lecteur.
@immutable
class HizbRef {
  /// Numéro du Hizb (1–60)
  final int hizbNumber;

  /// Sourate de départ (1–114)
  final int surah;

  /// Verset de départ
  final int ayah;

  /// Sourate du dernier verset du Hizb
  final int endSurah;

  /// Dernier verset du Hizb
  final int endAyah;

  /// Page dans le Mushaf Hafs / Madina (604 pages)
  final int pageHafs;

  /// Dernière page couverte dans le Mushaf Hafs / Madina.
  final int endPageHafs;

  /// Alias de compatibilité ; aucune pagination Warsh n'est certifiée ici.
  final int pageWarsh;

  /// Premiers mots du verset de départ en arabe
  final String incipitAr;

  /// Numéro du Juz (1–30)
  final int juz;

  /// Plage surah:ayah utilisée par FlutterQuran().navigateToHizb()
  /// Format : 'startSurah:startAyah - endSurah:endAyah'
  final String rangeStr;

  const HizbRef({
    required this.hizbNumber,
    required this.surah,
    required this.ayah,
    required this.endSurah,
    required this.endAyah,
    required this.pageHafs,
    required this.endPageHafs,
    required this.pageWarsh,
    required this.incipitAr,
    required this.juz,
    required this.rangeStr,
  }) : assert(hizbNumber >= 1 && hizbNumber <= 60),
       assert(surah >= 1 && surah <= 114),
       assert(ayah >= 1),
       assert(endSurah >= 1 && endSurah <= 114),
       assert(endAyah >= 1),
       assert(pageHafs >= 1 && pageHafs <= 604),
       assert(endPageHafs >= pageHafs && endPageHafs <= 604),
       assert(juz >= 1 && juz <= 30);

  /// Vrai si le verset [s]:[a] appartient à ce Hizb (bornes incluses).
  bool containsAyah(int s, int a) {
    if (s < surah || (s == surah && a < ayah)) return false;
    if (s > endSurah || (s == endSurah && a > endAyah)) return false;
    return true;
  }

  @override
  String toString() =>
      'HizbRef($hizbNumber: $surah:$ayah p$pageHafs "$incipitAr")';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is HizbRef && other.hizbNumber == hizbNumber;

  @override
  int get hashCode => hizbNumber.hashCode;
}
