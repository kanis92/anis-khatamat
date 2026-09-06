import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../api/anis_api_client.dart';
import '../api/api_exception.dart';
import '../constants/reservation_config.dart';
import '../models/assignee_kind.dart';
import '../models/khatma.dart';
import '../models/reading_progress.dart';
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
  permissionDenied,
  networkError,
}

class ReservationException implements Exception {
  final ReservationErrorCode code;
  final int? hizbNumber;
  final String message;

  ReservationException(this.code, this.message, [this.hizbNumber]);
}

/// Service de réservation avec mutations server-authoritative via REST API.
class ReservationService {
  final _readingService = ReadingService();
  final _historyService = ReadingHistoryService();
  final AnisApiClient _apiClient;
  static const _idempotencyPrefix = 'anis_idem_';

  ReservationService({AnisApiClient? apiClient})
      : _apiClient = apiClient ?? AnisApiClient();

  int maxHizbPerUser(Khatma khatma) {
    final completed = khatma.completedReservationCount;
    return completed >= ReservationConfig.completedThresholdForHigherLimit
        ? ReservationConfig.maxHizbPerUserWhenAlmostDone
        : ReservationConfig.maxHizbPerUserDefault;
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

  /// Client-side soft lock (UX optimization) - kept for offline/instant feedback
  Future<void> softLock(
    String khatmaId,
    int hizbNumber,
    String userId, {
    String? idempotencyKey,
    String source = 'app',
  }) async {
    // Soft lock remains client-side for instant UX feedback
    // This is a temporary hold before actual reservation via Functions
    if (idempotencyKey != null) {
      if (await _checkIdempotency(idempotencyKey)) return;
    }

    // TODO: Implement client-side soft lock if needed
    // For now, this is a no-op since reservation is immediate via Functions

    if (idempotencyKey != null) await _setIdempotency(idempotencyKey);
  }

  /// Reserve a Hizb via server-authoritative callable function
  Future<void> reserve(
    String khatmaId,
    int hizbNumber,
    String userId, {
    String? reservedForName,
    AssigneeKind assigneeKind = AssigneeKind.self,
    String? assigneeUserId,
    String? assignedByUserId,
    String? idempotencyKey,
    String source = 'app',
  }) async {
    if (assigneeKind == AssigneeKind.offline &&
        (reservedForName == null || reservedForName.trim().isEmpty)) {
      throw ReservationException(
        ReservationErrorCode.invalidState,
        'Un nom court est requis pour réserver pour quelqu\'un d\'autre',
        hizbNumber,
      );
    }
    if (assigneeKind == AssigneeKind.participant &&
        (assigneeUserId == null || assigneeUserId.isEmpty)) {
      throw ReservationException(
        ReservationErrorCode.invalidState,
        'Participant requis pour une assignation organisateur',
        hizbNumber,
      );
    }

    if (idempotencyKey != null) {
      if (await _checkIdempotency(idempotencyKey)) return;
    }

    try {
      await _apiClient.post('/khatmat/$khatmaId/hizb/$hizbNumber/reserve', body: {
        'assigneeKind': assigneeKind.value,
        if (assigneeKind == AssigneeKind.offline && reservedForName != null)
          'assigneeDisplayName': reservedForName.trim(),
        if (assigneeKind == AssigneeKind.participant && assigneeUserId != null)
          'assigneeUserId': assigneeUserId,
      });

      if (idempotencyKey != null) await _setIdempotency(idempotencyKey);
    } on ApiException catch (e) {
      throw _mapApiException(e, hizbNumber);
    } catch (e) {
      // Fallback for local Khatma
      final khatma = await _getKhatma(khatmaId);
      if (khatma != null && khatma.id.startsWith('local_')) {
        debugPrint('ReservationService: Firestore échoué, fallback local: $e');
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
      throw ReservationException(
        ReservationErrorCode.networkError,
        'Réservation indisponible hors ligne. Réessayez avec une connexion.',
        hizbNumber,
      );
    }
  }

  /// Release a Hizb via server-authoritative callable function
  Future<void> release(
    String khatmaId,
    int hizbNumber,
    String userId, {
    String? idempotencyKey,
  }) async {
    if (idempotencyKey != null) {
      if (await _checkIdempotency(idempotencyKey)) return;
    }

    try {
      await _apiClient.post('/khatmat/$khatmaId/hizb/$hizbNumber/release', body: {});

      if (idempotencyKey != null) await _setIdempotency(idempotencyKey);
    } on ApiException catch (e) {
      throw _mapApiException(e, hizbNumber);
    } catch (e) {
      throw ReservationException(
        ReservationErrorCode.networkError,
        'Libération indisponible hors ligne. Réessayez avec une connexion.',
        hizbNumber,
      );
    }
  }

  /// Start reading (transition to inProgress) - kept client-side for UX
  Future<void> start(
    String khatmaId,
    int hizbNumber,
    String userId, {
    String? idempotencyKey,
  }) async {
    // This could be removed or kept as a local state transition
    // For now, keeping as no-op since completion is what matters
    if (idempotencyKey != null) await _setIdempotency(idempotencyKey);
  }

  /// Complete a Hizb via server-authoritative callable function
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
      await _apiClient.post('/khatmat/$khatmaId/hizb/$hizbNumber/complete', body: {});

      if (idempotencyKey != null) await _setIdempotency(idempotencyKey);

      // Update local reading progress
      final now = DateTime.now();
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
    } on ApiException catch (e) {
      throw _mapApiException(e, hizbNumber);
    } catch (e) {
      // Fallback for local Khatma
      final khatma = await _getKhatma(khatmaId);
      if (khatma != null && khatma.id.startsWith('local_')) {
        debugPrint('ReservationService.done: fallback local: $e');
        await _readingService.completeHizbReservation(
          khatmaId,
          hizbNumber,
          userId,
          authUid: authUid,
        );
        return;
      }
      throw ReservationException(
        ReservationErrorCode.networkError,
        'Validation indisponible hors ligne. Réessayez avec une connexion.',
        hizbNumber,
      );
    }
  }

  /// Extend reservation - kept client-side or could be moved to Functions
  Future<void> extend(
    String khatmaId,
    int hizbNumber,
    String userId, {
    String? idempotencyKey,
  }) async {
    // Extension feature - could be added to Functions later if needed
    // For now, keeping as no-op
    if (idempotencyKey != null) await _setIdempotency(idempotencyKey);
  }

  /// Admin force release - kept for organizer override
  Future<void> adminForceRelease(
    String khatmaId,
    int hizbNumber,
    String adminUserId,
  ) async {
    // Use releaseHizb REST API with organizer permissions
    try {
      await _apiClient.post('/khatmat/$khatmaId/hizb/$hizbNumber/release', body: {});
    } on ApiException catch (e) {
      throw _mapApiException(e, hizbNumber);
    } catch (e) {
      throw ReservationException(
        ReservationErrorCode.networkError,
        'Libération forcée indisponible hors ligne.',
        hizbNumber,
      );
    }
  }

  ReservationException _mapApiException(
    ApiException e,
    int? hizbNumber,
  ) {
    switch (e.code) {
      case ApiErrorCode.authRequired:
      case ApiErrorCode.authInvalid:
        return ReservationException(
          ReservationErrorCode.invalidState,
          'Authentification requise',
          hizbNumber,
        );
      case ApiErrorCode.forbidden:
        return ReservationException(
          ReservationErrorCode.permissionDenied,
          'Permission refusée: ${e.message ?? ''}',
          hizbNumber,
        );
      case ApiErrorCode.notFound:
        return ReservationException(
          ReservationErrorCode.invalidState,
          'Khatma ou Hizb introuvable',
          hizbNumber,
        );
      case ApiErrorCode.conflict:
        return ReservationException(
          ReservationErrorCode.alreadyReserved,
          e.message ?? 'Hizb déjà réservé',
          hizbNumber,
        );
      case ApiErrorCode.invalidArgument:
        return ReservationException(
          ReservationErrorCode.invalidState,
          e.message ?? 'Requête invalide',
          hizbNumber,
        );
      case ApiErrorCode.networkError:
      case ApiErrorCode.timeout:
      case ApiErrorCode.rateLimited:
        return ReservationException(
          ReservationErrorCode.networkError,
          'Serveur indisponible',
          hizbNumber,
        );
      case ApiErrorCode.internal:
      case ApiErrorCode.unknown:
      default:
        return ReservationException(
          ReservationErrorCode.networkError,
          'Erreur: ${e.code} - ${e.message ?? ''}',
          hizbNumber,
        );
    }
  }
}
