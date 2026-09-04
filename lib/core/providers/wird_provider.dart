import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/wird.dart';
import '../services/wird_service.dart';
import 'auth_provider.dart';

/// Providers Wird V2 — État Wird utilisateur avec tracking Rub' canonique

final wirdServiceProvider = Provider<WirdService>((ref) => WirdService());

/// Wird de l'utilisateur (objectif + position)
final wirdProvider = FutureProvider<Wird>((ref) async {
  final service = ref.watch(wirdServiceProvider);
  final user = ref.watch(currentUserProvider);
  final userId = user?.email ?? 'demo';
  return service.getWird(userId);
});

/// Progression aujourd'hui (Rub' complétés)
final wirdTodayProgressProvider = FutureProvider<int>((ref) async {
  final service = ref.watch(wirdServiceProvider);
  final user = ref.watch(currentUserProvider);
  final userId = user?.email ?? 'demo';
  return service.getTodayProgress(userId);
});

/// IDs des Rub' complétés aujourd'hui (0-240)
final wirdTodayCompletedRubIdsProvider = FutureProvider<Set<int>>((ref) async {
  final service = ref.watch(wirdServiceProvider);
  final user = ref.watch(currentUserProvider);
  final userId = user?.email ?? 'demo';
  return service.getTodayCompletedRubIds(userId);
});

/// Continuité 7 derniers jours (jours actifs)
final wirdContinuityProvider = FutureProvider<int>((ref) async {
  final service = ref.watch(wirdServiceProvider);
  final user = ref.watch(currentUserProvider);
  final userId = user?.email ?? 'demo';
  return service.getRecentContinuity(userId, 7);
});

/// Met à jour l'objectif quotidien (en Rub')
Future<void> updateWirdDailyGoal(WidgetRef ref, int targetRubs) async {
  final service = ref.read(wirdServiceProvider);
  final user = ref.read(currentUserProvider);
  final userId = user?.email ?? 'demo';
  await service.updateDailyGoal(userId, targetRubs);
  ref.invalidate(wirdProvider);
}

/// Enregistre un tour de page séquentiel (tracking Rub' canonique).
/// 
/// À appeler UNIQUEMENT lors d'un tour de page avant séquentiel par l'utilisateur.
/// Retourne true si au moins un Rub' a été complété.
Future<bool> recordWirdSequentialPageTurn(
  WidgetRef ref,
  String mushafType,
  int fromPage,
  int toPage,
  int lastSurah,
  int lastAyah,
) async {
  final service = ref.read(wirdServiceProvider);
  final user = ref.read(currentUserProvider);
  final userId = user?.email ?? 'demo';
  
  final completed = await service.recordSequentialPageTurn(
    userId,
    mushafType,
    fromPage,
    toPage,
    lastSurah,
    lastAyah,
  );

  if (completed) {
    ref.invalidate(wirdProvider);
    ref.invalidate(wirdTodayProgressProvider);
  }

  return completed;
}

/// Sauvegarde position seulement (sans marquer de Rub' complété).
/// 
/// À utiliser pour :
/// - navigation programmatique
/// - reprise (resume)
/// - recherche / picker
/// - sauts > 1 page
/// - navigation arrière
Future<void> saveWirdPositionOnly(
  WidgetRef ref,
  String mushafType,
  int page, {
  int? surah,
  int? ayah,
}) async {
  final service = ref.read(wirdServiceProvider);
  final user = ref.read(currentUserProvider);
  final userId = user?.email ?? 'demo';
  
  await service.savePositionOnly(
    userId,
    mushafType,
    page,
    surah: surah,
    ayah: ayah,
  );

  ref.invalidate(wirdProvider);
}

/// Récupère la dernière page séquentielle (pour détecter les sauts).
Future<int?> getWirdLastSequentialPage(WidgetRef ref) async {
  final service = ref.read(wirdServiceProvider);
  final user = ref.read(currentUserProvider);
  final userId = user?.email ?? 'demo';
  return service.getLastSequentialPage(userId);
}

/// Enregistre la complétion de la dernière page du Quran (604).
/// 
/// Cette fonction doit être appelée quand l'utilisateur arrive séquentiellement
/// sur la page finale du Mushaf, car il n'y aura pas de tour 604→605 pour
/// déclencher la complétion automatiquement.
Future<void> recordWirdFinalPageCompletion(
  WidgetRef ref,
  String mushafType,
) async {
  final service = ref.read(wirdServiceProvider);
  final user = ref.read(currentUserProvider);
  final userId = user?.email ?? 'demo';
  
  await service.recordFinalPageCompletion(userId, mushafType);
  
  ref.invalidate(wirdProvider);
  ref.invalidate(wirdTodayProgressProvider);
}
