import 'package:flutter/foundation.dart';

import 'hizb_canonical_data.dart';
import 'quran_subdivision_data.dart';

/// API de compatibilité pour les données Hizb.
///
/// Les bornes ne sont plus stockées ici : elles sont dérivées de
/// [HizbCanonicalData], certifié contre Quran Foundation Content API v4.
class QuranHizbData {
  QuranHizbData._();

  static const String hizbConventionLabel =
      'Découpage standard 30 Juz / 60 Hizb (Quran Foundation)';

  static final List<Map<String, String>> hizbList = List.unmodifiable(
    HizbCanonicalData.refs.map((ref) {
      final start = _surah(ref.startSurah);
      final end = _surah(ref.endSurah);
      return {
        'range': '${ref.startRef} - ${ref.endRef}',
        'surah':
            ref.startSurah == ref.endSurah
                ? start['name']! as String
                : '${start['name']} - ${end['name']}',
      };
    }),
  );

  static Map<String, dynamic> _surah(int number) =>
      QuranSubdivisionData.surahList[number - 1];

  static int compareAyah(int aSurah, int aAyah, int bSurah, int bAyah) {
    if (aSurah < bSurah) return -1;
    if (aSurah > bSurah) return 1;
    if (aAyah < bAyah) return -1;
    if (aAyah > bAyah) return 1;
    return 0;
  }

  static bool isAyahInRange(
    int surah,
    int ayah,
    int startSurah,
    int startAyah,
    int endSurah,
    int endAyah,
  ) =>
      compareAyah(surah, ayah, startSurah, startAyah) >= 0 &&
      compareAyah(surah, ayah, endSurah, endAyah) <= 0;

  static int getHizbForAyah(int surah, int ayah) {
    for (final ref in HizbCanonicalData.refs) {
      if (ref.containsAyah(surah, ayah)) return ref.hizbNumber;
    }
    return 1;
  }

  static int getHizbFromAyah(int surah, int verse) =>
      getHizbForAyah(surah, verse);

  static Map<String, String> getHizbData(int hizbNumber) {
    if (hizbNumber < 1 || hizbNumber > hizbList.length) {
      return const {'range': '', 'surah': ''};
    }
    return hizbList[hizbNumber - 1];
  }

  static void debugPrintHizbRanges() {
    if (!kDebugMode) return;
    debugPrint('✅ QuranHizbData: ${hizbList.length} Hizb canoniques');
    for (final number in [1, 2, 29, 30, 44, 57, 58, 59, 60]) {
      final ref = HizbCanonicalData.getByNumber(number);
      debugPrint(
        'Hizb $number · Juz ${ref.juzNumber} → '
        '${ref.startRef}–${ref.endRef} · '
        'pages ${ref.startPageHafs}–${ref.endPageHafs}',
      );
    }
  }
}
