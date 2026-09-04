import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/wird.dart';
import 'wird_rub_tracker.dart';

/// Service Wird V2 — tracking canonique par Rub'.
class WirdService {
  static const _wirdKey = 'anis_wird_v2';
  final _rubTracker = WirdRubTracker();

  Future<Wird> getWird(String userId) async {
    final prefs = await SharedPreferences.getInstance();
    final json = prefs.getString('${_wirdKey}_$userId');
    if (json == null) return Wird.defaultWird();

    try {
      final map = jsonDecode(json) as Map<String, dynamic>;
      return Wird.fromMap(map);
    } catch (_) {
      return Wird.defaultWird();
    }
  }

  Future<void> saveWird(String userId, Wird wird) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('${_wirdKey}_$userId', jsonEncode(wird.toMap()));
  }

  Future<void> updateDailyGoal(String userId, int targetRubs) async {
    final wird = await getWird(userId);
    await saveWird(
      userId,
      wird.copyWith(dailyTargetRubs: targetRubs),
    );
  }

  /// Enregistre un tour de page séquentiel (marque les Rub' franchis).
  Future<bool> recordSequentialPageTurn(
    String userId,
    String mushafType,
    int fromPage,
    int toPage,
    int lastSurah,
    int lastAyah,
  ) async {
    final completed = await _rubTracker.recordSequentialPageTurn(
      userId,
      mushafType,
      fromPage,
      toPage,
      lastSurah,
      lastAyah,
    );

    if (completed) {
      final wird = await getWird(userId);
      await saveWird(
        userId,
        wird.copyWith(
          lastMushafType: mushafType,
          lastPage: toPage,
          lastReadAt: DateTime.now(),
        ),
      );
    }

    return completed;
  }

  /// Sauvegarde position de reprise sans marquer de Rub' complété
  /// (navigation programmatique, resume, search, picker, jump).
  Future<void> savePositionOnly(
    String userId,
    String mushafType,
    int page, {
    int? surah,
    int? ayah,
  }) async {
    await _rubTracker.savePositionOnly(
      userId,
      mushafType,
      page,
      surah: surah,
      ayah: ayah,
    );

    final wird = await getWird(userId);
    await saveWird(
      userId,
      wird.copyWith(
        lastMushafType: mushafType,
        lastPage: page,
        lastReadAt: DateTime.now(),
      ),
    );
  }

  /// Progression aujourd'hui (nombre de Rub' uniques complétés).
  Future<int> getTodayProgress(String userId) async {
    return _rubTracker.getUniqueRubsCompletedToday(userId);
  }

  /// Rub' complétés aujourd'hui (IDs des marqueurs).
  Future<Set<int>> getTodayCompletedRubIds(String userId) async {
    return _rubTracker.getRubsCompletedForDate(userId, DateTime.now());
  }

  /// Continuité récente (nombre de jours actifs sur les N derniers jours).
  Future<int> getRecentContinuity(String userId, int lastNDays) async {
    return _rubTracker.getActiveDaysCount(userId, lastNDays);
  }

  /// Dernière date de lecture.
  Future<DateTime?> getLastReadDate(String userId) async {
    final position = await _rubTracker.getLastPosition(userId);
    return position?.lastReadAt;
  }

  /// Position de reprise (mushafType + page).
  Future<({String type, int page})?> getLastPosition(String userId) async {
    final position = await _rubTracker.getLastPosition(userId);
    if (position == null) return null;
    return (type: position.type, page: position.page);
  }

  /// Dernière page séquentielle (pour détecter les sauts).
  Future<int?> getLastSequentialPage(String userId) async {
    return _rubTracker.getLastSequentialPage(userId);
  }

  /// Dernière position Quran séquentielle (surah, ayah).
  /// 
  /// Retourne null si aucune lecture séquentielle n'a eu lieu.
  /// Cette position est plus précise que lastPage car elle reflète
  /// la vraie position de lecture séquentielle de l'utilisateur.
  Future<(int surah, int ayah)?> getLastSequentialQuranPosition(String userId) async {
    return _rubTracker.getLastSequentialQuranPosition(userId);
  }

  /// Enregistre la complétion de la dernière page du Quran.
  Future<bool> recordFinalPageCompletion(
    String userId,
    String mushafType,
  ) async {
    return _rubTracker.recordFinalPageCompletion(userId, mushafType);
  }
}
