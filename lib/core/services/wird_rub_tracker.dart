import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

import '../abstractions/subdivision_definition.dart';
import '../data/subdivision_definitions/hafs_quran_foundation_rub_240_v1.dart';
import '../models/subdivision_marker.dart';

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
  final SubdivisionDefinition _definition;
  late final String _namespace;

  /// Crée un tracker avec une définition de subdivision.
  /// 
  /// Par défaut, utilise la définition Hafs 240 Rub' validée en production.
  /// 
  /// Le namespace de stockage est automatiquement dérivé de l'ID de la définition
  /// pour garantir la cohérence entre logique et progression sauvegardée.
  WirdRubTracker({SubdivisionDefinition? definition})
      : _definition = definition ?? HafsQuranFoundationRub240V1Definition() {
    _namespace = _definition.id;
  }

  static const _rubsCompletedKey = 'anis_wird_rubs_completed';
  static const _lastPositionKey = 'anis_wird_last_position';
  static const _lastSequentialPageKey = 'anis_wird_last_sequential_page';
  
  /// Identifiant legacy pour migration: tout ce qui n'a pas de namespace
  /// explicite est considéré comme Hafs 240 V1
  static const _legacyHafsNamespace = 'hafs_quran_foundation_rub_240_v1';

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
    
    // Migration lazy pour les données Hafs legacy
    await _migrateLegacyRubsIfNeeded(prefs, userId, today);
    
    final key = _namespacedRubsKey(userId, today);

    // Récupérer les Rub' déjà complétés aujourd'hui
    final existing = prefs.getStringList(key) ?? [];
    final completed = existing.map((s) => int.parse(s)).toSet();
    final initialCount = completed.length;

    // Trouver les marqueurs franchis entre la position précédente et actuelle
    final previousPosition = await _getLastSequentialPosition(userId);
    final (fromSurah, fromAyah) = previousPosition ?? (1, 1);
    
    final newlyFranchis = _definition.getMarkersCrossedBetween(
      fromSurah: fromSurah,
      fromAyah: fromAyah,
      toSurah: lastSurah,
      toAyah: lastAyah,
      granularity: SubdivisionGranularity.rub,
    );
    
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
    
    // Migration lazy pour les données Hafs legacy
    await _migrateLegacyRubsIfNeeded(prefs, userId, today);
    
    final key = _namespacedRubsKey(userId, today);
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
    
    // Migration lazy pour les données Hafs legacy
    await _migrateLegacyRubsIfNeeded(prefs, userId, dateKey);
    
    final key = _namespacedRubsKey(userId, dateKey);
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
      
      // Migration lazy pour chaque jour
      await _migrateLegacyRubsIfNeeded(prefs, userId, dateKey);
      
      final key = _namespacedRubsKey(userId, dateKey);
      final list = prefs.getStringList(key) ?? [];
      if (list.isNotEmpty) activeDays++;
    }

    return activeDays;
  }

  /// Dernière page séquentielle enregistrée (pour détecter les sauts).
  Future<int?> getLastSequentialPage(String userId) async {
    final prefs = await SharedPreferences.getInstance();
    
    // Migration lazy pour les données Hafs legacy
    await _migrateLegacySequentialPageIfNeeded(prefs, userId);
    
    final key = _namespacedSequentialPageKey(userId);
    return prefs.getInt(key);
  }

  /// Dernière position séquentielle Quran (surah, ayah) enregistrée.
  /// 
  /// Retourne null si aucune position séquentielle n'existe.
  /// Cette position est mise à jour uniquement lors des tours de page séquentiels,
  /// ce qui garantit qu'elle reflète la lecture réelle de l'utilisateur.
  Future<(int surah, int ayah)?> getLastSequentialQuranPosition(String userId) async {
    return _getLastSequentialPosition(userId);
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
    final key = _namespacedSequentialPageKey(userId);
    await prefs.setInt(key, page);
  }

  Future<void> _saveLastSequentialPosition(String userId, int surah, int ayah) async {
    final prefs = await SharedPreferences.getInstance();
    final data = {'surah': surah, 'ayah': ayah};
    final key = _namespacedSequentialPositionKey(userId);
    await prefs.setString(key, jsonEncode(data));
  }

  Future<(int, int)?> _getLastSequentialPosition(String userId) async {
    final prefs = await SharedPreferences.getInstance();
    
    // Migration lazy pour les données Hafs legacy
    await _migrateLegacySequentialPositionIfNeeded(prefs, userId);
    
    final key = _namespacedSequentialPositionKey(userId);
    final json = prefs.getString(key);
    if (json == null) return null;
    final map = jsonDecode(json) as Map<String, dynamic>;
    return (map['surah'] as int, map['ayah'] as int);
  }

  String _todayKey() => _dateKey(DateTime.now());

  String _dateKey(DateTime date) =>
      '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

  /// Construit une clé namespacée pour les marker IDs complétés
  String _namespacedRubsKey(String userId, String dateKey) =>
      '$_rubsCompletedKey:$_namespace:$userId:$dateKey';

  /// Construit la clé legacy (sans namespace) pour migration
  String _legacyRubsKey(String userId, String dateKey) =>
      '$_rubsCompletedKey:$userId:$dateKey';

  /// Construit une clé namespacée pour la dernière page séquentielle
  String _namespacedSequentialPageKey(String userId) =>
      '$_lastSequentialPageKey:$_namespace:$userId';

  /// Construit la clé legacy (sans namespace) pour la page séquentielle
  String _legacySequentialPageKey(String userId) =>
      '$_lastSequentialPageKey:$userId';

  /// Construit une clé namespacée pour la dernière position Quran séquentielle
  String _namespacedSequentialPositionKey(String userId) =>
      '${_lastSequentialPageKey}_position:$_namespace:$userId';

  /// Construit la clé legacy (sans namespace) pour la position séquentielle
  String _legacySequentialPositionKey(String userId) =>
      '${_lastSequentialPageKey}_position:$userId';

  /// Migration lazy: copie legacy vers nouvelle clé Hafs si nécessaire
  /// 
  /// Retourne true si migration effectuée, false sinon.
  /// Cette migration est idempotente et ne supprime jamais les données legacy.
  Future<bool> _migrateLegacyRubsIfNeeded(
    SharedPreferences prefs,
    String userId,
    String dateKey,
  ) async {
    // Seulement pour Hafs: si nouvelle clé absente et legacy présente, copier
    if (_namespace != _legacyHafsNamespace) return false;

    final newKey = _namespacedRubsKey(userId, dateKey);
    final legacyKey = _legacyRubsKey(userId, dateKey);

    // Si nouvelle clé existe déjà, pas de migration
    if (prefs.containsKey(newKey)) return false;

    // Si legacy key existe, copier vers nouvelle clé
    final legacyData = prefs.getStringList(legacyKey);
    if (legacyData != null && legacyData.isNotEmpty) {
      await prefs.setStringList(newKey, legacyData);
      return true;
    }

    return false;
  }

  /// Migration lazy pour la dernière page séquentielle
  Future<bool> _migrateLegacySequentialPageIfNeeded(
    SharedPreferences prefs,
    String userId,
  ) async {
    if (_namespace != _legacyHafsNamespace) return false;

    final newKey = _namespacedSequentialPageKey(userId);
    final legacyKey = _legacySequentialPageKey(userId);

    if (prefs.containsKey(newKey)) return false;

    final legacyPage = prefs.getInt(legacyKey);
    if (legacyPage != null) {
      await prefs.setInt(newKey, legacyPage);
      return true;
    }

    return false;
  }

  /// Migration lazy pour la dernière position Quran séquentielle
  Future<bool> _migrateLegacySequentialPositionIfNeeded(
    SharedPreferences prefs,
    String userId,
  ) async {
    if (_namespace != _legacyHafsNamespace) return false;

    final newKey = _namespacedSequentialPositionKey(userId);
    final legacyKey = _legacySequentialPositionKey(userId);

    if (prefs.containsKey(newKey)) return false;

    final legacyJson = prefs.getString(legacyKey);
    if (legacyJson != null) {
      await prefs.setString(newKey, legacyJson);
      return true;
    }

    return false;
  }
}
