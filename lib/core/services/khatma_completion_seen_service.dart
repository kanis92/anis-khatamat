import 'package:shared_preferences/shared_preferences.dart';

/// Mémorise localement qu'un utilisateur a déjà vu la transition de clôture.
class KhatmaCompletionSeenService {
  static const _prefix = 'khatma_completion_seen_';

  Future<bool> hasSeenCelebration(String khatmaId) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('$_prefix$khatmaId') ?? false;
  }

  Future<void> markCelebrationSeen(String khatmaId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('$_prefix$khatmaId', true);
  }
}
