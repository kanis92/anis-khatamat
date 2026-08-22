import 'package:flutter/foundation.dart';

import '../constants/hizb_definitions.dart';
import '../data/hizb_canonical_data.dart';
import '../models/hizb_ref.dart';
import '../models/hizb_reservation.dart';

/// Façade canonique des 60 Hizb.
///
/// Les bornes, Juz et pages Hafs viennent uniquement de
/// [HizbCanonicalData], certifié contre Quran Foundation Content API v4.
class HizbIndexRepository {
  HizbIndexRepository._();

  static final List<HizbRef> _refs = List.unmodifiable(
    HizbCanonicalData.refs.map(
      (canonical) => HizbRef(
        hizbNumber: canonical.hizbNumber,
        surah: canonical.startSurah,
        ayah: canonical.startAyah,
        endSurah: canonical.endSurah,
        endAyah: canonical.endAyah,
        pageHafs: canonical.startPageHafs,
        endPageHafs: canonical.endPageHafs,
        // Compatibilité historique. Tous les lecteurs ANIS rendent le JSON
        // Hafs 604 pages ; aucune navigation ne doit utiliser cette valeur.
        pageWarsh: canonical.startPageHafs,
        // L'ancienne table d'incipits était décalée à partir du Hizb 14.
        // Une référence exacte vaut mieux qu'un texte coranique incorrect.
        incipitAr: canonical.startRef,
        juz: canonical.juzNumber,
        rangeStr: '${canonical.startRef} - ${canonical.endRef}',
      ),
    ),
  );

  static List<HizbRef> getAllHizbRefs() => _refs;

  static HizbRef getByNumber(int hizbNumber) {
    if (hizbNumber < 1 || hizbNumber > 60) {
      throw ArgumentError(
        'hizbNumber must be between 1 and 60, got $hizbNumber',
      );
    }
    return _refs[hizbNumber - 1];
  }

  /// Résout un Hizb dans un référentiel explicitement versionné.
  ///
  /// Aucune absence de définition n'est convertie implicitement en canonique.
  static HizbRef getByDefinition(
    int hizbNumber, {
    required String? definitionId,
  }) {
    HizbDefinitions.requireSupported(definitionId);
    return getByNumber(hizbNumber);
  }

  /// Snapshot minimal persistant dérivé de la même source que la navigation.
  static HizbReservation reservationSnapshot(
    int hizbNumber, {
    required String? definitionId,
  }) {
    final ref = getByDefinition(
      hizbNumber,
      definitionId: definitionId,
    );
    return HizbReservation(
      hizbNumber: ref.hizbNumber,
      hizbDefinitionId: definitionId,
      startVerseKey: '${ref.surah}:${ref.ayah}',
      endVerseKey: '${ref.endSurah}:${ref.endAyah}',
      startPageHafs: ref.pageHafs,
      endPageHafs: ref.endPageHafs,
    );
  }

  static HizbRef getByPageHafs(int page) {
    HizbRef best = _refs.first;
    for (final ref in _refs) {
      if (ref.pageHafs <= page) {
        best = ref;
      } else {
        break;
      }
    }
    return best;
  }

  static int hizbForAyah(int surah, int ayah) {
    for (final ref in _refs) {
      if (ref.containsAyah(surah, ayah)) return ref.hizbNumber;
    }
    return 1;
  }

  static int hizbForPageHafs(int page) => getByPageHafs(page).hizbNumber;

  /// Alias de compatibilité : les lecteurs ANIS utilisent tous la pagination
  /// Hafs. Il ne constitue pas une certification d'une pagination Warsh.
  static HizbRef getByPageWarsh(int page) => getByPageHafs(page);

  static void debugAssert() {
    if (!kDebugMode) return;
    assert(_refs.length == 60);
    for (var index = 0; index < _refs.length; index++) {
      final ref = _refs[index];
      assert(ref.hizbNumber == index + 1);
      assert(ref.juz == ((ref.hizbNumber - 1) ~/ 2) + 1);
      assert(ref.surah >= 1 && ref.surah <= 114);
      assert(ref.endSurah >= ref.surah && ref.endSurah <= 114);
      assert(ref.pageHafs >= 1 && ref.pageHafs <= 604);
      assert(ref.endPageHafs >= ref.pageHafs && ref.endPageHafs <= 604);
    }
    debugPrint('✅ HizbIndexRepository: 60 références Quran Foundation OK');
  }
}
