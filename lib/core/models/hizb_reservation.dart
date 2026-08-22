import 'package:equatable/equatable.dart';

/// Statuts possibles d'un Hizb en mode réservation collaborative
enum HizbReservationStatus {
  available,
  softLocked,
  reserved,
  inProgress,
  completed,
  expired,
}

/// Source de la réservation (audit)
enum ReservationSource {
  app,
  webGuest,
}

/// Données de réservation d'un Hizb
class HizbReservation extends Equatable {
  final HizbReservationStatus status;
  final String? reservedBy;
  /// Nom affiché (soi ou personne pour qui on réserve)
  final String? reservedForName;
  final DateTime? reservedAt;
  final DateTime? expiresAt;
  final DateTime? completedAt;
  final String? softLockedBy;
  final DateTime? softLockExpiresAt;
  final int extendedCount;
  final String? source;
  /// Numéro Hizb (1–60) — présent dans les documents sous-collection.
  final int? hizbNumber;
  /// Snapshot sémantique immuable de la portion coranique réservée.
  final String? hizbDefinitionId;
  final String? startVerseKey;
  final String? endVerseKey;
  final int? startPageHafs;
  final int? endPageHafs;

  const HizbReservation({
    this.status = HizbReservationStatus.available,
    this.reservedBy,
    this.reservedForName,
    this.reservedAt,
    this.expiresAt,
    this.completedAt,
    this.softLockedBy,
    this.softLockExpiresAt,
    this.extendedCount = 0,
    this.source,
    this.hizbNumber,
    this.hizbDefinitionId,
    this.startVerseKey,
    this.endVerseKey,
    this.startPageHafs,
    this.endPageHafs,
  });

  bool get isAvailable =>
      status == HizbReservationStatus.available ||
      status == HizbReservationStatus.expired;
  bool get isSoftLocked => status == HizbReservationStatus.softLocked;
  bool get isReserved =>
      status == HizbReservationStatus.reserved ||
      status == HizbReservationStatus.inProgress;
  bool get isInProgress => status == HizbReservationStatus.inProgress;
  bool get isCompleted => status == HizbReservationStatus.completed;
  bool get canExtend => extendedCount < 1 && isReserved;
  bool get hasCompleteSnapshot =>
      hizbNumber != null &&
      hizbDefinitionId != null &&
      startVerseKey != null &&
      endVerseKey != null &&
      startPageHafs != null &&
      endPageHafs != null;

  /// Construit un nouvel état fonctionnel tout en conservant exclusivement le
  /// snapshot immuable. Les données de réservation omises sont volontairement
  /// effacées, contrairement à [copyWith].
  HizbReservation transitionTo({
    required HizbReservationStatus status,
    String? reservedBy,
    String? reservedForName,
    DateTime? reservedAt,
    DateTime? expiresAt,
    DateTime? completedAt,
    String? softLockedBy,
    DateTime? softLockExpiresAt,
    int extendedCount = 0,
    String? source,
  }) {
    return HizbReservation(
      status: status,
      reservedBy: reservedBy,
      reservedForName: reservedForName,
      reservedAt: reservedAt,
      expiresAt: expiresAt,
      completedAt: completedAt,
      softLockedBy: softLockedBy,
      softLockExpiresAt: softLockExpiresAt,
      extendedCount: extendedCount,
      source: source,
      hizbNumber: hizbNumber,
      hizbDefinitionId: hizbDefinitionId,
      startVerseKey: startVerseKey,
      endVerseKey: endVerseKey,
      startPageHafs: startPageHafs,
      endPageHafs: endPageHafs,
    );
  }

  HizbReservation copyWith({
    HizbReservationStatus? status,
    String? reservedBy,
    String? reservedForName,
    DateTime? reservedAt,
    DateTime? expiresAt,
    DateTime? completedAt,
    String? softLockedBy,
    DateTime? softLockExpiresAt,
    int? extendedCount,
    String? source,
    int? hizbNumber,
    String? hizbDefinitionId,
    String? startVerseKey,
    String? endVerseKey,
    int? startPageHafs,
    int? endPageHafs,
  }) {
    return HizbReservation(
      status: status ?? this.status,
      reservedBy: reservedBy ?? this.reservedBy,
      reservedForName: reservedForName ?? this.reservedForName,
      reservedAt: reservedAt ?? this.reservedAt,
      expiresAt: expiresAt ?? this.expiresAt,
      completedAt: completedAt ?? this.completedAt,
      softLockedBy: softLockedBy ?? this.softLockedBy,
      softLockExpiresAt: softLockExpiresAt ?? this.softLockExpiresAt,
      extendedCount: extendedCount ?? this.extendedCount,
      source: source ?? this.source,
      hizbNumber: hizbNumber ?? this.hizbNumber,
      hizbDefinitionId: hizbDefinitionId ?? this.hizbDefinitionId,
      startVerseKey: startVerseKey ?? this.startVerseKey,
      endVerseKey: endVerseKey ?? this.endVerseKey,
      startPageHafs: startPageHafs ?? this.startPageHafs,
      endPageHafs: endPageHafs ?? this.endPageHafs,
    );
  }

  factory HizbReservation.fromMap(Map<String, dynamic> map) {
    final statusStr = map['status'] as String? ?? 'available';
    return HizbReservation(
      status: HizbReservationStatus.values.firstWhere(
        (e) => e.name == statusStr,
        orElse: () => HizbReservationStatus.available,
      ),
      reservedBy: map['reservedBy'] as String?,
      reservedForName: map['reservedForName'] as String?,
      reservedAt: map['reservedAt'] != null
          ? DateTime.tryParse(map['reservedAt'].toString())
          : null,
      expiresAt: map['expiresAt'] != null
          ? DateTime.tryParse(map['expiresAt'].toString())
          : null,
      completedAt: map['completedAt'] != null
          ? DateTime.tryParse(map['completedAt'].toString())
          : null,
      softLockedBy: map['softLockedBy'] as String?,
      softLockExpiresAt: map['softLockExpiresAt'] != null
          ? DateTime.tryParse(map['softLockExpiresAt'].toString())
          : null,
      extendedCount: (map['extendedCount'] as num?)?.toInt() ?? 0,
      source: map['source'] as String?,
      hizbNumber: (map['hizbNumber'] as num?)?.toInt(),
      hizbDefinitionId: map['hizbDefinitionId'] as String?,
      startVerseKey: map['startVerseKey'] as String?,
      endVerseKey: map['endVerseKey'] as String?,
      startPageHafs: (map['startPageHafs'] as num?)?.toInt(),
      endPageHafs: (map['endPageHafs'] as num?)?.toInt(),
    );
  }

  Map<String, dynamic> toMap({int? hizbNumberOverride}) {
    final num = hizbNumberOverride ?? hizbNumber;
    return {
      if (num != null) 'hizbNumber': num,
      if (hizbDefinitionId != null) 'hizbDefinitionId': hizbDefinitionId,
      if (startVerseKey != null) 'startVerseKey': startVerseKey,
      if (endVerseKey != null) 'endVerseKey': endVerseKey,
      if (startPageHafs != null) 'startPageHafs': startPageHafs,
      if (endPageHafs != null) 'endPageHafs': endPageHafs,
      'status': status.name,
      if (reservedBy != null) 'reservedBy': reservedBy,
      if (reservedForName != null) 'reservedForName': reservedForName,
      if (reservedAt != null) 'reservedAt': reservedAt!.toIso8601String(),
      if (expiresAt != null) 'expiresAt': expiresAt!.toIso8601String(),
      if (completedAt != null) 'completedAt': completedAt!.toIso8601String(),
      if (softLockedBy != null) 'softLockedBy': softLockedBy,
      if (softLockExpiresAt != null)
        'softLockExpiresAt': softLockExpiresAt!.toIso8601String(),
      if (extendedCount > 0) 'extendedCount': extendedCount,
      if (source != null) 'source': source,
    };
  }

  @override
  List<Object?> get props => [
        status,
        reservedBy,
        reservedForName,
        reservedAt,
        expiresAt,
        completedAt,
        softLockedBy,
        softLockExpiresAt,
        extendedCount,
        source,
        hizbNumber,
        hizbDefinitionId,
        startVerseKey,
        endVerseKey,
        startPageHafs,
        endPageHafs,
      ];
}
