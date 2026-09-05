import 'package:equatable/equatable.dart';

/// Plan de lecture personnel du Quran.
///
/// Représente l'INTENTION d'accomplir une section du Quran sur un cycle temporel.
/// 
/// **Principes architecturaux :**
/// - Ne duplique PAS la progression (pas de completedRubIds stockés ici)
/// - La progression réelle est dérivée du WirdRubTracker par agrégation différentielle
/// - Définit uniquement : portée cible, cycle temporel, baseline
/// 
/// **Portée :**
/// - Completion IDs strictement 1..240 (business semantics)
/// - 1 = premier Rub' (marker 0 franchi: 1:1 → 2:49)
/// - 240 = dernier Rub' (marker 239 franchi + Quran-end: 114:1 → 114:6)
/// 
/// **Progression :**
/// - Calculée dynamiquement depuis WirdRubTracker
/// - Aggregation: tous les completion IDs dans [start, end] complétés APRÈS baselineDate
/// - Design future-proof pour Khatmas répétés (voir cycleNumber)
class WirdPlan extends Equatable {
  /// Identifiant unique du plan
  final String id;

  /// Type de plan (libre, mois hijri, mois grégorien, deadline custom)
  final WirdPlanType type;

  /// Identifiant de la définition de subdivision (hérité du Wird parent).
  /// 
  /// Exemple: 'hafs_quran_foundation_rub_240_v1'
  /// 
  /// Garantit que le plan utilise les mêmes frontières canoniques
  /// que le tracking quotidien.
  final String subdivisionDefinitionId;

  /// Date de baseline (jour 0 du plan, normalisée à minuit).
  /// 
  /// Tous les Rub' complétés STRICTEMENT APRÈS cette date
  /// comptent pour la progression de ce plan.
  /// 
  /// Exemple: plan démarré le 2026-01-15
  /// → baselineDate = 2026-01-14 23:59:59 (normalisé à minuit du 14)
  /// → progression = completion IDs du 15 janvier et après
  final DateTime baselineDate;

  /// Date de fin du cycle (normalisée à minuit, null si libre).
  /// 
  /// Pour type = freeDaily: null
  /// Pour type = hijriMonth/gregorianMonth: dernier jour du mois
  /// Pour type = customDeadline: date choisie
  final DateTime? endDate;

  /// Premier completion ID de la portée (1..240 inclus).
  /// 
  /// Par défaut 1 (début du Quran).
  final int startCompletionId;

  /// Dernier completion ID de la portée (1..240 inclus).
  /// 
  /// Par défaut 240 (fin du Quran: 114:6).
  final int endCompletionId;

  /// Date de complétion du plan (null si en cours).
  /// 
  /// Marqué complété quand tous les completion IDs [start, end]
  /// ont été accomplis.
  final DateTime? completedAt;

  /// Date de création du plan.
  final DateTime createdAt;

  /// Numéro de cycle (pour Khatmas répétés futurs).
  /// 
  /// Phase 0: toujours 1 (cycle unique).
  /// Future: permet de distinguer plusieurs Khatmas successives
  /// avec le même subdivisionDefinitionId et portée.
  /// 
  /// Exemple:
  /// - Cycle 1: Ramadan 1447
  /// - Cycle 2: Ramadan 1448
  /// 
  /// L'agrégation de progression filtre par (baselineDate, endDate, cycleNumber)
  /// pour éviter la contamination entre cycles.
  final int cycleNumber;

  const WirdPlan({
    required this.id,
    required this.type,
    required this.subdivisionDefinitionId,
    required this.baselineDate,
    this.endDate,
    this.startCompletionId = 1,
    this.endCompletionId = 240,
    this.completedAt,
    required this.createdAt,
    this.cycleNumber = 1,
  }) : assert(startCompletionId >= 1 && startCompletionId <= 240,
            'startCompletionId must be 1..240'),
       assert(endCompletionId >= 1 && endCompletionId <= 240,
            'endCompletionId must be 1..240'),
       assert(startCompletionId <= endCompletionId,
            'startCompletionId must be <= endCompletionId'),
       assert(cycleNumber >= 1, 'cycleNumber must be >= 1');

  /// Nombre total de Rub' ciblés par ce plan.
  int get totalRubTarget => endCompletionId - startCompletionId + 1;

  /// Vérifie si le plan est expiré (deadline passée, non complété).
  bool isExpired(DateTime now) {
    if (completedAt != null) return false; // Complété, pas expiré
    if (endDate == null) return false; // Pas de deadline
    return _toMidnight(now).isAfter(_toMidnight(endDate!));
  }

  /// Vérifie si le plan est complété.
  bool get isCompleted => completedAt != null;

  WirdPlan copyWith({
    String? id,
    WirdPlanType? type,
    String? subdivisionDefinitionId,
    DateTime? baselineDate,
    DateTime? endDate,
    int? startCompletionId,
    int? endCompletionId,
    DateTime? completedAt,
    DateTime? createdAt,
    int? cycleNumber,
  }) {
    return WirdPlan(
      id: id ?? this.id,
      type: type ?? this.type,
      subdivisionDefinitionId:
          subdivisionDefinitionId ?? this.subdivisionDefinitionId,
      baselineDate: baselineDate ?? this.baselineDate,
      endDate: endDate ?? this.endDate,
      startCompletionId: startCompletionId ?? this.startCompletionId,
      endCompletionId: endCompletionId ?? this.endCompletionId,
      completedAt: completedAt ?? this.completedAt,
      createdAt: createdAt ?? this.createdAt,
      cycleNumber: cycleNumber ?? this.cycleNumber,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'type': type.name,
      'subdivisionDefinitionId': subdivisionDefinitionId,
      'baselineDate': baselineDate.toIso8601String(),
      if (endDate != null) 'endDate': endDate!.toIso8601String(),
      'startCompletionId': startCompletionId,
      'endCompletionId': endCompletionId,
      if (completedAt != null) 'completedAt': completedAt!.toIso8601String(),
      'createdAt': createdAt.toIso8601String(),
      'cycleNumber': cycleNumber,
    };
  }

  factory WirdPlan.fromMap(Map<String, dynamic> map) {
    return WirdPlan(
      id: map['id'] as String,
      type: WirdPlanType.values.firstWhere(
        (e) => e.name == map['type'],
        orElse: () => WirdPlanType.freeDaily,
      ),
      subdivisionDefinitionId: map['subdivisionDefinitionId'] as String,
      baselineDate: DateTime.parse(map['baselineDate'] as String),
      endDate: map['endDate'] != null
          ? DateTime.parse(map['endDate'] as String)
          : null,
      startCompletionId: map['startCompletionId'] as int? ?? 1,
      endCompletionId: map['endCompletionId'] as int? ?? 240,
      completedAt: map['completedAt'] != null
          ? DateTime.parse(map['completedAt'] as String)
          : null,
      createdAt: map['createdAt'] != null
          ? DateTime.parse(map['createdAt'] as String)
          : DateTime.now(),
      cycleNumber: map['cycleNumber'] as int? ?? 1,
    );
  }

  @override
  List<Object?> get props => [
        id,
        type,
        subdivisionDefinitionId,
        baselineDate,
        endDate,
        startCompletionId,
        endCompletionId,
        completedAt,
        createdAt,
        cycleNumber,
      ];

  static DateTime _toMidnight(DateTime dt) =>
      DateTime(dt.year, dt.month, dt.day);
}

/// Type de plan de lecture.
enum WirdPlanType {
  /// Mode libre : objectif quotidien fixe, pas de deadline.
  freeDaily,

  /// Plan basé sur un mois hijri (29 ou 30 jours).
  hijriMonth,

  /// Plan basé sur un mois grégorien (28/29/30/31 jours).
  gregorianMonth,

  /// Deadline personnalisée (phase future).
  customDeadline,
}
