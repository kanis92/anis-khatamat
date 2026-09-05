import 'package:hijri_date_time/hijri_date_time.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

import '../models/wird.dart';
import '../models/wird_plan.dart';
import '../models/wird_plan_state.dart';
import '../utils/balanced_distribution.dart';

/// Service de gestion des plans de lecture personnels du Quran.
///
/// **Architecture :**
/// - Plans = intentions (cycles temporels, portées)
/// - Progression = dérivée du WirdRubTracker (pas de duplication)
/// - Allocation = distribution équilibrée avec recalcul dynamique
class WirdPlanService {
  /// Récupère la progression actuelle d'un plan.
  ///
  /// **Stratégie d'agrégation :**
  /// - Parcourt toutes les dates depuis baselineDate (exclus) jusqu'à aujourd'hui (inclus)
  /// - Collecte tous les completion IDs dans [startCompletionId, endCompletionId]
  /// - Union simple acceptable pour Phase 0 (cycle unique, non-répétitif)
  /// - Design future-proof: cycleNumber permet de filtrer cycles répétés
  ///
  /// **Invariant critique :**
  /// - Source unique de vérité : WirdRubTracker via SharedPreferences
  /// - Aucune progression n'est stockée dans WirdPlan
  Future<Set<int>> getPlanProgress(
    String userId,
    WirdPlan plan,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    final planCompletions = <int>{};

    // Calculer plage de dates : (baselineDate, today]
    final today = DateTime.now();
    final baselineMidnight = _toMidnight(plan.baselineDate);
    final todayMidnight = _toMidnight(today);

    // Parcourir chaque jour depuis baseline + 1 jusqu'à aujourd'hui
    var currentDate = baselineMidnight.add(const Duration(days: 1));

    while (
        currentDate.isBefore(todayMidnight) || currentDate == todayMidnight) {
      final dateKey = _formatDateKey(currentDate);
      final namespace = plan.subdivisionDefinitionId;

      // Clé SharedPreferences identique à WirdRubTracker
      final key = 'anis_wird_rubs_completed:$namespace:$userId:$dateKey';

      final dailyCompletions = prefs.getStringList(key) ?? [];

      for (final idStr in dailyCompletions) {
        final id = int.parse(idStr);

        // Filtrer : seulement completion IDs dans la portée du plan
        if (id >= plan.startCompletionId && id <= plan.endCompletionId) {
          planCompletions.add(id);
        }
      }

      currentDate = currentDate.add(const Duration(days: 1));
    }

    return planCompletions;
  }

  /// Calcule l'allocation quotidienne recommandée pour aujourd'hui.
  ///
  /// **Logique :**
  /// - Plan libre : retourne objectif fixe (dailyTargetRubs du Wird parent)
  /// - Plan temporel : distribution équilibrée des Rub' restants sur jours restants
  /// - Recalcul dynamique : ahead/behind géré automatiquement
  ///
  /// **Garanties :**
  /// - Allocation entière (pas de décimales)
  /// - Variation max-min ≤ 1 entre les jours
  /// - Somme exacte = Rub' restants
  int calculateTodayAllocation(
    WirdPlan plan,
    Set<int> currentProgress,
    Wird wird,
    DateTime today,
  ) {
    final totalTarget = plan.totalRubTarget;
    final completed = currentProgress.length;
    final remaining = totalTarget - completed;

    if (remaining <= 0) return 0; // Plan complété

    // Plan libre : objectif fixe depuis Wird parent
    if (plan.type == WirdPlanType.freeDaily) {
      return wird.dailyTargetRubs;
    }

    // Plans temporels : allocation dynamique
    final daysLeft = _calculateRemainingDays(plan, today);

    if (daysLeft <= 0) {
      // Deadline passée ou dernier jour : tout ce qui reste
      return remaining;
    }

    // Distribution équilibrée sur jours restants
    final distribution = balancedDistribution(remaining, daysLeft);

    // Aujourd'hui = premier jour de la distribution
    return distribution.first;
  }

  /// Calcule les jours restants dans le cycle du plan.
  ///
  /// Retourne jours restants inclus aujourd'hui.
  /// - Normalisation à minuit pour comparaison date-only
  /// - today inclus dans le compte
  int calculateRemainingDays(WirdPlan plan, DateTime today) {
    if (plan.endDate == null) return 999; // Pas de deadline

    final todayMidnight = _toMidnight(today);
    final endMidnight = _toMidnight(plan.endDate!);

    if (todayMidnight.isAfter(endMidnight)) return 0; // Deadline passée

    final diff = endMidnight.difference(todayMidnight).inDays;
    return diff + 1; // +1 car aujourd'hui compte
  }

  int _calculateRemainingDays(WirdPlan plan, DateTime today) {
    return calculateRemainingDays(plan, today);
  }

  /// Crée un plan mois hijri en réutilisant la convention ANIS existante.
  ///
  /// **Source Hijri :**
  /// - Package : hijri_date_time (déjà utilisé dans ANIS)
  /// - API : HijriDateTime.fromGregorian() et .toGregorian()
  ///
  /// **Modes :**
  /// - startNextMonth = false : démarre aujourd'hui, finit fin du mois en cours
  /// - startNextMonth = true : démarre 1er du prochain mois, finit fin du mois prochain
  WirdPlan createHijriMonthPlan({
    required String subdivisionDefinitionId,
    required DateTime startGregorian,
    bool startNextMonth = false,
  }) {
    final startHijri = HijriDateTime.fromGregorian(startGregorian);

    final HijriDateTime planStartHijri;
    final HijriDateTime planEndHijri;

    if (startNextMonth) {
      // Option B : démarrer le 1er du prochain mois hijri
      planStartHijri = HijriDateTime(
        startHijri.year,
        month: startHijri.month + 1,
        day: 1,
      );
      final daysInMonth = planStartHijri.monthLength;
      planEndHijri = HijriDateTime(
        planStartHijri.year,
        month: planStartHijri.month,
        day: daysInMonth,
      );
    } else {
      // Option A : démarrer aujourd'hui, finir fin du mois en cours
      planStartHijri = startHijri;
      final daysInMonth = startHijri.monthLength;
      planEndHijri = HijriDateTime(
        startHijri.year,
        month: startHijri.month,
        day: daysInMonth,
      );
    }

    final startGregorianDate = planStartHijri.toGregorian();
    final endGregorianDate = planEndHijri.toGregorian();

    return WirdPlan(
      id: const Uuid().v4(),
      type: WirdPlanType.hijriMonth,
      subdivisionDefinitionId: subdivisionDefinitionId,
      baselineDate: _toMidnight(startGregorianDate).subtract(
        const Duration(days: 1), // baseline = jour avant début
      ),
      endDate: _toMidnight(endGregorianDate),
      startCompletionId: 1,
      endCompletionId: 240,
      createdAt: DateTime.now(),
    );
  }

  /// Crée un plan mois grégorien.
  ///
  /// **Modes :**
  /// - startNextMonth = false : démarre aujourd'hui, finit fin du mois en cours
  /// - startNextMonth = true : démarre 1er du prochain mois, finit fin du mois prochain
  WirdPlan createGregorianMonthPlan({
    required String subdivisionDefinitionId,
    required DateTime startGregorian,
    bool startNextMonth = false,
  }) {
    final DateTime planStartDate;
    final DateTime planEndDate;

    if (startNextMonth) {
      // Option B : démarrer le 1er du prochain mois
      planStartDate = DateTime(
        startGregorian.year,
        startGregorian.month + 1,
        1,
      );
      // Dernier jour du mois suivant
      planEndDate = DateTime(
        planStartDate.year,
        planStartDate.month + 1,
        0, // Dernier jour du mois
      );
    } else {
      // Option A : démarrer aujourd'hui, finir fin du mois en cours
      planStartDate = startGregorian;
      // Dernier jour du mois en cours
      planEndDate = DateTime(
        startGregorian.year,
        startGregorian.month + 1,
        0,
      );
    }

    return WirdPlan(
      id: const Uuid().v4(),
      type: WirdPlanType.gregorianMonth,
      subdivisionDefinitionId: subdivisionDefinitionId,
      baselineDate: _toMidnight(planStartDate).subtract(
        const Duration(days: 1), // baseline = jour avant début
      ),
      endDate: _toMidnight(planEndDate),
      startCompletionId: 1,
      endCompletionId: 240,
      createdAt: DateTime.now(),
    );
  }

  /// Calcule le nombre de Rub' restants à accomplir.
  int calculateRemainingRubs(WirdPlan plan, Set<int> currentProgress) {
    final totalTarget = plan.totalRubTarget;
    final completed = currentProgress.length;
    return totalTarget - completed;
  }

  /// Détermine l'état runtime du plan.
  ///
  /// **Logique :**
  /// - null plan → none
  /// - plan.completedAt != null → completed
  /// - today < baselineDate + 1 → scheduled (pas encore démarré)
  /// - today > endDate && not completed → expired
  /// - sinon → active
  WirdPlanState determinePlanState(
    WirdPlan? plan,
    Set<int> currentProgress,
    DateTime today,
  ) {
    if (plan == null) return WirdPlanState.none;

    // Complété explicitement
    if (plan.completedAt != null) return WirdPlanState.completed;

    // Vérifier si tous les Rub' sont complétés (implicitement complété)
    final remaining = calculateRemainingRubs(plan, currentProgress);
    if (remaining <= 0) return WirdPlanState.completed;

    final todayMidnight = _toMidnight(today);
    final baselineMidnight = _toMidnight(plan.baselineDate);
    final startMidnight = baselineMidnight.add(const Duration(days: 1));

    // Pas encore démarré
    if (todayMidnight.isBefore(startMidnight)) {
      return WirdPlanState.scheduled;
    }

    // Expiré (deadline passée et non complété)
    if (plan.endDate != null) {
      final endMidnight = _toMidnight(plan.endDate!);
      if (todayMidnight.isAfter(endMidnight)) {
        return WirdPlanState.expired;
      }
    }

    // Actif
    return WirdPlanState.active;
  }

  /// Vérifie si le plan est actif aujourd'hui (pas scheduled).
  ///
  /// **Important :** Un plan scheduled ne doit PAS affecter l'objectif
  /// quotidien libre d'aujourd'hui.
  bool isPlanActiveToday(WirdPlan? plan, DateTime today) {
    if (plan == null) return false;

    final todayMidnight = _toMidnight(today);
    final baselineMidnight = _toMidnight(plan.baselineDate);
    final startMidnight = baselineMidnight.add(const Duration(days: 1));

    return !todayMidnight.isBefore(startMidnight);
  }

  /// Valide qu'un plan est compatible avec son Wird parent.
  ///
  /// **Invariant critique :**
  /// - WirdPlan.subdivisionDefinitionId DOIT correspondre à
  ///   Wird.subdivisionDefinitionId
  /// - Sinon, le plan lirait un namespace de progression incorrect
  ///
  /// Throws [ArgumentError] si mismatch détecté.
  void validatePlanForWird(WirdPlan plan, String wirdDefinitionId) {
    if (plan.subdivisionDefinitionId != wirdDefinitionId) {
      throw ArgumentError(
        'Plan subdivisionDefinitionId "${plan.subdivisionDefinitionId}" '
        'does not match Wird subdivisionDefinitionId "$wirdDefinitionId". '
        'Cannot use plan with different definition.',
      );
    }
  }

  String _formatDateKey(DateTime date) =>
      '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

  DateTime _toMidnight(DateTime dt) => DateTime(dt.year, dt.month, dt.day);
}
