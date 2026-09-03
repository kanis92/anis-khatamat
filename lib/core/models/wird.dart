import 'package:equatable/equatable.dart';

/// Modèle Wird V2 — tracking canonique par Rub' (1/4 Hizb).
/// 
/// - 240 Rub' canoniques (4 par Hizb × 60 Hizb)
/// - 1 Nisf = 2 Rub'
/// - 1 Hizb = 4 Rub'
/// - Objectif quotidien en Rub', pas en pages
/// - Position de reprise reste page-based (mushafType + page)
class Wird extends Equatable {
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

  const Wird({
    required this.dailyTargetRubs,
    this.lastMushafType,
    this.lastPage,
    this.lastReadAt,
    required this.createdAt,
  });

  Wird copyWith({
    int? dailyTargetRubs,
    String? lastMushafType,
    int? lastPage,
    DateTime? lastReadAt,
    DateTime? createdAt,
  }) {
    return Wird(
      dailyTargetRubs: dailyTargetRubs ?? this.dailyTargetRubs,
      lastMushafType: lastMushafType ?? this.lastMushafType,
      lastPage: lastPage ?? this.lastPage,
      lastReadAt: lastReadAt ?? this.lastReadAt,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'dailyTargetRubs': dailyTargetRubs,
      'lastMushafType': lastMushafType,
      'lastPage': lastPage,
      'lastReadAt': lastReadAt?.toIso8601String(),
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory Wird.fromMap(Map<String, dynamic> map) {
    return Wird(
      dailyTargetRubs: map['dailyTargetRubs'] as int? ?? 4, // défaut 1 Hizb
      lastMushafType: map['lastMushafType'] as String?,
      lastPage: map['lastPage'] as int?,
      lastReadAt: map['lastReadAt'] != null
          ? DateTime.parse(map['lastReadAt'] as String)
          : null,
      createdAt: map['createdAt'] != null
          ? DateTime.parse(map['createdAt'] as String)
          : DateTime.now(),
    );
  }

  /// Wird par défaut : 1 Hizb par jour (4 Rub')
  static Wird defaultWird() {
    return Wird(
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
        dailyTargetRubs,
        lastMushafType,
        lastPage,
        lastReadAt,
        createdAt,
      ];
}
