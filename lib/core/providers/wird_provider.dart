import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/wird.dart';
import '../models/wird_plan.dart';
import '../models/wird_plan_state.dart';
import '../services/wird_plan_service.dart';
import '../services/wird_service.dart';
import 'auth_provider.dart';

/// Providers Wird V2 — État Wird utilisateur avec tracking Rub' canonique

final wirdServiceProvider = Provider<WirdService>((ref) => WirdService());

final wirdPlanServiceProvider = Provider<WirdPlanService>((ref) => WirdPlanService());

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

/// Objectif quotidien autoritaire (en Rub').
///
/// **Règle produit:**
/// - Plan ACTIVE → allocation adaptive du plan
/// - Plan SCHEDULED → free goal (plan futur n'affecte pas aujourd'hui)
/// - NO plan → free goal
/// - Plan COMPLETED/EXPIRED → free goal
///
/// Cette valeur devient la source unique de vérité pour "Lecture du jour".
final wirdTodayAuthoritativeTargetProvider = FutureProvider<int>((ref) async {
  final wird = await ref.watch(wirdProvider.future);
  final plan = wird.activePlan;
  
  // Pas de plan → free goal
  if (plan == null) return wird.dailyTargetRubs;
  
  final state = await ref.watch(wirdPlanStateProvider.future);
  
  // Plan scheduled/completed/expired → free goal
  if (state != WirdPlanState.active) {
    return wird.dailyTargetRubs;
  }
  
  // Plan actif → allocation adaptive
  return ref.watch(wirdPlanAllocationProvider.future);
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
    ref.invalidate(wirdTodayCompletedRubIdsProvider);
    // Plan progress is derived from tracker, will update automatically
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
  ref.invalidate(wirdTodayCompletedRubIdsProvider);
  // Plan progress is derived, will update automatically on next read
}

// ══════════════════════════════════════════════════════════════════════════════
// Personal Khatma Plan Providers
// ══════════════════════════════════════════════════════════════════════════════

/// Plan personnel actif de l'utilisateur (null si mode libre).
final wirdActivePlanProvider = FutureProvider<Wird>((ref) async {
  return ref.watch(wirdProvider.future);
});

/// Progression actuelle du plan actif (completion IDs dérivés du tracker).
///
/// **Important :** Dérivé dynamiquement depuis WirdRubTracker storage.
/// Aucune duplication de progression n'est persistée dans le plan.
///
/// **Validation :** Si le plan existe, son subdivisionDefinitionId doit
/// correspondre au Wird parent. Sinon, throw error.
final wirdPlanProgressProvider = FutureProvider<Set<int>>((ref) async {
  final wird = await ref.watch(wirdProvider.future);
  final plan = wird.activePlan;
  
  if (plan == null) return {};
  
  final planService = ref.watch(wirdPlanServiceProvider);
  
  // CRITICAL: Validate plan compatibility
  planService.validatePlanForWird(plan, wird.subdivisionDefinitionId);
  
  final user = ref.watch(currentUserProvider);
  final userId = user?.email ?? 'demo';
  
  return planService.getPlanProgress(userId, plan);
});

/// État runtime du plan actif.
final wirdPlanStateProvider = FutureProvider<WirdPlanState>((ref) async {
  final wird = await ref.watch(wirdProvider.future);
  final plan = wird.activePlan;
  final progress = await ref.watch(wirdPlanProgressProvider.future);
  
  final planService = ref.watch(wirdPlanServiceProvider);
  return planService.determinePlanState(plan, progress, DateTime.now());
});

/// Allocation quotidienne dynamique pour aujourd'hui.
///
/// **Logique :**
/// - Aucun plan ou plan scheduled → dailyTargetRubs du Wird (mode libre)
/// - Plan actif → allocation équilibrée dynamique basée sur progression réelle
/// - Plan complété/expiré → 0
final wirdPlanAllocationProvider = FutureProvider<int>((ref) async {
  final wird = await ref.watch(wirdProvider.future);
  final plan = wird.activePlan;
  final state = await ref.watch(wirdPlanStateProvider.future);
  
  // Pas de plan ou plan schedulé → mode libre
  if (plan == null || state == WirdPlanState.scheduled) {
    return wird.dailyTargetRubs;
  }
  
  // Plan complété ou expiré → 0
  if (state == WirdPlanState.completed || state == WirdPlanState.expired) {
    return 0;
  }
  
  // Plan actif → allocation dynamique
  final progress = await ref.watch(wirdPlanProgressProvider.future);
  final planService = ref.watch(wirdPlanServiceProvider);
  
  return planService.calculateTodayAllocation(
    plan,
    progress,
    wird,
    DateTime.now(),
  );
});

/// Nombre de Rub' restants à accomplir dans le plan actif.
final wirdPlanRemainingRubsProvider = FutureProvider<int>((ref) async {
  final wird = await ref.watch(wirdProvider.future);
  final plan = wird.activePlan;
  
  if (plan == null) return 0;
  
  final progress = await ref.watch(wirdPlanProgressProvider.future);
  final planService = ref.watch(wirdPlanServiceProvider);
  
  return planService.calculateRemainingRubs(plan, progress);
});

/// Jours restants dans le cycle du plan actif.
final wirdPlanRemainingDaysProvider = FutureProvider<int>((ref) async {
  final wird = await ref.watch(wirdProvider.future);
  final plan = wird.activePlan;
  
  if (plan == null) return 0;
  
  final planService = ref.watch(wirdPlanServiceProvider);
  return planService.calculateRemainingDays(plan, DateTime.now());
});

// ══════════════════════════════════════════════════════════════════════════════
// Personal Khatma Plan Actions
// ══════════════════════════════════════════════════════════════════════════════

/// Active un plan personnel de Khatma.
///
/// **Validation :** Le plan doit avoir le même subdivisionDefinitionId
/// que le Wird actuel.
///
/// Invalidates: wirdProvider, wirdPlanStateProvider, et tous les dérivés.
Future<void> activateWirdPlan(WidgetRef ref, WirdPlan plan) async {
  final service = ref.read(wirdServiceProvider);
  final user = ref.read(currentUserProvider);
  final userId = user?.email ?? 'demo';
  
  await service.activatePlan(userId, plan);
  
  // Invalidate all plan-related providers
  ref.invalidate(wirdProvider);
}

/// Désactive le plan actuel (retour au mode libre).
Future<void> clearWirdPlan(WidgetRef ref) async {
  final service = ref.read(wirdServiceProvider);
  final user = ref.read(currentUserProvider);
  final userId = user?.email ?? 'demo';
  
  await service.clearActivePlan(userId);
  
  ref.invalidate(wirdProvider);
}
