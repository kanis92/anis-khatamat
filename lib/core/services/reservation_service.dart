import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../constants/app_constants.dart';
import '../constants/hizb_definitions.dart';
import '../constants/reservation_config.dart';
import '../constants/reservation_schema.dart';
import '../models/hizb_reservation.dart';
import '../models/khatma.dart';
import '../models/reading_progress.dart';
import '../utils/reservation_counter_utils.dart';
import 'hizb_reservation_repository.dart';
import 'reading_history_service.dart';
import 'reading_service.dart';

/// Erreurs de réservation (UX claire)
enum ReservationErrorCode {
  alreadyReserved,
  limitReached,
  expired,
  softLockExpired,
  notYours,
  alreadyExtended,
  invalidState,
}

class ReservationException implements Exception {
  final ReservationErrorCode code;
  final int? hizbNumber;
  final String message;

  ReservationException(this.code, this.message, [this.hizbNumber]);
}

/// Service de réservation avec transactions Firestore sur sous-collection v2.
class ReservationService {
  final _readingService = ReadingService();
  final _historyService = ReadingHistoryService();
  final _reservationRepo = HizbReservationRepository();
  static const _idempotencyPrefix = 'anis_idem_';

  FirebaseFirestore get _firestore => FirebaseFirestore.instance;

  int maxHizbPerUser(Khatma khatma) {
    final completed = khatma.completedReservationCount;
    return completed >= ReservationConfig.completedThresholdForHigherLimit
        ? ReservationConfig.maxHizbPerUserWhenAlmostDone
        : ReservationConfig.maxHizbPerUserDefault;
  }

  bool _isExpired(HizbReservation r) {
    if (r.expiresAt == null) return false;
    return DateTime.now().isAfter(r.expiresAt!);
  }

  bool _isSoftLockExpired(HizbReservation r) {
    if (r.softLockExpiresAt == null) return false;
    return DateTime.now().isAfter(r.softLockExpiresAt!);
  }

  HizbReservation _resolveExpired(HizbReservation r) {
    if (r.isSoftLocked && _isSoftLockExpired(r)) {
      return r.transitionTo(status: HizbReservationStatus.available);
    }
    if (r.isReserved && _isExpired(r)) {
      return r.transitionTo(status: HizbReservationStatus.expired);
    }
    return r;
  }

  Future<bool> _checkIdempotency(String key) async {
    final prefs = await SharedPreferences.getInstance();
    final stored = prefs.getString('$_idempotencyPrefix$key');
    if (stored == null) return false;
    try {
      final ts = int.tryParse(stored) ?? 0;
      final age = DateTime.now().millisecondsSinceEpoch - ts;
      if (age > ReservationConfig.idempotencyCacheMinutes * 60 * 1000) {
        await prefs.remove('$_idempotencyPrefix$key');
        return false;
      }
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<void> _setIdempotency(String key) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      '$_idempotencyPrefix$key',
      DateTime.now().millisecondsSinceEpoch.toString(),
    );
  }

  Future<Khatma?> _getKhatma(String khatmaId) =>
      _readingService.getKhatmaById(khatmaId);

  DocumentReference<Map<String, dynamic>> _hizbRef(
    String khatmaId,
    int hizbNumber,
  ) =>
      _reservationRepo.hizbDocumentRef(khatmaId, hizbNumber);

  Future<Map<int, HizbReservation>> _readAllReservationsInTransaction(
    Transaction tx,
    String khatmaId,
  ) async {
    final map = <int, HizbReservation>{};
    for (var i = 1; i <= AppConstants.totalHizb; i++) {
      final doc = await tx.get(_hizbRef(khatmaId, i));
      if (doc.exists && doc.data() != null) {
        map[i] = HizbReservation.fromMap(doc.data()!);
      }
    }
    return map;
  }

  HizbReservation _getFromMap(
    Map<int, HizbReservation> map,
    int hizbNumber,
  ) {
    final reservation = map[hizbNumber];
    if (reservation == null || !reservation.hasCompleteSnapshot) {
      throw ReservationException(
        ReservationErrorCode.invalidState,
        'Snapshot canonique du Hizb $hizbNumber absent',
        hizbNumber,
      );
    }
    return reservation;
  }

  void _requireSupportedDefinition(Khatma khatma) {
    try {
      HizbDefinitions.requireSupported(khatma.hizbDefinitionId);
    } on UnsupportedHizbDefinitionException {
      throw ReservationException(
        ReservationErrorCode.invalidState,
        'Cette Khatma doit être recréée avec un référentiel Hizb explicite',
      );
    }
  }

  Future<void> _ensureMigrated(String khatmaId) async {
    final k = await _getKhatma(khatmaId);
    if (k == null || !k.reservationMode || k.id.startsWith('local_')) return;
    _requireSupportedDefinition(k);
    if (k.reservationSchemaVersion >= ReservationSchema.subcollection) return;
    await _reservationRepo.migrateIfNeeded(k);
  }

  Future<void> softLock(
    String khatmaId,
    int hizbNumber,
    String userId, {
    String? idempotencyKey,
    String source = 'app',
  }) async {
    if (idempotencyKey != null) {
      if (await _checkIdempotency(idempotencyKey)) return;
    }
    await _ensureMigrated(khatmaId);

    await _firestore.runTransaction((tx) async {
      final parentRef = _firestore.collection('khatmat').doc(khatmaId);
      final parentDoc = await tx.get(parentRef);
      if (!parentDoc.exists) {
        throw ReservationException(ReservationErrorCode.invalidState, 'Khatma introuvable');
      }

      final khatma = Khatma.fromMap({...parentDoc.data()!, 'id': parentDoc.id});
      if (!khatma.reservationMode) return;
      _requireSupportedDefinition(khatma);

      final allMap = await _readAllReservationsInTransaction(tx, khatmaId);
      var r = _resolveExpired(_getFromMap(allMap, hizbNumber));

      if (!r.isAvailable && !(r.isSoftLocked && r.softLockedBy == userId)) {
        throw ReservationException(
          ReservationErrorCode.alreadyReserved,
          'Hizb $hizbNumber déjà réservé',
          hizbNumber,
        );
      }

      if (_reservationRepo.countActiveByUser(allMap, userId) >= maxHizbPerUser(khatma)) {
        throw ReservationException(
          ReservationErrorCode.limitReached,
          'Limite de ${maxHizbPerUser(khatma)} Hizb atteinte',
          hizbNumber,
        );
      }

      final now = DateTime.now();
      final softExpires = now.add(Duration(seconds: ReservationConfig.softLockSeconds));
      tx.set(
        _hizbRef(khatmaId, hizbNumber),
        r.transitionTo(
          status: HizbReservationStatus.softLocked,
          softLockedBy: userId,
          softLockExpiresAt: softExpires,
          source: source,
        ).toMap(hizbNumberOverride: hizbNumber),
      );
    });

    if (idempotencyKey != null) await _setIdempotency(idempotencyKey);
  }

  Future<void> reserve(
    String khatmaId,
    int hizbNumber,
    String userId, {
    String? reservedForName,
    String? idempotencyKey,
    String source = 'app',
  }) async {
    if (idempotencyKey != null) {
      if (await _checkIdempotency(idempotencyKey)) return;
    }

    try {
      await _reserveFirestore(
        khatmaId,
        hizbNumber,
        userId,
        reservedForName: reservedForName,
        source: source,
      );
      if (idempotencyKey != null) await _setIdempotency(idempotencyKey);
    } catch (e) {
      final khatma = await _getKhatma(khatmaId);
      if (khatma != null && khatma.id.startsWith('local_')) {
        debugPrint('ReservationService: Firestore échoué, fallback local (Khatma locale): $e');
        try {
          await _readingService.reserveHizb(
            khatmaId,
            hizbNumber,
            userId,
            reservedForName: reservedForName,
          );
          if (idempotencyKey != null) await _setIdempotency(idempotencyKey);
          return;
        } on HizbReservationConflictException catch (c) {
          throw ReservationException(
            ReservationErrorCode.alreadyReserved,
            'Hizb ${c.hizbNumber} déjà réservé',
            c.hizbNumber,
          );
        }
      }
      if (e is ReservationException) rethrow;
      throw ReservationException(
        ReservationErrorCode.invalidState,
        'Réservation indisponible hors ligne. Réessayez avec une connexion.',
        hizbNumber,
      );
    }
  }

  Future<void> _reserveFirestore(
    String khatmaId,
    int hizbNumber,
    String userId, {
    String? reservedForName,
    String source = 'app',
  }) async {
    await _ensureMigrated(khatmaId);

    await _firestore.runTransaction((tx) async {
      final parentRef = _firestore.collection('khatmat').doc(khatmaId);
      final parentDoc = await tx.get(parentRef);
      if (!parentDoc.exists) {
        throw ReservationException(ReservationErrorCode.invalidState, 'Khatma introuvable');
      }

      final khatma = Khatma.fromMap({...parentDoc.data()!, 'id': parentDoc.id});
      if (!khatma.reservationMode) return;
      _requireSupportedDefinition(khatma);

      final allMap = await _readAllReservationsInTransaction(tx, khatmaId);
      var r = _resolveExpired(_getFromMap(allMap, hizbNumber));

      final isMySoftLock = r.isSoftLocked && r.softLockedBy == userId;
      if (!r.isAvailable && !isMySoftLock) {
        throw ReservationException(
          ReservationErrorCode.alreadyReserved,
          'Hizb $hizbNumber déjà réservé',
          hizbNumber,
        );
      }

      if (r.isReserved && r.reservedBy == userId) return;

      if (_reservationRepo.countActiveByUser(allMap, userId) >= maxHizbPerUser(khatma)) {
        throw ReservationException(
          ReservationErrorCode.limitReached,
          'Limite de ${maxHizbPerUser(khatma)} Hizb atteinte',
          hizbNumber,
        );
      }

      final now = DateTime.now();
      final expires = now.add(Duration(hours: ReservationConfig.reservationExpirationHours));
      tx.set(
        _hizbRef(khatmaId, hizbNumber),
        r.transitionTo(
          status: HizbReservationStatus.reserved,
          reservedBy: userId,
          reservedForName:
              reservedForName?.trim().isNotEmpty == true ? reservedForName!.trim() : null,
          reservedAt: now,
          expiresAt: expires,
          source: source,
        ).toMap(hizbNumberOverride: hizbNumber),
      );
    });
  }

  Future<void> release(
    String khatmaId,
    int hizbNumber,
    String userId, {
    String? idempotencyKey,
  }) async {
    if (idempotencyKey != null) {
      if (await _checkIdempotency(idempotencyKey)) return;
    }
    await _ensureMigrated(khatmaId);

    await _firestore.runTransaction((tx) async {
      final parentRef = _firestore.collection('khatmat').doc(khatmaId);
      final parentDoc = await tx.get(parentRef);
      if (!parentDoc.exists) return;

      final hizbDoc = await tx.get(_hizbRef(khatmaId, hizbNumber));
      if (!hizbDoc.exists) return;

      final r = HizbReservation.fromMap(hizbDoc.data()!);
      if (r.reservedBy != userId && r.softLockedBy != userId) return;
      if (!r.isReserved && !r.isSoftLocked) return;

      tx.set(
        _hizbRef(khatmaId, hizbNumber),
        r
            .transitionTo(status: HizbReservationStatus.available)
            .toMap(hizbNumberOverride: hizbNumber),
      );
    });

    if (idempotencyKey != null) await _setIdempotency(idempotencyKey);
  }

  Future<void> start(
    String khatmaId,
    int hizbNumber,
    String userId, {
    String? idempotencyKey,
  }) async {
    if (idempotencyKey != null) {
      if (await _checkIdempotency(idempotencyKey)) return;
    }
    await _ensureMigrated(khatmaId);

    await _firestore.runTransaction((tx) async {
      final parentRef = _firestore.collection('khatmat').doc(khatmaId);
      final parentDoc = await tx.get(parentRef);
      if (!parentDoc.exists) {
        throw ReservationException(ReservationErrorCode.invalidState, 'Khatma introuvable');
      }

      final hizbDoc = await tx.get(_hizbRef(khatmaId, hizbNumber));
      if (!hizbDoc.exists) {
        throw ReservationException(
          ReservationErrorCode.notYours,
          'Hizb non réservé par vous',
          hizbNumber,
        );
      }

      var r = HizbReservation.fromMap(hizbDoc.data()!);
      if (r.reservedBy != userId || !r.isReserved) {
        throw ReservationException(
          ReservationErrorCode.notYours,
          'Hizb non réservé par vous',
          hizbNumber,
        );
      }
      if (_isExpired(r)) {
        throw ReservationException(
          ReservationErrorCode.expired,
          'Réservation expirée',
          hizbNumber,
        );
      }

      tx.update(_hizbRef(khatmaId, hizbNumber), {
        'status': HizbReservationStatus.inProgress.name,
      });
    });

    if (idempotencyKey != null) await _setIdempotency(idempotencyKey);
  }

  Future<void> done(
    String khatmaId,
    int hizbNumber,
    String userId, {
    String? idempotencyKey,
    String? authUid,
  }) async {
    if (idempotencyKey != null) {
      if (await _checkIdempotency(idempotencyKey)) return;
    }

    try {
      await _doneFirestore(khatmaId, hizbNumber, userId, authUid: authUid);
      if (idempotencyKey != null) await _setIdempotency(idempotencyKey);
    } catch (e) {
      final khatma = await _getKhatma(khatmaId);
      if (khatma != null && khatma.id.startsWith('local_')) {
        debugPrint('ReservationService.done: fallback local (Khatma locale): $e');
        await _readingService.completeHizbReservation(
          khatmaId,
          hizbNumber,
          userId,
          authUid: authUid,
        );
        return;
      }
      if (e is ReservationException) rethrow;
      throw ReservationException(
        ReservationErrorCode.invalidState,
        'Validation indisponible hors ligne. Réessayez avec une connexion.',
        hizbNumber,
      );
    }
  }

  Future<void> _doneFirestore(
    String khatmaId,
    int hizbNumber,
    String userId, {
    String? authUid,
  }) async {
    await _ensureMigrated(khatmaId);
    final now = DateTime.now();
    var wasAlreadyCompleted = false;

    await _firestore.runTransaction((tx) async {
      final parentRef = _firestore.collection('khatmat').doc(khatmaId);
      final parentDoc = await tx.get(parentRef);
      if (!parentDoc.exists) {
        throw ReservationException(ReservationErrorCode.invalidState, 'Khatma introuvable');
      }

      final khatma = Khatma.fromMap({...parentDoc.data()!, 'id': parentDoc.id});
      final hizbDoc = await tx.get(_hizbRef(khatmaId, hizbNumber));
      if (!hizbDoc.exists) return;

      var r = HizbReservation.fromMap(hizbDoc.data()!);
      if (ReservationCounterUtils.shouldSkipDone(r, userId)) {
        if (r.isCompleted) wasAlreadyCompleted = true;
        return;
      }

      final allMap = await _readAllReservationsInTransaction(tx, khatmaId);
      final currentCount = khatma.completedHizbCount ??
          ReservationCounterUtils.countCompleted(allMap);

      tx.update(_hizbRef(khatmaId, hizbNumber), {
        'status': HizbReservationStatus.completed.name,
        'completedAt': now.toIso8601String(),
      });

      final nextCount = ReservationCounterUtils.nextCompletedCount(currentCount);
      if (nextCount != null) {
        final parentUpdate = <String, dynamic>{
          'completedHizbCount': nextCount,
        };
        if (nextCount >= AppConstants.totalHizb &&
            khatma.completedAt == null) {
          parentUpdate['completedAt'] = FieldValue.serverTimestamp();
        }
        tx.update(parentRef, parentUpdate);
      }
    });

    if (wasAlreadyCompleted) return;

    await _historyService.logHizbCompleted(userId, now);
    final progress = await _readingService.getProgress(khatmaId, userId) ??
        ReadingProgress(
          khatmaId: khatmaId,
          userId: userId,
          lastUpdated: now,
          authUid: authUid,
        );
    final newSet = Set<int>.from(progress.completedHizb)..add(hizbNumber);
    await _readingService.saveProgress(progress.copyWith(
      completedHizb: newSet,
      lastUpdated: now,
      authUid: authUid ?? progress.authUid,
    ));
  }

  Future<void> extend(
    String khatmaId,
    int hizbNumber,
    String userId, {
    String? idempotencyKey,
  }) async {
    if (idempotencyKey != null) {
      if (await _checkIdempotency(idempotencyKey)) return;
    }
    await _ensureMigrated(khatmaId);

    await _firestore.runTransaction((tx) async {
      final parentRef = _firestore.collection('khatmat').doc(khatmaId);
      final parentDoc = await tx.get(parentRef);
      if (!parentDoc.exists) {
        throw ReservationException(ReservationErrorCode.invalidState, 'Khatma introuvable');
      }

      final hizbDoc = await tx.get(_hizbRef(khatmaId, hizbNumber));
      if (!hizbDoc.exists) {
        throw ReservationException(
          ReservationErrorCode.notYours,
          'Hizb non réservé par vous',
          hizbNumber,
        );
      }

      var r = HizbReservation.fromMap(hizbDoc.data()!);
      if (r.reservedBy != userId || !r.isReserved) {
        throw ReservationException(
          ReservationErrorCode.notYours,
          'Hizb non réservé par vous',
          hizbNumber,
        );
      }
      if (!r.canExtend) {
        throw ReservationException(
          ReservationErrorCode.alreadyExtended,
          'Prolongation déjà utilisée',
          hizbNumber,
        );
      }

      final newExpires = (r.expiresAt ?? DateTime.now())
          .add(Duration(hours: ReservationConfig.extensionHours));
      tx.update(_hizbRef(khatmaId, hizbNumber), {
        'expiresAt': newExpires.toIso8601String(),
        'extendedCount': 1,
      });
    });

    if (idempotencyKey != null) await _setIdempotency(idempotencyKey);
  }

  Future<void> adminForceRelease(
    String khatmaId,
    int hizbNumber,
    String adminUserId,
  ) async {
    final khatma = await _getKhatma(khatmaId);
    if (khatma == null || khatma.createdBy != adminUserId) {
      throw ReservationException(ReservationErrorCode.invalidState, 'Non autorisé');
    }
    await _ensureMigrated(khatmaId);

    await _firestore.runTransaction((tx) async {
      final parentRef = _firestore.collection('khatmat').doc(khatmaId);
      final parentDoc = await tx.get(parentRef);
      if (!parentDoc.exists) return;

      final allMap = await _readAllReservationsInTransaction(tx, khatmaId);
      final updatedMap =
          ReservationCounterUtils.applyRelease(allMap, hizbNumber);
      final newCount = ReservationCounterUtils.countCompleted(updatedMap);

      tx.set(
        _hizbRef(khatmaId, hizbNumber),
        _getFromMap(allMap, hizbNumber)
            .transitionTo(status: HizbReservationStatus.available)
            .toMap(hizbNumberOverride: hizbNumber),
      );
      final parentUpdate = <String, dynamic>{'completedHizbCount': newCount};
      if (newCount < AppConstants.totalHizb) {
        parentUpdate['completedAt'] = FieldValue.delete();
      }
      tx.update(parentRef, parentUpdate);
    });
  }
}
