import 'package:flutter/foundation.dart';

/// Référence canonique d'un des 60 Hizb du Mushaf Hafs 604 pages.
///
/// Les valeurs sont figées depuis Quran Foundation Content API v4
/// (`/verses/by_hizb/{hizb_number}`), puis vérifiées contre le JSON Hafs
/// réellement rendu par l'application.
@immutable
class HizbCanonicalRef {
  const HizbCanonicalRef({
    required this.hizbNumber,
    required this.juzNumber,
    required this.startSurah,
    required this.startAyah,
    required this.endSurah,
    required this.endAyah,
    required this.startPageHafs,
    required this.endPageHafs,
  });

  final int hizbNumber;
  final int juzNumber;
  final int startSurah;
  final int startAyah;
  final int endSurah;
  final int endAyah;
  final int startPageHafs;
  final int endPageHafs;

  String get startRef => '$startSurah:$startAyah';
  String get endRef => '$endSurah:$endAyah';
  String get rangeLabel => '$startRef – $endRef';

  bool containsAyah(int surah, int ayah) {
    if (surah < startSurah || (surah == startSurah && ayah < startAyah)) {
      return false;
    }
    if (surah > endSurah || (surah == endSurah && ayah > endAyah)) {
      return false;
    }
    return true;
  }
}
