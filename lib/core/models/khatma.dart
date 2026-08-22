import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

import '../constants/app_constants.dart';
import '../constants/hizb_definitions.dart';
import 'hizb_reservation.dart';

/// Représente une Khatma (individuelle ou groupe)
class Khatma extends Equatable {
  final String id;
  final String title;
  final String? objectives;
  final bool isGroup;
  final List<String> members;
  /// Identités canoniques queryables (email ou Firebase uid invité).
  final List<String> participantIds;
  /// Invités sans compte : clé canonique = Firebase Auth UID (request.auth.uid).
  /// Legacy : clés guest_* conservées pour compatibilité documents existants.
  final Map<String, String> guestParticipants;
  /// hizbNumber = identifiant QuranHizbData (1..60), plages via QuranHizbData.getHizbData(id)['range'].
  /// hizbNumber = identifiant QuranHizbData (1..60), plages via QuranHizbData.getHizbData(id)['range'].
  final Map<int, String> hizbAssignments; // hizbNumber -> memberEmail (mode classique)
  final String createdBy;
  final DateTime createdAt;
  /// Mode réservation collaborative : les participants choisissent leurs Hizb
  final bool reservationMode;
  /// Réservations par Hizb (1-60) quand reservationMode = true.
  /// Les clés = identifiant QuranHizbData (1..60), plages via QuranHizbData.getHizbData(id)['range'].
  final Map<int, HizbReservation> hizbReservations;
  /// Khatma publique : visible et rejoignable par tous
  final bool isPublic;
  /// v1 = map embarquée, v2 = sous-collection hizb_reservations
  final int reservationSchemaVersion;
  /// Compteur dénormalisé (v2) — maintenu atomiquement lors des transitions completed
  final int? completedHizbCount;
  /// Date de clôture collective (v2) — écrit une seule fois à 60/60
  final DateTime? completedAt;
  /// Version sémantique du découpage Hizb. Null signifie « non déterminée »,
  /// jamais « canonique par défaut ».
  final String? hizbDefinitionId;

  const Khatma({
    required this.id,
    required this.title,
    this.objectives,
    required this.isGroup,
    this.members = const [],
    this.participantIds = const [],
    this.guestParticipants = const {},
    this.hizbAssignments = const {},
    required this.createdBy,
    required this.createdAt,
    this.reservationMode = false,
    this.hizbReservations = const {},
    this.isPublic = false,
    this.reservationSchemaVersion = 1,
    this.completedHizbCount,
    this.completedAt,
    this.hizbDefinitionId,
  });

  bool get isCollectivelyCompleted =>
      reservationMode &&
      completedReservationCount >= AppConstants.totalHizb;

  /// Nombre de Hizb complétés (mode réservation)
  int get completedReservationCount {
    if (completedHizbCount != null) return completedHizbCount!;
    return hizbReservations.values.where((r) => r.isCompleted).length;
  }

  bool get usesSubcollectionReservations =>
      reservationSchemaVersion >= 2;

  bool get hasSupportedHizbDefinition =>
      HizbDefinitions.isSupported(hizbDefinitionId);

  /// Nombre de Hizb réservés par un utilisateur
  int reservedByUser(String userId) =>
      hizbReservations.values.where((r) => r.reservedBy == userId && r.isReserved).length;

  factory Khatma.fromMap(Map<String, dynamic> map) {
    final guests = map['guestParticipants'] as Map<String, dynamic>? ?? {};
    final assignments = map['hizbAssignments'] as Map<String, dynamic>? ?? {};
    final reservationsRaw = map['hizbReservations'] as Map<String, dynamic>? ?? {};
    final reservations = reservationsRaw.map((k, v) {
      final num = int.tryParse(k.toString()) ?? 0;
      final data = v is Map<String, dynamic> ? v : (v as Map).cast<String, dynamic>();
      return MapEntry(num, HizbReservation.fromMap(data));
    });
    return Khatma(
      id: map['id'] as String? ?? '',
      title: map['title'] as String? ?? '',
      objectives: map['objectives'] as String?,
      isGroup: map['isGroup'] as bool? ?? false,
      members: List<String>.from(map['members'] as List? ?? []),
      participantIds: List<String>.from(map['participantIds'] as List? ?? []),
      guestParticipants: guests.map((k, v) => MapEntry(k.toString(), v.toString())),
      hizbAssignments: assignments.map((k, v) => MapEntry(int.parse(k.toString()), v.toString())),
      createdBy: map['createdBy'] as String? ?? '',
      createdAt: map['createdAt'] != null
          ? DateTime.parse(map['createdAt'].toString())
          : DateTime.now(),
      reservationMode: map['reservationMode'] as bool? ?? false,
      hizbReservations: reservations,
      isPublic: map['isPublic'] as bool? ?? false,
      reservationSchemaVersion:
          (map['reservationSchemaVersion'] as num?)?.toInt() ?? 1,
      completedHizbCount: (map['completedHizbCount'] as num?)?.toInt(),
      completedAt: _parseDateTime(map['completedAt']),
      hizbDefinitionId: map['hizbDefinitionId'] as String?,
    );
  }

  static DateTime? _parseDateTime(dynamic value) {
    if (value == null) return null;
    if (value is DateTime) return value;
    if (value is Timestamp) return value.toDate();
    return DateTime.tryParse(value.toString());
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'objectives': objectives,
      'isGroup': isGroup,
      'members': members,
      if (participantIds.isNotEmpty) 'participantIds': participantIds,
      'guestParticipants': guestParticipants,
      'hizbAssignments': hizbAssignments.map((k, v) => MapEntry(k.toString(), v)),
      'createdBy': createdBy,
      'createdAt': createdAt.toIso8601String(),
      'reservationMode': reservationMode,
      'hizbReservations': hizbReservations.map((k, v) => MapEntry(k.toString(), v.toMap())),
      'isPublic': isPublic,
      if (reservationSchemaVersion > 1) 'reservationSchemaVersion': reservationSchemaVersion,
      if (completedHizbCount != null) 'completedHizbCount': completedHizbCount,
      if (completedAt != null) 'completedAt': completedAt!.toIso8601String(),
      if (hizbDefinitionId != null) 'hizbDefinitionId': hizbDefinitionId,
    };
  }

  Khatma copyWith({
    String? id,
    String? title,
    String? objectives,
    bool? isGroup,
    List<String>? members,
    List<String>? participantIds,
    Map<String, String>? guestParticipants,
    Map<int, String>? hizbAssignments,
    String? createdBy,
    DateTime? createdAt,
    bool? reservationMode,
    Map<int, HizbReservation>? hizbReservations,
    bool? isPublic,
    int? reservationSchemaVersion,
    int? completedHizbCount,
    DateTime? completedAt,
    String? hizbDefinitionId,
  }) {
    return Khatma(
      id: id ?? this.id,
      title: title ?? this.title,
      objectives: objectives ?? this.objectives,
      isGroup: isGroup ?? this.isGroup,
      members: members ?? this.members,
      participantIds: participantIds ?? this.participantIds,
      guestParticipants: guestParticipants ?? this.guestParticipants,
      hizbAssignments: hizbAssignments ?? this.hizbAssignments,
      createdBy: createdBy ?? this.createdBy,
      createdAt: createdAt ?? this.createdAt,
      reservationMode: reservationMode ?? this.reservationMode,
      hizbReservations: hizbReservations ?? this.hizbReservations,
      isPublic: isPublic ?? this.isPublic,
      reservationSchemaVersion:
          reservationSchemaVersion ?? this.reservationSchemaVersion,
      completedHizbCount: completedHizbCount ?? this.completedHizbCount,
      completedAt: completedAt ?? this.completedAt,
      hizbDefinitionId: hizbDefinitionId ?? this.hizbDefinitionId,
    );
  }

  @override
  List<Object?> get props => [id, title, createdAt];
}
