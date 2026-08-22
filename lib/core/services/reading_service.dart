import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../constants/app_constants.dart';
import '../constants/hizb_definitions.dart';
import '../constants/reservation_config.dart';
import '../constants/reservation_schema.dart';
import '../models/home_dashboard_state.dart';
import '../models/hizb_reservation.dart';
import '../models/khatma.dart';
import '../models/khatma_load_result.dart';
import '../models/reading_progress.dart';
import '../repositories/hizb_index_repository.dart';
import '../utils/auth_diag.dart';
import '../utils/firestore_access.dart';
import '../utils/my_khatmat_utils.dart';
import 'guest_service.dart';
import 'hizb_reservation_repository.dart';
import 'reading_history_service.dart';

/// Erreur quand un Hizb n'est plus disponible (conflit temps réel)
class HizbReservationConflictException implements Exception {
  final int hizbNumber;
  HizbReservationConflictException(this.hizbNumber);
}

/// Service de persistance : Firestore + backup local
class ReadingService {
  final _historyService = ReadingHistoryService();
  final _reservationRepo = HizbReservationRepository();
  static const _khatmatKey = 'anis_khatmat';
  static const _progressKey = 'anis_progress';

  /// Firestore peut être indisponible si Firebase n'est pas initialisé (ex: Android sans google-services.json)
  FirebaseFirestore? get _firestore {
    try {
      return FirebaseFirestore.instance;
    } catch (_) {
      return null;
    }
  }

  /// Charge une Khatma par ID avec erreurs explicites (navigation / deep links).
  /// Ne retombe jamais sur le cache local en cas de permission refusée Firestore.
  Future<Khatma> loadKhatmaById(String khatmaId) async {
    if (khatmaId.isEmpty) {
      throw KhatmaNotFoundException(khatmaId);
    }

    final fs = _firestore;
    if (fs != null) {
      try {
        final doc = await fs.collection('khatmat').doc(khatmaId).get();
        if (doc.exists) {
          var khatma = Khatma.fromMap({...doc.data()!, 'id': doc.id});
          if (khatma.reservationMode && !khatmaId.startsWith('local_')) {
            khatma = await _reservationRepo.migrateIfNeeded(khatma);
          }
          return khatma;
        }
        if (khatmaId.startsWith('local_')) {
          final local = await _findLocalKhatma(khatmaId);
          if (local != null) return local;
        }
        throw KhatmaNotFoundException(khatmaId);
      } on KhatmaNotFoundException {
        rethrow;
      } on KhatmaAccessDeniedException {
        rethrow;
      } on KhatmaNetworkException {
        rethrow;
      } on FirebaseException catch (e) {
        logFirestoreAccess(
          'loadKhatmaById',
          e,
          hasFirebaseAuth: _firebaseUser != null,
        );
        if (e.code == 'permission-denied') {
          throw KhatmaAccessDeniedException(khatmaId);
        }
        if (e.code == 'unavailable' ||
            e.code == 'deadline-exceeded' ||
            e.code == 'network-request-failed') {
          throw KhatmaNetworkException(khatmaId);
        }
        throw KhatmaNetworkException(khatmaId);
      }
    }

    final local = await _findLocalKhatma(khatmaId);
    if (local != null) return local;
    throw KhatmaNotFoundException(khatmaId);
  }

  Future<Khatma?> _findLocalKhatma(String khatmaId) async {
    final list = await _getKhatmatLocal();
    for (final k in list) {
      if (k.id == khatmaId) return k;
    }
    return null;
  }

  Future<Khatma?> getKhatmaById(String khatmaId) async {
    try {
      return await loadKhatmaById(khatmaId);
    } on KhatmaNotFoundException {
      return null;
    } on KhatmaAccessDeniedException {
      return null;
    } on KhatmaNetworkException {
      return null;
    }
  }

  /// Stream temps réel d'une Khatma (parent + sous-collection réservations).
  Stream<Khatma?> streamKhatmaById(String khatmaId) {
    final fs = _firestore;
    if (fs != null) {
      try {
        final parentStream =
            fs.collection('khatmat').doc(khatmaId).snapshots();
        final reservationsStream =
            _reservationRepo.collectionRef(khatmaId).snapshots();
        return combineKhatmaAndReservationsStream(
          parentStream,
          reservationsStream,
          _reservationRepo,
          khatmaId,
        );
      } catch (_) {}
    }
    return Stream.value(null);
  }

  /// Khatmas publiques (rejoignables par tous) — pagination 50 par page
  static const int _publicPageSize = 50;

  Future<List<Khatma>> getPublicKhatmat({DocumentSnapshot? startAfter}) async {
    final fs = _firestore;
    if (fs == null) return [];
    if (_firebaseUser == null) {
      await AuthDiag.logContext('getPublicKhatmat');
      return [];
    }
    try {
      var query = fs
          .collection('khatmat')
          .where('isPublic', isEqualTo: true)
          .where('reservationMode', isEqualTo: true)
          .orderBy('createdAt', descending: true)
          .limit(_publicPageSize);
      if (startAfter != null) {
        query = query.startAfterDocument(startAfter);
      }
      final snapshot = await query.get();
      return snapshot.docs
          .map((d) => Khatma.fromMap({...d.data(), 'id': d.id}))
          .toList();
    } catch (e) {
      logFirestoreAccess(
        'getPublicKhatmat',
        e,
        hasFirebaseAuth: _firebaseUser != null,
      );
      return [];
    }
  }

  /// Admin : récupère toutes les Khatmas (Firestore uniquement)
  Future<List<Khatma>> getAllKhatmatAdmin() async {
    final fs = _firestore;
    if (fs == null) return [];
    try {
      final snapshot = await fs.collection('khatmat').limit(200).get();
      final list = snapshot.docs
          .map((d) => Khatma.fromMap({...d.data(), 'id': d.id}))
          .toList();
      list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return list;
    } catch (e) {
      debugPrint('ReadingService.getAllKhatmatAdmin: $e');
      return [];
    }
  }

  static const int _khatmatLimit = 100;

  User? get _firebaseUser {
    try {
      return FirebaseAuth.instance.currentUser;
    } catch (_) {
      return null;
    }
  }

  /// Toutes les Khatmas de l'utilisateur (créées, rejointes membre, invité).
  ///
  /// N'interroge Firestore que si un token Firebase est présent. Les constraints
  /// de chaque query sont alignées sur les rules (`createdBy` / `members` /
  /// `participantIds` = email du token ou uid). Une query trop large ferait
  /// refuser **toute** la liste : chaque query est donc isolée.
  Future<List<Khatma>> getMyKhatmat({
    String? email,
    String? authUid,
  }) async {
    await AuthDiag.logContext('getMyKhatmat');
    final localList = await _getKhatmatLocal();
    final user = _firebaseUser;
    final plan = planMyKhatmatQueries(
      isDemo: false,
      hasFirebaseAuth: user != null,
      isAnonymous: user?.isAnonymous ?? false,
      tokenEmail: user?.email,
      authUid: user?.uid,
    );

    final queryResults = <List<Khatma>>[];
    if (!plan.skipRemote) {
      final fs = _firestore;
      if (fs != null) {
        final col = fs.collection('khatmat');
        Future<List<Khatma>> run(
          String label,
          Query<Map<String, dynamic>> query,
        ) async {
          try {
            final snap = await query.limit(_khatmatLimit).get();
            return snap.docs
                .map((d) => Khatma.fromMap({...d.data(), 'id': d.id}))
                .toList();
          } catch (e) {
            logFirestoreAccess(
              'getMyKhatmat.$label',
              e,
              hasFirebaseAuth: true,
            );
            return const [];
          }
        }

        final futures = <Future<List<Khatma>>>[];
        if (plan.queryCreatedBy) {
          futures.add(run(
            'createdBy',
            col
                .where('createdBy', isEqualTo: plan.email)
                .orderBy('createdAt', descending: true),
          ));
        }
        if (plan.queryMembers) {
          futures.add(run(
            'members',
            col
                .where('members', arrayContains: plan.email)
                .orderBy('createdAt', descending: true),
          ));
        }
        if (plan.queryParticipantEmail) {
          futures.add(run(
            'participantEmail',
            col
                .where('participantIds', arrayContains: plan.email)
                .orderBy('createdAt', descending: true),
          ));
        }
        if (plan.queryParticipantUid) {
          futures.add(run(
            'participantUid',
            col
                .where('participantIds', arrayContains: plan.authUid)
                .orderBy('createdAt', descending: true),
          ));
        }

        queryResults.addAll(await Future.wait(futures));

        final uid = plan.authUid;
        if (uid != null && uid.isNotEmpty) {
          final guestIds = await GuestService().getJoinedKhatmaIds();
          final mergedSoFar = mergeMyKhatmatQueries(queryResults);
          final knownIds = mergedSoFar.map((k) => k.id).toSet();
          for (final id in guestIds) {
            if (knownIds.contains(id)) continue;
            final k = await getKhatmaById(id);
            if (k != null &&
                (k.guestParticipants.containsKey(uid) ||
                    k.participantIds.contains(uid))) {
              queryResults.add([k]);
              await _backfillParticipantId(id, uid);
            }
          }
        }
      }
    }

    final filterEmail = plan.skipRemote ? email : plan.email;
    final filterUid = plan.skipRemote ? authUid : plan.authUid;

    var merged = mergeMyKhatmatQueries(queryResults);
    merged = merged
        .where((k) => userBelongsToKhatma(k, email: filterEmail, authUid: filterUid))
        .toList();

    final firestoreIds = merged.map((k) => k.id).toSet();
    for (final k in localList) {
      if (!firestoreIds.contains(k.id) &&
          userBelongsToKhatma(k, email: filterEmail, authUid: filterUid)) {
        merged.add(k);
      }
    }

    merged.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return merged;
  }

  /// @deprecated Utiliser [getMyKhatmat].
  Future<List<Khatma>> getKhatmat(String userId) =>
      getMyKhatmat(email: userId);

  Future<void> _backfillParticipantId(String khatmaId, String participantId) async {
    final fs = _firestore;
    if (fs == null || participantId.isEmpty) return;
    try {
      await fs.collection('khatmat').doc(khatmaId).update({
        'participantIds': FieldValue.arrayUnion([participantId]),
      });
    } catch (e) {
      debugPrint('ReadingService._backfillParticipantId: $e');
    }
  }

  /// Une seule requête pour toute la progression utilisateur (évite N+1).
  Future<Map<String, ReadingProgress>> getProgressMapForUser(String userId) async {
    final map = <String, ReadingProgress>{};
    final fs = _firestore;
    if (fs != null) {
      try {
        final snap = await fs
            .collection('reading_progress')
            .where('userId', isEqualTo: userId)
            .get();
        for (final doc in snap.docs) {
          final data = doc.data();
          final khatmaId = data['khatmaId'] as String? ?? '';
          if (khatmaId.isEmpty) continue;
          map[khatmaId] = ReadingProgress.fromMap({...data, 'khatmaId': khatmaId});
        }
        return map;
      } catch (_) {}
    }
    final prefs = await SharedPreferences.getInstance();
    for (final key in prefs.getKeys().where((k) => k.startsWith(_progressKey))) {
      if (!key.contains(userId)) continue;
      final json = prefs.getString(key);
      if (json == null) continue;
      final p = ReadingProgress.fromMap(jsonDecode(json) as Map<String, dynamic>);
      map[p.khatmaId] = p;
    }
    return map;
  }

  Future<List<Khatma>> _getKhatmatLocal() async {
    final prefs = await SharedPreferences.getInstance();
    final json = prefs.getString(_khatmatKey);
    if (json == null) return [];
    final list = jsonDecode(json) as List;
    return list.map((e) => Khatma.fromMap(e as Map<String, dynamic>)).toList();
  }

  /// Sauvegarde une Khatma. Retourne la Khatma avec l'id Firestore si c'était un local_.
  Future<Khatma> saveKhatma(Khatma khatma) async {
    await AuthDiag.logContext('saveKhatma', refreshToken: true);

    if (khatma.id.startsWith('local_')) {
      HizbDefinitions.requireSupported(khatma.hizbDefinitionId);
    }

    final identity = ParticipantIdentity.fromFirebaseAuth();
    var toSave = khatma;
    if (identity != null && identity.canWriteKhatma) {
      final email = identity.canonicalId;
      final ids = {...khatma.participantIds, email}.toList();
      toSave = khatma.copyWith(createdBy: email, participantIds: ids);
    }

    final prefs = await SharedPreferences.getInstance();
    final list = await _getKhatmatLocal();
    final index = list.indexWhere((k) => k.id == toSave.id);
    if (index >= 0) {
      list[index] = toSave;
    } else {
      list.insert(0, toSave);
    }
    await prefs.setString(_khatmatKey, jsonEncode(list.map((k) => k.toMap()).toList()));
    final fs = _firestore;
    if (fs != null) {
      if (identity == null || !identity.canWriteKhatma) {
        if (kDebugMode) {
          debugPrint(
            '[AuthDiag] saveKhatma skip remote: member email auth required '
            '(identity=${identity?.type.name ?? 'null'})',
          );
        }
        return toSave;
      }
      try {
        if (toSave.id.startsWith('local_')) {
          final canonicalToSave = toSave.copyWith(
            reservationSchemaVersion: ReservationSchema.subcollection,
            completedHizbCount: 0,
          );
          final data = canonicalToSave.toMap();
          data.remove('id');
          data.remove('hizbReservations');
          if (toSave.createdBy.isNotEmpty) {
            data['participantIds'] = [toSave.createdBy];
          }
          final doc = await fs.collection('khatmat').add(data);
          final updated = canonicalToSave.copyWith(
            id: doc.id,
          );
          await _reservationRepo.initializeSubcollection(
            doc.id,
            hizbDefinitionId: updated.hizbDefinitionId,
          );
          final newList = list.map((k) => k.id == khatma.id ? updated : k).toList();
          await prefs.setString(_khatmatKey, jsonEncode(newList.map((k) => k.toMap()).toList()));
          return updated;
        } else {
          final data = toSave.toMap();
          data.remove('id');
          await fs.collection('khatmat').doc(toSave.id).set(data, SetOptions(merge: true));
        }
      } on FirebaseException catch (e) {
        logFirestoreAccess(
          'saveKhatma',
          e,
          hasFirebaseAuth: _firebaseUser != null,
        );
        if (kDebugMode) {
          debugPrint(
            '[AuthDiag] saveKhatma denied: createdBy=${toSave.createdBy.isNotEmpty} '
            'rules require auth+email+createdBy==token.email',
          );
        }
      } catch (e) {
        debugPrint('ReadingService.saveKhatma Firestore: $e');
      }
    }
    return toSave;
  }

  Future<ReadingProgress?> getProgress(String khatmaId, String userId) async {
    final fs = _firestore;
    if (fs != null) {
      try {
        final doc = await fs
            .collection('reading_progress')
            .doc('${khatmaId}_$userId')
            .get();
        if (doc.exists) {
          return ReadingProgress.fromMap({...doc.data()!, 'khatmaId': khatmaId, 'userId': userId});
        }
      } catch (_) {}
    }
    return await _getProgressLocal(khatmaId, userId);
  }

  Future<ReadingProgress?> _getProgressLocal(String khatmaId, String userId) async {
    final prefs = await SharedPreferences.getInstance();
    final map = prefs.getString('$_progressKey$khatmaId\$$userId');
    if (map == null) return null;
    return ReadingProgress.fromMap(jsonDecode(map) as Map<String, dynamic>);
  }

  Future<void> toggleHizbCompleted(String khatmaId, String userId, int hizbNumber) async {
    final progress = await getProgress(khatmaId, userId) ??
        ReadingProgress(khatmaId: khatmaId, userId: userId, lastUpdated: DateTime.now());
    final newSet = Set<int>.from(progress.completedHizb);
    if (newSet.contains(hizbNumber)) {
      newSet.remove(hizbNumber);
    } else {
      newSet.add(hizbNumber);
      await _historyService.logHizbCompleted(userId, DateTime.now());
    }
    final updated = progress.copyWith(
      completedHizb: newSet,
      lastUpdated: DateTime.now(),
    );
    await saveProgress(updated);
  }

  Future<void> saveProgress(ReadingProgress progress) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      '$_progressKey${progress.khatmaId}\$${progress.userId}',
      jsonEncode(progress.toMap()),
    );
    final fs = _firestore;
    if (fs != null) {
      try {
        await fs
            .collection('reading_progress')
            .doc('${progress.khatmaId}_${progress.userId}')
            .set(progress.toMap());
      } catch (_) {}
    }
  }

  /// Réserve un Hizb (mode collaboratif). Lance [HizbReservationConflictException] si déjà pris.
  /// Fallback local uniquement pour Khatmas local_* (hors sync collective production).
  Future<void> reserveHizb(
    String khatmaId,
    int hizbNumber,
    String userId, {
    String? reservedForName,
  }) async {
    final khatma = await getKhatmaById(khatmaId);
    if (khatma == null || !khatma.reservationMode) return;
    if (!khatma.id.startsWith('local_') && _firestore == null) {
      throw HizbReservationConflictException(hizbNumber);
    }

    final reservations = Map<int, HizbReservation>.from(khatma.hizbReservations);
    var current = reservations[hizbNumber] ??
        HizbIndexRepository.reservationSnapshot(
          hizbNumber,
          definitionId: khatma.hizbDefinitionId,
        );
    // Résoudre les états expirés
    if (current.isSoftLocked && current.softLockExpiresAt != null &&
        DateTime.now().isAfter(current.softLockExpiresAt!)) {
      current = current.transitionTo(
        status: HizbReservationStatus.available,
      );
    }
    if (current.isReserved && current.expiresAt != null &&
        DateTime.now().isAfter(current.expiresAt!)) {
      current = current.transitionTo(
        status: HizbReservationStatus.expired,
      );
    }

    if (!current.isAvailable) {
      throw HizbReservationConflictException(hizbNumber);
    }

    final now = DateTime.now();
    final expiresAt = now.add(Duration(hours: ReservationConfig.reservationExpirationHours));
    reservations[hizbNumber] = current.transitionTo(
      status: HizbReservationStatus.reserved,
      reservedBy: userId,
      reservedForName: reservedForName?.trim().isNotEmpty == true ? reservedForName!.trim() : null,
      reservedAt: now,
      expiresAt: expiresAt,
    );

    final updated = khatma.copyWith(hizbReservations: reservations);
    await saveKhatma(updated);
  }

  /// Libère une réservation (annulation par le participant).
  /// Fallback local uniquement pour Khatmas local_*.
  Future<void> releaseHizb(String khatmaId, int hizbNumber, String userId) async {
    final khatma = await getKhatmaById(khatmaId);
    if (khatma == null || !khatma.reservationMode) return;
    if (!khatma.id.startsWith('local_') && _firestore == null) {
      throw HizbReservationConflictException(hizbNumber);
    }

    final current = khatma.hizbReservations[hizbNumber];
    if (current == null || current.reservedBy != userId || !current.isReserved) {
      return;
    }

    final reservations = Map<int, HizbReservation>.from(khatma.hizbReservations);
    reservations[hizbNumber] = current.transitionTo(
      status: HizbReservationStatus.available,
    );

    final updated = khatma.copyWith(hizbReservations: reservations);
    await saveKhatma(updated);
  }

  /// Marque un Hizb réservé comme terminé (lu)
  /// [authUid] : requis pour invités (guestId) — Firebase Auth UID pour règles Firestore
  Future<void> completeHizbReservation(
    String khatmaId,
    int hizbNumber,
    String userId, {
    String? authUid,
  }) async {
    final khatma = await getKhatmaById(khatmaId);
    if (khatma == null || !khatma.reservationMode) return;

    final current = khatma.hizbReservations[hizbNumber];
    if (current == null || current.reservedBy != userId || !current.isReserved) {
      return;
    }

    final now = DateTime.now();
    final reservations = Map<int, HizbReservation>.from(khatma.hizbReservations);
    reservations[hizbNumber] = current.copyWith(
      status: HizbReservationStatus.completed,
      completedAt: now,
    );

    final updated = khatma.copyWith(hizbReservations: reservations);
    await saveKhatma(updated);

    await _historyService.logHizbCompleted(userId, now);
    final progress = await getProgress(khatmaId, userId) ??
        ReadingProgress(khatmaId: khatmaId, userId: userId, lastUpdated: now, authUid: authUid);
    final newSet = Set<int>.from(progress.completedHizb)..add(hizbNumber);
    await saveProgress(progress.copyWith(
      completedHizb: newSet,
      lastUpdated: now,
      authUid: authUid ?? progress.authUid,
    ));
  }

  /// Ajoute un invité (Firebase Anonymous UID) à une Khatma.
  /// [authUid] = request.auth.uid (clé canonique guestParticipants).
  /// [legacyGuestId] : ancien guest_{uuid} — migre les réservations vers authUid.
  Future<void> addGuestToKhatma(
    String khatmaId,
    String authUid,
    String name, {
    String? legacyGuestId,
  }) async {
    final fs = _firestore;
    if (fs == null) {
      debugPrint('ReadingService.addGuestToKhatma: Firestore indisponible');
      return;
    }

    final docRef = fs.collection('khatmat').doc(khatmaId);
    final needsMigration = legacyGuestId != null &&
        legacyGuestId.isNotEmpty &&
        legacyGuestId.startsWith('guest_') &&
        legacyGuestId != authUid;

    if (needsMigration) {
      await fs.runTransaction((tx) async {
        final doc = await tx.get(docRef);
        if (!doc.exists) return;
        final khatma = Khatma.fromMap({...doc.data()!, 'id': doc.id});
        final guests = Map<String, String>.from(khatma.guestParticipants);
        guests[authUid] = name.trim();

        tx.update(docRef, {
          'guestParticipants': guests,
          'participantIds': FieldValue.arrayUnion([authUid]),
        });

        if (khatma.reservationSchemaVersion >= ReservationSchema.subcollection) {
          for (var i = 1; i <= AppConstants.totalHizb; i++) {
            final d = await tx.get(
              docRef.collection(ReservationSchema.subcollectionName).doc(i.toString()),
            );
            if (!d.exists || d.data() == null) continue;
            final r = HizbReservation.fromMap(d.data()!);
            var updated = r;
            if (r.reservedBy == legacyGuestId) {
              updated = updated.copyWith(reservedBy: authUid);
            }
            if (r.softLockedBy == legacyGuestId) {
              updated = updated.copyWith(softLockedBy: authUid);
            }
            if (updated != r) {
              tx.update(d.reference, updated.toMap(hizbNumberOverride: i));
            }
          }
        } else {
          final reservations = Map<int, HizbReservation>.from(khatma.hizbReservations);
          for (final entry in reservations.entries.toList()) {
            final r = entry.value;
            var updated = r;
            if (r.reservedBy == legacyGuestId) {
              updated = updated.copyWith(reservedBy: authUid);
            }
            if (r.softLockedBy == legacyGuestId) {
              updated = updated.copyWith(softLockedBy: authUid);
            }
            if (updated != r) {
              reservations[entry.key] = updated;
            }
          }
          tx.update(docRef, {
            'hizbReservations':
                reservations.map((k, v) => MapEntry(k.toString(), v.toMap())),
          });
        }
      });
      return;
    }

    await docRef.update({
      'guestParticipants.$authUid': name.trim(),
      'participantIds': FieldValue.arrayUnion([authUid]),
    });
  }

  /// Ajoute un membre (avec compte) à une Khatma — mise à jour partielle Firestore.
  Future<void> addMemberToKhatma(String khatmaId, String memberEmail, {String? displayName}) async {
    final fs = _firestore;
    if (fs == null) {
      debugPrint('ReadingService.addMemberToKhatma: Firestore indisponible');
      return;
    }

    final updates = <String, dynamic>{
      'members': FieldValue.arrayUnion([memberEmail]),
      'participantIds': FieldValue.arrayUnion([memberEmail]),
    };
    if (displayName != null && displayName.trim().isNotEmpty) {
      updates['guestParticipants.$memberEmail'] = displayName.trim();
    }
    await fs.collection('khatmat').doc(khatmaId).update(updates);
  }

  /// Initialise les 60 Hizb en mode disponible pour une nouvelle Khatma réservation
  Map<int, HizbReservation> createEmptyReservations({
    required String? hizbDefinitionId,
  }) {
    final map = <int, HizbReservation>{};
    for (var i = 1; i <= AppConstants.totalHizb; i++) {
      map[i] = HizbIndexRepository.reservationSnapshot(
        i,
        definitionId: hizbDefinitionId,
      );
    }
    return map;
  }

  /// Compte le total de Hizb complétés pour une Khatma en mode classique
  /// (union des completedHizb de tous les participants)
  Future<int> getClassicModeCompletedCount(String khatmaId) async {
    final fs = _firestore;
    if (fs != null) {
      try {
        final snapshot = await fs
            .collection('reading_progress')
            .where('khatmaId', isEqualTo: khatmaId)
            .get();
        final allCompleted = <int>{};
        for (final doc in snapshot.docs) {
          final progress = ReadingProgress.fromMap(doc.data());
          allCompleted.addAll(progress.completedHizb);
        }
        return allCompleted.length;
      } catch (_) {}
    }
    final prefs = await SharedPreferences.getInstance();
    final keys = prefs.getKeys().where((k) => k.startsWith('$_progressKey$khatmaId\$'));
    final allCompleted = <int>{};
    for (final key in keys) {
      final json = prefs.getString(key);
      if (json != null) {
        final p = ReadingProgress.fromMap(jsonDecode(json) as Map<String, dynamic>);
        allCompleted.addAll(p.completedHizb);
      }
    }
    return allCompleted.length;
  }

  /// Réservations actives de l'utilisateur (v2 sous-collection) — 1 requête collection group.
  ///
  /// La rule collectionGroup n'autorise que `reservedBy == canonicalId()`.
  /// [participantId] doit donc être l'email du token ou l'uid anonyme — jamais
  /// une identité synthétique (demo@test.com) sans session.
  Future<Map<String, UserKhatmaReservationInfo>> fetchUserActiveReservationsFromSubcollection(
    String participantId,
  ) async {
    final fs = _firestore;
    final user = _firebaseUser;
    if (fs == null || participantId.isEmpty || user == null) return {};

    final canonical = user.isAnonymous
        ? user.uid
        : (user.email?.trim().isNotEmpty == true ? user.email!.trim() : user.uid);
    if (canonical != participantId) {
      if (kDebugMode) {
        debugPrint(
          '[FirestoreAccess] reservations.canonicalMismatch '
          '${FirestoreAccessCode.khatmaAccessDenied.name}',
        );
      }
      return {};
    }

    try {
      final snap = await fs
          .collectionGroup(ReservationSchema.subcollectionName)
          .where('reservedBy', isEqualTo: participantId)
          .limit(40)
          .get();

      final map = <String, UserKhatmaReservationInfo>{};
      for (final doc in snap.docs) {
        final data = doc.data();
        final statusStr = data['status'] as String? ?? '';
        if (statusStr != 'reserved' && statusStr != 'inProgress') continue;

        final khatmaId = doc.reference.parent.parent?.id;
        if (khatmaId == null || khatmaId.isEmpty) continue;

        final hizbNumber = (data['hizbNumber'] as num?)?.toInt() ??
            int.tryParse(doc.id) ??
            0;
        if (hizbNumber < 1) continue;

        DateTime? reservedAt;
        final raw = data['reservedAt'];
        if (raw is String) {
          reservedAt = DateTime.tryParse(raw);
        }

        final candidate = UserKhatmaReservationInfo(
          khatmaId: khatmaId,
          hizbNumber: hizbNumber,
          reservedAt: reservedAt,
          inProgress: statusStr == 'inProgress',
        );

        final existing = map[khatmaId];
        if (existing == null) {
          map[khatmaId] = candidate;
          continue;
        }
        final a = candidate.reservedAt;
        final b = existing.reservedAt;
        if (a != null && (b == null || a.isAfter(b))) {
          map[khatmaId] = candidate;
        }
      }
      return map;
    } catch (e) {
      logFirestoreAccess(
        'fetchUserActiveReservations',
        e,
        hasFirebaseAuth: true,
      );
      return {};
    }
  }

  Future<int> getTotalCompletedHizb(String userId) async {
    final prefs = await SharedPreferences.getInstance();
    final keys = prefs.getKeys().where((k) => k.startsWith(_progressKey));
    int total = 0;
    for (final key in keys) {
      if (key.contains(userId)) {
        final json = prefs.getString(key);
        if (json != null) {
          final p = ReadingProgress.fromMap(jsonDecode(json) as Map<String, dynamic>);
          total += p.completedCount;
        }
      }
    }
    return total;
  }
}
