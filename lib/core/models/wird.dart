import 'package:equatable/equatable.dart';

import 'wird_plan.dart';

/// Modèle Wird V2 — tracking canonique par Rub' (1/4 Hizb).
/// 
/// - 240 Rub' canoniques (4 par Hizb × 60 Hizb)
/// - 1 Nisf = 2 Rub'
/// - 1 Hizb = 4 Rub'
/// - Objectif quotidien en Rub', pas en pages
/// - Position de reprise reste page-based (mushafType + page)
/// - Plan personnel optionnel (Personal Khatma Plan)
class Wird extends Equatable {
  /// Identifiant de la définition de subdivision utilisée.
  /// 
  /// Exemple: 'hafs_quran_foundation_rub_240_v1'
  /// 
  /// Cette définition détermine quels marqueurs coraniques sont utilisés
  /// pour le tracking. Les enregistrements legacy sans ce champ sont
  /// automatiquement interprétés comme Hafs 240 Rub'.
  final String subdivisionDefinitionId;

  /// Objectif quotidien en nombre de Rub' (1/4 Hizb).
  /// Exemples : 1 Rub' = 1, 1 Nisf = 2, 1 Hizb = 4, 2 Hizb = 8
  final int dailyTargetRubs;

  /// Position de reprise : type de Mushaf (hafs / warsh / women)
  final String? lastMushafType;

  /// Position de reprise : numéro de page (1-604)
  final int? lastPage;

  /// Dernière lecture enregistrée
  final DateTime? lastReadAt;

  /// Date de création du Wird
  final DateTime createdAt;

  /// Plan personnel actif (Personal Khatma Plan).
  /// 
  /// - null = mode libre (objectif quotidien fixe, pas de deadline)
  /// - non-null = plan temporel (mois hijri/grégorien, allocation dynamique)
  /// 
  /// La progression du plan est dérivée du WirdRubTracker, jamais dupliquée.
  final WirdPlan? activePlan;

  const Wird({
    required this.subdivisionDefinitionId,
    required this.dailyTargetRubs,
    this.lastMushafType,
    this.lastPage,
    this.lastReadAt,
    required this.createdAt,
    this.activePlan,
  });

  Wird copyWith({
    String? subdivisionDefinitionId,
    int? dailyTargetRubs,
    String? lastMushafType,
    int? lastPage,
    DateTime? lastReadAt,
    DateTime? createdAt,
    WirdPlan? activePlan,
  }) {
    return Wird(
      subdivisionDefinitionId:
          subdivisionDefinitionId ?? this.subdivisionDefinitionId,
      dailyTargetRubs: dailyTargetRubs ?? this.dailyTargetRubs,
      lastMushafType: lastMushafType ?? this.lastMushafType,
      lastPage: lastPage ?? this.lastPage,
      lastReadAt: lastReadAt ?? this.lastReadAt,
      createdAt: createdAt ?? this.createdAt,
      activePlan: activePlan ?? this.activePlan,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'subdivisionDefinitionId': subdivisionDefinitionId,
      'dailyTargetRubs': dailyTargetRubs,
      'lastMushafType': lastMushafType,
      'lastPage': lastPage,
      'lastReadAt': lastReadAt?.toIso8601String(),
      'createdAt': createdAt.toIso8601String(),
      if (activePlan != null) 'activePlan': activePlan!.toMap(),
    };
  }

  factory Wird.fromMap(Map<String, dynamic> map) {
    return Wird(
      // MIGRATION: Legacy records without subdivisionDefinitionId default to Hafs 240 Rub'
      subdivisionDefinitionId: map['subdivisionDefinitionId'] as String? ??
          'hafs_quran_foundation_rub_240_v1',
      dailyTargetRubs: map['dailyTargetRubs'] as int? ?? 4, // défaut 1 Hizb
      lastMushafType: map['lastMushafType'] as String?,
      lastPage: map['lastPage'] as int?,
      lastReadAt: map['lastReadAt'] != null
          ? DateTime.parse(map['lastReadAt'] as String)
          : null,
      createdAt: map['createdAt'] != null
          ? DateTime.parse(map['createdAt'] as String)
          : DateTime.now(),
      // MIGRATION: Legacy records without activePlan remain in free daily mode
      activePlan: map['activePlan'] != null
          ? WirdPlan.fromMap(map['activePlan'] as Map<String, dynamic>)
          : null,
    );
  }

  /// Wird par défaut : 1 Hizb par jour (4 Rub') avec définition Hafs 240
  static Wird defaultWird() {
    return Wird(
      subdivisionDefinitionId: 'hafs_quran_foundation_rub_240_v1',
      dailyTargetRubs: 4, // 1 Hizb
      createdAt: DateTime.now(),
    );
  }

  /// Libellés pour les objectifs courants
  static String labelForTarget(int rubs, String Function(String) l10n) {
    switch (rubs) {
      case 1:
        return '1 Rub\' (¼ Hizb)';
      case 2:
        return '1 Nisf (½ Hizb)';
      case 4:
        return '1 Hizb';
      case 8:
        return '2 Hizb';
      default:
        return '$rubs Rub\'';
    }
  }

  @override
  List<Object?> get props => [
        subdivisionDefinitionId,
        dailyTargetRubs,
        lastMushafType,
        lastPage,
        lastReadAt,
        createdAt,
        activePlan,
      ];
}
