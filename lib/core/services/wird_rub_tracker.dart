import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

import '../data/quran_subdivision_data.dart';

/// Tracking canonique Wird basé sur les 240 Rub' du Coran.
/// 
/// Règle de complétion :
/// - Navigation programmatique / resume / search / picker → position seulement
/// - Saut > 1 page → position seulement
/// - Navigation arrière → pas de complétion
/// - Tour de page séquentiel avant → évaluer frontières Rub' franchies
/// 
/// Important : Ne marque QUE les frontières franchies entre la position
/// précédente et la nouvelle, pas tous les Rub' avant le curseur actuel.
class WirdRubTracker {
  static const _rubsCompletedKey = 'anis_wird_rubs_completed';
  static const _lastPositionKey = 'anis_wird_last_position';
  static const _lastSequentialPageKey = 'anis_wird_last_sequential_page';

  /// Enregistre la complétion de la dernière page du Quran (cas spécial).
  /// 
  /// La page 604 est la dernière page du Mushaf. Il n'y a pas de tour 604→605,
  /// donc on doit explicitement marquer la complétion quand l'utilisateur
  /// arrive séquentiellement sur cette page.
  /// 
  /// Cette méthode crédite le dernier verset du Quran (114:6), ce qui déclenche
  /// la complétion du 240ème et dernier Rub'.
  Future<bool> recordFinalPageCompletion(
    String userId,
    String mushafType,
  ) async {
    // Sourate 114:6 est le dernier verset du Quran
    // On simule un tour 603→604 pour créditer la page 604
    return recordSequentialPageTurn(
      userId,
      mushafType,
      603, // Page avant-dernière
      604, // Page finale
      114, // An-Nas
      6, // Dernier ayat du Quran
    );
  }

  /// Enregistre les Rub' franchis lors d'un tour de page séquentiel.
  /// 
  /// Retourne true si au moins un nouveau Rub' a été complété.
  Future<bool> recordSequentialPageTurn(
    String userId,
    String mushafType,
    int fromPage,
    int toPage,
    int lastSurah,
    int lastAyah,
  ) async {
    if (toPage <= fromPage || toPage != fromPage + 1) return false;

    final prefs = await SharedPreferences.getInstance();
    final today = _todayKey();
    final key = '$_rubsCompletedKey:$userId:$today';

    // Récupérer les Rub' déjà complétés aujourd'hui
    final existing = prefs.getStringList(key) ?? [];
    final completed = existing.map((s) => int.parse(s)).toSet();
    final initialCount = completed.length;

    // Trouver les marqueurs franchis par la position actuelle et la position précédente
    final currentCrossed = _findCrossedRubs(lastSurah, lastAyah);
    final previousPosition = await _getLastSequentialPosition(userId);
    final previousCrossed = previousPosition != null
        ? _findCrossedRubs(previousPosition.$1, previousPosition.$2)
        : <int>{};

    // Ne marquer que les marqueurs nouvellement franchis (différence entre current et previous)
    final newlyFranchis = currentCrossed.difference(previousCrossed);
    
    // SEMANTIC FIX: Le marqueur 0 (1:1) est le début absolu et ne représente AUCUN Rub' complété.
    // Seuls les marqueurs 1-239 représentent des complétions de Rub'.
    // On filtre donc le marqueur 0 avant de l'ajouter aux Rub' complétés.
    for (final markerIndex in newlyFranchis) {
      if (markerIndex > 0 && !completed.contains(markerIndex)) {
        completed.add(markerIndex);
      }
    }

    // SPECIAL CASE: 240th Rub' (final segment 239 → end of Quran)
    // Il n'y a pas de marqueur 240, donc on détecte explicitement la fin du Quran.
    // Sourate 114 (An-Nas) ayat 6 est le dernier verset du Quran.
    if (lastSurah == 114 && lastAyah == 6 && !completed.contains(240)) {
      // Le lecteur a atteint la fin du Quran, donc le 240ème Rub' est complété
      completed.add(240);
    }

    // TOUJOURS sauvegarder la position séquentielle après un tour valide
    // (même si aucun nouveau Rub' n'a été marqué)
    await _saveLastSequentialPosition(userId, lastSurah, lastAyah);
    await _saveLastSequentialPage(userId, toPage);

    // Sauvegarder les Rub' et la position de reprise si changement
    if (completed.length > initialCount) {
      await prefs.setStringList(
        key,
        completed.map((i) => i.toString()).toList(),
      );
      await _saveLastPosition(userId, mushafType, toPage, lastSurah, lastAyah);
      return true;
    }

    return false;
  }

  /// Sauvegarde position pour reprise (sans marquer de Rub' complété).
  Future<void> savePositionOnly(
    String userId,
    String mushafType,
    int page, {
    int? surah,
    int? ayah,
  }) async {
    await _saveLastPosition(userId, mushafType, page, surah, ayah);
    // Ne pas mettre à jour lastSequentialPage : casse la séquence
  }

  /// Position de reprise sauvegardée.
  Future<({String type, int page, DateTime? lastReadAt})?> getLastPosition(
    String userId,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    final json = prefs.getString('$_lastPositionKey:$userId');
    if (json == null) return null;

    final map = jsonDecode(json) as Map<String, dynamic>;
    return (
      type: map['type'] as String,
      page: map['page'] as int,
      lastReadAt: map['lastReadAt'] != null
          ? DateTime.parse(map['lastReadAt'] as String)
          : null,
    );
  }

  /// Nombre de Rub' uniques complétés aujourd'hui.
  Future<int> getUniqueRubsCompletedToday(String userId) async {
    final prefs = await SharedPreferences.getInstance();
    final today = _todayKey();
    final key = '$_rubsCompletedKey:$userId:$today';
    final list = prefs.getStringList(key) ?? [];
    return list.length;
  }

  /// Rub' complétés pour une date donnée.
  Future<Set<int>> getRubsCompletedForDate(
    String userId,
    DateTime date,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    final dateKey = _dateKey(date);
    final key = '$_rubsCompletedKey:$userId:$dateKey';
    final list = prefs.getStringList(key) ?? [];
    return list.map((s) => int.parse(s)).toSet();
  }

  /// Nombre de jours actifs sur les N derniers jours.
  Future<int> getActiveDaysCount(String userId, int lastNDays) async {
    final prefs = await SharedPreferences.getInstance();
    final now = DateTime.now();
    var activeDays = 0;

    for (var i = 0; i < lastNDays; i++) {
      final date = now.subtract(Duration(days: i));
      final dateKey = _dateKey(date);
      final key = '$_rubsCompletedKey:$userId:$dateKey';
      final list = prefs.getStringList(key) ?? [];
      if (list.isNotEmpty) activeDays++;
    }

    return activeDays;
  }

  /// Dernière page séquentielle enregistrée (pour détecter les sauts).
  Future<int?> getLastSequentialPage(String userId) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt('$_lastSequentialPageKey:$userId');
  }

  /// Trouve tous les Rub' dont le marqueur de début a été franchi par (surah, ayah).
  /// 
  /// Un Rub' est franchi si son début est strictement avant (surah, ayah).
  /// Ne retourne que les Rub' réellement dépassés, pas celui qui commence exactement à cette position.
  Set<int> _findCrossedRubs(int surah, int ayah) {
    final crossed = <int>{};
    // getAllQuarters() retourne 240 marqueurs (60 Hizb × 4 quarts)
    // Chaque marqueur représente un 1/4 de Hizb (Rub'), peu importe son type
    final markers = QuranSubdivisionData.getAllQuarters();

    for (var i = 0; i < markers.length; i++) {
      final marker = markers[i];
      // Un Rub' est franchi si on est APRÈS son début
      if (_isAfter(surah, ayah, marker.surah, marker.ayah)) {
        crossed.add(i); // Index 0-239
      }
    }

    return crossed;
  }

  /// Vrai si (s1, a1) est strictement après (s2, a2) dans l'ordre du Coran.
  bool _isAfter(int s1, int a1, int s2, int a2) {
    if (s1 > s2) return true;
    if (s1 == s2 && a1 > a2) return true;
    return false;
  }

  Future<void> _saveLastPosition(
    String userId,
    String mushafType,
    int page,
    int? surah,
    int? ayah,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    final data = {
      'type': mushafType,
      'page': page,
      if (surah != null) 'surah': surah,
      if (ayah != null) 'ayah': ayah,
      'lastReadAt': DateTime.now().toIso8601String(),
    };
    await prefs.setString('$_lastPositionKey:$userId', jsonEncode(data));
  }

  Future<void> _saveLastSequentialPage(String userId, int page) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('$_lastSequentialPageKey:$userId', page);
  }

  Future<void> _saveLastSequentialPosition(String userId, int surah, int ayah) async {
    final prefs = await SharedPreferences.getInstance();
    final data = {'surah': surah, 'ayah': ayah};
    await prefs.setString('${_lastSequentialPageKey}_position:$userId', jsonEncode(data));
  }

  Future<(int, int)?> _getLastSequentialPosition(String userId) async {
    final prefs = await SharedPreferences.getInstance();
    final json = prefs.getString('${_lastSequentialPageKey}_position:$userId');
    if (json == null) return null;
    final map = jsonDecode(json) as Map<String, dynamic>;
    return (map['surah'] as int, map['ayah'] as int);
  }

  String _todayKey() => _dateKey(DateTime.now());

  String _dateKey(DateTime date) =>
      '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
}
