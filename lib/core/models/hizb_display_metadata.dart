import '../constants/hizb_definitions.dart';
import '../data/quran_subdivision_data.dart';
import '../repositories/hizb_index_repository.dart';

/// Métadonnées d'affichage d'un Hizb, dérivées exclusivement des sources
/// canoniques de navigation et du catalogue existant des 114 sourates.
class HizbDisplayMetadata {
  const HizbDisplayMetadata({
    required this.hizbNumber,
    required this.juzNumber,
    required this.startSurah,
    required this.startAyah,
    required this.endSurah,
    required this.endAyah,
    required this.startPageHafs,
    required this.endPageHafs,
    required this.surahs,
    required this.localizedSurahLabel,
    required this.localizedJuzLabel,
    required this.localizedPagesLabel,
  });

  final int hizbNumber;
  final int juzNumber;
  final int startSurah;
  final int startAyah;
  final int endSurah;
  final int endAyah;
  final int startPageHafs;
  final int endPageHafs;
  final List<HizbDisplaySurah> surahs;
  final String localizedSurahLabel;
  final String localizedJuzLabel;
  final String localizedPagesLabel;

  String get startRef => '$startSurah:$startAyah';
  String get endRef => '$endSurah:$endAyah';
  String get rangeLabel => '$startRef – $endRef';
  String get pageRangeLabel => '$startPageHafs–$endPageHafs';
  int get pageHafs => startPageHafs;

  factory HizbDisplayMetadata.fromHizb(
    int hizbNumber, {
    required String languageCode,
  }) => HizbDisplayMetadata.fromDefinition(
    hizbNumber,
    definitionId: HizbDefinitions.quranFoundationHafsV1,
    languageCode: languageCode,
  );

  factory HizbDisplayMetadata.fromDefinition(
    int hizbNumber, {
    required String? definitionId,
    required String languageCode,
  }) {
    final ref = HizbIndexRepository.getByDefinition(
      hizbNumber,
      definitionId: definitionId,
    );
    final surahs = List<HizbDisplaySurah>.unmodifiable(
      QuranSubdivisionData.surahList
          .where((surah) {
            final number = surah['number']! as int;
            return number >= ref.surah && number <= ref.endSurah;
          })
          .map(HizbDisplaySurah.fromMap),
    );

    if (surahs.isEmpty) {
      throw StateError('Hizb $hizbNumber ne traverse aucune sourate');
    }

    return HizbDisplayMetadata(
      hizbNumber: hizbNumber,
      juzNumber: ref.juz,
      startSurah: ref.surah,
      startAyah: ref.ayah,
      endSurah: ref.endSurah,
      endAyah: ref.endAyah,
      startPageHafs: ref.pageHafs,
      endPageHafs: ref.endPageHafs,
      surahs: surahs,
      localizedSurahLabel: _formatSurahLabel(surahs, languageCode),
      localizedJuzLabel:
          languageCode == 'ar' ? 'الجزء ${ref.juz}' : 'Juz ${ref.juz}',
      localizedPagesLabel:
          languageCode == 'ar'
              ? 'الصفحات ${ref.pageHafs}–${ref.endPageHafs}'
              : 'Pages ${ref.pageHafs}–${ref.endPageHafs}',
    );
  }

  static String _formatSurahLabel(
    List<HizbDisplaySurah> surahs,
    String languageCode,
  ) {
    String name(HizbDisplaySurah surah) =>
        languageCode == 'ar' ? surah.nameAr : surah.transliteratedName;

    if (surahs.length == 1) return name(surahs.first);
    return languageCode == 'ar'
        ? '${name(surahs.first)} ← ${name(surahs.last)}'
        : '${name(surahs.first)} → ${name(surahs.last)}';
  }
}

class HizbDisplaySurah {
  const HizbDisplaySurah({
    required this.number,
    required this.nameAr,
    required this.transliteratedName,
    required this.ayahCount,
  });

  final int number;
  final String nameAr;
  final String transliteratedName;
  final int ayahCount;

  factory HizbDisplaySurah.fromMap(Map<String, dynamic> map) =>
      HizbDisplaySurah(
        number: map['number']! as int,
        nameAr: map['name']! as String,
        // Le catalogue historique nomme ce champ nameFr, mais sa valeur est
        // une translittération déjà utilisée par ANIS en français et anglais.
        transliteratedName: map['nameFr']! as String,
        ayahCount: map['verses']! as int,
      );
}
