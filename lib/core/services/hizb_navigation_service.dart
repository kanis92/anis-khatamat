import 'package:flutter/foundation.dart';
import 'package:flutter_quran/flutter_quran.dart';

import '../constants/hizb_definitions.dart';
import '../models/hizb_ref.dart';
import '../repositories/hizb_index_repository.dart';

/// Point d'entrée unique pour ouvrir un Hizb dans le lecteur Mushaf.
///
/// Tous les écrans (réservation collaborative, Khatma classique, reprise de
/// lecture, sheet de navigation, deep link) doivent passer par ce service.
/// Aucun appelant ne calcule lui-même une page à partir d'un numéro de Hizb.
///
/// Chaîne canonique :
///   hizbNumber (1..60)
///     → [HizbIndexRepository] : surah:ayah de départ + bornes de fin
///       → page du Mushaf rendu (JSON flutter_quran, 604 pages Hafs)
///         → PageView du lecteur
///
/// Les quatre lecteurs (Hafs, Warsh, Femmes) rendent le même JSON Hafs
/// 604 pages : `pageHafs` est donc la seule pagination valide pour piloter
/// le lecteur, y compris en Warsh. `pageWarsh` décrit le Mushaf imprimé et
/// n'est jamais utilisé ici.
class HizbNavigationService {
  HizbNavigationService._();

  /// Nombre de pages du Mushaf rendu par le lecteur.
  static const int totalPages = 604;

  /// Référence canonique du Hizb [hizb] (1–60).
  static HizbRef refFor(int hizb) => HizbIndexRepository.getByNumber(hizb);

  static HizbRef refForDefinition(
    int hizb, {
    required String? definitionId,
  }) =>
      HizbIndexRepository.getByDefinition(
        hizb,
        definitionId: definitionId,
      );

  /// Page de début canonique du Hizb dans le Mushaf rendu.
  ///
  /// Le JSON du Mushaf fait foi quand il est chargé ; la table statique sert
  /// de repli et lui est identique (verrouillé par `hizb_navigation_test.dart`).
  static int startPage(int hizb) {
    final ref = refFor(hizb);
    return _startPageForRef(ref);
  }

  static int startPageForDefinition(
    int hizb, {
    required String? definitionId,
  }) {
    final ref = refForDefinition(hizb, definitionId: definitionId);
    return _startPageForRef(ref);
  }

  static int _startPageForRef(HizbRef ref) {
    final page = _pageOfAyah(ref.surah, ref.ayah);
    return page ?? ref.pageHafs;
  }

  /// Dernière page du Hizb, certifiée depuis les versets Quran Foundation.
  /// Une page peut appartenir à deux Hizb lorsqu'elle contient leur frontière.
  static int endPage(int hizb) => refFor(hizb).endPageHafs;

  static int endPageForDefinition(
    int hizb, {
    required String? definitionId,
  }) =>
      refForDefinition(hizb, definitionId: definitionId).endPageHafs;

  /// Vrai si [page] fait partie du Hizb [hizb].
  static bool pageBelongsToHizb(int hizb, int page) =>
      page >= startPage(hizb) && page <= endPage(hizb);

  static bool pageBelongsToHizbForDefinition(
    int hizb,
    int page, {
    required String? definitionId,
  }) =>
      page >=
          startPageForDefinition(hizb, definitionId: definitionId) &&
      page <= endPageForDefinition(hizb, definitionId: definitionId);

  /// « Lire le Hizb » — ouvre toujours le DÉBUT canonique du Hizb.
  /// Retourne la page réellement atteinte.
  static int openStart(int hizb) {
    final ref = refFor(hizb);
    return _openStartFromRef(hizb, ref);
  }

  static int openStartForDefinition(
    int hizb, {
    required String? definitionId,
  }) {
    final ref = refForDefinition(hizb, definitionId: definitionId);
    return _openStartFromRef(hizb, ref);
  }

  static int _openStartFromRef(int hizb, HizbRef ref) {
    final quran = FlutterQuran();
    final ayah = quran.getAyahBySurahAndVerse(ref.surah, ref.ayah);
    if (ayah != null) {
      quran.navigateToAyah(ayah);
      _log(hizb, ayah.page, 'ayah ${ref.surah}:${ref.ayah}');
      return ayah.page;
    }
    quran.navigateToPage(ref.pageHafs);
    _log(hizb, ref.pageHafs, 'table statique (Mushaf non chargé)');
    return ref.pageHafs;
  }

  /// « Continuer » — reprend à [savedPage] si cette position appartient bien
  /// au Hizb réservé, sinon retombe sur le début canonique du Hizb.
  ///
  /// Une position enregistrée peut pointer hors du Hizb (lecture libre entre
  /// deux sessions, Hizb réattribué, donnée héritée d'une ancienne version).
  /// On ne la suit jamais aveuglément : le contrat « Continuer reste dans le
  /// Hizb réservé » prime sur la restauration exacte.
  static int openResume(int hizb, int? savedPage) {
    if (savedPage != null && pageBelongsToHizb(hizb, savedPage)) {
      FlutterQuran().navigateToPage(savedPage);
      _log(hizb, savedPage, 'reprise');
      return savedPage;
    }
    if (savedPage != null && kDebugMode) {
      debugPrint(
        '[HizbNav] reprise p$savedPage hors Hizb $hizb '
        '(${startPage(hizb)}–${endPage(hizb)}) → repli sur le début',
      );
    }
    return openStart(hizb);
  }

  static int openResumeForDefinition(
    int hizb,
    int? savedPage, {
    required String? definitionId,
  }) {
    if (savedPage != null &&
        pageBelongsToHizbForDefinition(
          hizb,
          savedPage,
          definitionId: definitionId,
        )) {
      FlutterQuran().navigateToPage(savedPage);
      _log(hizb, savedPage, 'reprise');
      return savedPage;
    }
    return openStartForDefinition(hizb, definitionId: definitionId);
  }

  /// Hizb (1–60) auquel appartient la page [page] du Mushaf rendu.
  ///
  /// Une page de frontière est attribuée au Hizb qui y COMMENCE, conformément
  /// aux marqueurs Quran Foundation et à la pagination Hafs rendue.
  static int hizbForPage(int page) =>
      HizbIndexRepository.hizbForPageHafs(page.clamp(1, totalPages));

  /// Hizb à afficher pour [page] dans le lecteur.
  ///
  /// [reservedHizb] est le Hizb demandé par l'appelant (réservation Khatma).
  /// Tant que la page lui appartient encore, il prime : sur une page partagée
  /// par deux Hizb, l'utilisateur doit voir celui qu'il a choisi. Dès qu'il en
  /// sort, l'indicateur suit à nouveau la page réellement affichée.
  static int displayedHizb(int page, {int? reservedHizb}) {
    if (reservedHizb != null &&
        reservedHizb >= 1 &&
        reservedHizb <= 60 &&
        pageBelongsToHizb(reservedHizb, page)) {
      return reservedHizb;
    }
    return hizbForPage(page);
  }

  static int displayedHizbForDefinition(
    int page, {
    required String? definitionId,
    int? reservedHizb,
  }) {
    HizbDefinitions.requireSupported(definitionId);
    if (reservedHizb != null &&
        reservedHizb >= 1 &&
        reservedHizb <= 60 &&
        pageBelongsToHizbForDefinition(
          reservedHizb,
          page,
          definitionId: definitionId,
        )) {
      return reservedHizb;
    }
    return hizbForPage(page);
  }

  static int? _pageOfAyah(int surah, int ayah) =>
      FlutterQuran().getAyahBySurahAndVerse(surah, ayah)?.page;

  static void _log(int hizb, int page, String via) {
    if (!kDebugMode) return;
    final landed = hizbForPage(page);
    final ok = landed == hizb ? '✅' : '⚠️';
    debugPrint(
      '[HizbNav] Hizb $hizb → p$page via $via — page = Hizb $landed $ok',
    );
  }
}
