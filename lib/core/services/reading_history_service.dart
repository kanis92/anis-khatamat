import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

/// Historique des lectures quotidiennes (Hizb complétés par jour)
class ReadingHistoryService {
  static const _key = 'anis_reading_history';
  static const _hoursKey = 'anis_reading_hours';
  static const _sessionsKey = 'anis_reading_sessions';
  static const _maxSessions = 2000;

  Future<void> logHizbCompleted(String userId, DateTime date) async {
    final prefs = await SharedPreferences.getInstance();
    final dateStr = _dateKey(date);
    final json = prefs.getString('$_key$userId');
    final map = json != null
        ? Map<String, int>.from(jsonDecode(json) as Map)
        : <String, int>{};
    map[dateStr] = (map[dateStr] ?? 0) + 1;
    await prefs.setString('$_key$userId', jsonEncode(map));

    final hour = date.hour;
    final hoursJson = prefs.getString('$_hoursKey$userId');
    final hoursMap = hoursJson != null
        ? Map<String, int>.from(jsonDecode(hoursJson) as Map)
        : <String, int>{};
    final hourKey = hour.toString().padLeft(2, '0');
    hoursMap[hourKey] = (hoursMap[hourKey] ?? 0) + 1;
    await prefs.setString('$_hoursKey$userId', jsonEncode(hoursMap));

    await _appendSession(prefs, userId, date);
  }

  Future<void> _appendSession(SharedPreferences prefs, String userId, DateTime date) async {
    final json = prefs.getString('$_sessionsKey$userId');
    final list = json != null
        ? List<Map<String, dynamic>>.from(
            (jsonDecode(json) as List).map((e) => Map<String, dynamic>.from(e as Map)))
        : <Map<String, dynamic>>[];
    list.add({'d': _dateKey(date), 'h': date.hour, 'w': date.weekday});
    if (list.length > _maxSessions) {
      list.removeRange(0, list.length - _maxSessions);
    }
    await prefs.setString('$_sessionsKey$userId', jsonEncode(list));
  }

  /// Sessions des N derniers jours : (date, hour, weekday)
  Future<List<({String date, int hour, int weekday})>> getRecentSessions(
    String userId, {
    int days = 90,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final json = prefs.getString('$_sessionsKey$userId');
    if (json == null) return [];
    final list = jsonDecode(json) as List;
    final cutoff = DateTime.now().subtract(Duration(days: days));
    final cutoffStr = _dateKey(cutoff);
    final filtered = list
        .map((e) {
          final m = e as Map<String, dynamic>;
          final d = m['d'] as String? ?? '';
          return (date: d, hour: (m['h'] as num?)?.toInt() ?? 0, weekday: (m['w'] as num?)?.toInt() ?? 1);
        })
        .where((s) => s.date.compareTo(cutoffStr) >= 0)
        .toList();
    filtered.sort((a, b) {
      final dc = a.date.compareTo(b.date);
      return dc != 0 ? dc : a.hour.compareTo(b.hour);
    });
    return filtered;
  }

  /// Distribution (heure, jour-semaine) -> probabilité relative
  /// weekday 1=Monday..7=Sunday
  Future<Map<int, Map<int, double>>> getHourWeekdayDistribution(
    String userId, {
    int days = 60,
  }) async {
    final sessions = await getRecentSessions(userId, days: days);
    if (sessions.isEmpty) return {};
    final count = <int, Map<int, int>>{};
    for (final s in sessions) {
      count.putIfAbsent(s.weekday, () => {}).update(s.hour, (v) => v + 1, ifAbsent: () => 1);
    }
    final result = <int, Map<int, double>>{};
    for (final e in count.entries) {
      final total = e.value.values.fold<int>(0, (a, b) => a + b);
      result[e.key] = e.value.map((h, c) => MapEntry(h, c / total));
    }
    return result;
  }

  /// Dernière session (timestamp)
  Future<DateTime?> getLastSessionTime(String userId) async {
    final sessions = await getRecentSessions(userId, days: 365);
    if (sessions.isEmpty) return null;
    final last = sessions.last;
    final parts = last.date.split('-');
    if (parts.length != 3) return null;
    return DateTime(
      int.parse(parts[0]),
      int.parse(parts[1]),
      int.parse(parts[2]),
      last.hour,
      0,
    );
  }

  /// Retourne le nombre de Hizb lus par jour pour les N derniers jours
  Future<Map<DateTime, int>> getLastDays(String userId, int days) async {
    final prefs = await SharedPreferences.getInstance();
    final json = prefs.getString('$_key$userId');
    final map = json != null
        ? Map<String, int>.from(jsonDecode(json) as Map)
        : <String, int>{};
    final result = <DateTime, int>{};
    final now = DateTime.now();
    for (var i = 0; i < days; i++) {
      final d = DateTime(now.year, now.month, now.day).subtract(Duration(days: i));
      result[d] = map[_dateKey(d)] ?? 0;
    }
    return result;
  }

  /// Heures où l'utilisateur lit le plus (pour suggestions)
  Future<List<int>> getTopReadingHours(String userId, {int limit = 2}) async {
    final prefs = await SharedPreferences.getInstance();
    final json = prefs.getString('$_hoursKey$userId');
    if (json == null) return [7, 21];
    final map = Map<String, int>.from(jsonDecode(json) as Map);
    if (map.isEmpty) return [7, 21];
    final sorted = map.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return sorted.take(limit).map((e) => int.parse(e.key)).toList();
  }

  /// Total Hizb sur les 30 derniers jours
  Future<int> getLast30DaysTotal(String userId) async {
    final map = await getLastDays(userId, 30);
    return map.values.fold<int>(0, (int a, int b) => a + b);
  }

  /// Vitesse moyenne (Hizb/jour) sur les 30 derniers jours
  Future<double> getAverageHizbPerDay(String userId) async {
    final total = await getLast30DaysTotal(userId);
    if (total == 0) return 1.0; // Par défaut : 1 hizb/jour
    return total / 30;
  }

  /// Estimation de la date de fin pour une Khatma (jours restants)
  Future<DateTime?> estimateCompletionDate(
    String userId, {
    required int completedCount,
    required int totalHizb,
  }) async {
    final remaining = totalHizb - completedCount;
    if (remaining <= 0) return DateTime.now();
    final avg = await getAverageHizbPerDay(userId);
    if (avg <= 0) return null;
    final daysNeeded = (remaining / avg).ceil();
    return DateTime.now().add(Duration(days: daysNeeded));
  }

  /// Nombre de jours depuis la dernière lecture (0 = aujourd'hui)
  Future<int> daysSinceLastRead(String userId) async {
    final map = await getLastDays(userId, 365);
    final sorted = map.keys.toList()..sort((a, b) => b.compareTo(a));
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    for (final d in sorted) {
      final count = map[d] ?? 0;
      if (count > 0) {
        return today.difference(d).inDays;
      }
    }
    return 999;
  }

  String _dateKey(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
}
