import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '../constants/app_constants.dart';
import '../constants/reservation_schema.dart';
import '../models/hizb_reservation.dart';
import '../models/khatma.dart';
import '../repositories/hizb_index_repository.dart';

/// Persistance v2 : sous-collection `hizb_reservations` + migration idempotente depuis la map v1.
class HizbReservationRepository {
  HizbReservationRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> _collection(String khatmaId) =>
      _firestore
          .collection('khatmat')
          .doc(khatmaId)
          .collection(ReservationSchema.subcollectionName);

  DocumentReference<Map<String, dynamic>> _hizbDoc(
    String khatmaId,
    int hizbNumber,
  ) =>
      _collection(khatmaId).doc(hizbNumber.toString());

  /// Parse une collection snapshot en map 1..60 (docs absents = available).
  Map<int, HizbReservation> mapFromSnapshot(
    QuerySnapshot<Map<String, dynamic>> snapshot,
  ) {
    final map = <int, HizbReservation>{};
    for (final doc in snapshot.docs) {
      final hizbNum =
          int.tryParse(doc.id) ?? (doc.data()['hizbNumber'] as num?)?.toInt();
      if (hizbNum == null || hizbNum < 1 || hizbNum > AppConstants.totalHizb) {
        continue;
      }
      map[hizbNum] =
          HizbReservation.fromMap(doc.data()).copyWith(hizbNumber: hizbNum);
    }
    return map;
  }

  /// Fusionne sous-collection + map legacy embarquée (sous-collection prioritaire).
  Khatma mergeReservationsIntoKhatma(
    Khatma khatma,
    Map<int, HizbReservation> fromSubcollection,
  ) {
    if (!khatma.reservationMode) return khatma;
    if (fromSubcollection.isEmpty && !khatma.usesSubcollectionReservations) {
      return khatma;
    }

    final merged = <int, HizbReservation>{};
    for (var i = 1; i <= AppConstants.totalHizb; i++) {
      if (fromSubcollection.containsKey(i)) {
        merged[i] = fromSubcollection[i]!;
      } else if (khatma.hizbReservations.containsKey(i)) {
        merged[i] = khatma.hizbReservations[i]!;
      } else if (khatma.hasSupportedHizbDefinition) {
        merged[i] = HizbIndexRepository.reservationSnapshot(
          i,
          definitionId: khatma.hizbDefinitionId,
        );
      } else {
        merged[i] = HizbReservation(hizbNumber: i);
      }
    }
    return khatma.copyWith(hizbReservations: merged);
  }

  Future<Map<int, HizbReservation>> fetchAll(String khatmaId) async {
    final snap = await _collection(khatmaId).get();
    return mapFromSnapshot(snap);
  }

  /// Un seul listener collection (max ~60 docs).
  Stream<Map<int, HizbReservation>> streamAll(String khatmaId) {
    return _collection(khatmaId).snapshots().map(mapFromSnapshot);
  }

  /// Charge les réservations et fusionne dans la Khatma.
  Future<Khatma> enrichKhatma(Khatma khatma) async {
    if (!khatma.reservationMode || khatma.id.startsWith('local_')) {
      return khatma;
    }
    if (khatma.usesSubcollectionReservations) {
      final map = await fetchAll(khatma.id);
      return mergeReservationsIntoKhatma(khatma, map);
    }
    return khatma;
  }

  /// Migration idempotente v1 map → v2 sous-collection.
  /// Relançable sans dommage : ne réécrit pas les docs existants.
  Future<Khatma> migrateIfNeeded(Khatma khatma) async {
    if (!khatma.reservationMode || khatma.id.startsWith('local_')) {
      return khatma;
    }
    // Une Khatma sans définition explicite reste lisible, mais sa signification
    // ne peut pas être transformée automatiquement.
    if (!khatma.hasSupportedHizbDefinition) return khatma;

    final parentRef = _firestore.collection('khatmat').doc(khatma.id);
    final parentSnap = await parentRef.get();
    if (!parentSnap.exists) return khatma;

    final data = parentSnap.data()!;
    final version =
        (data['reservationSchemaVersion'] as num?)?.toInt() ?? ReservationSchema.legacyMap;

    if (version >= ReservationSchema.subcollection) {
      final map = await fetchAll(khatma.id);
      return mergeReservationsIntoKhatma(
        khatma.copyWith(reservationSchemaVersion: version),
        map,
      );
    }

    final existing = await _collection(khatma.id).limit(1).get();
    if (existing.docs.isNotEmpty) {
      await parentRef.update({
        'reservationSchemaVersion': ReservationSchema.subcollection,
      });
      final map = await fetchAll(khatma.id);
      return mergeReservationsIntoKhatma(
        khatma.copyWith(
          reservationSchemaVersion: ReservationSchema.subcollection,
        ),
        map,
      );
    }

    final legacyMap = khatma.hizbReservations;
    final legacyRaw =
        data['hizbReservations'] as Map<String, dynamic>? ?? {};
    final sourceMap = legacyMap.isNotEmpty
        ? legacyMap
        : legacyRaw.map((k, v) {
            final n = int.tryParse(k) ?? 0;
            final m = v is Map<String, dynamic>
                ? v
                : (v as Map).cast<String, dynamic>();
            return MapEntry(n, HizbReservation.fromMap(m));
          });

    var completedCount = 0;
    final batch = _firestore.batch();
    for (var i = 1; i <= AppConstants.totalHizb; i++) {
      final base = HizbIndexRepository.reservationSnapshot(
        i,
        definitionId: khatma.hizbDefinitionId,
      );
      final legacy = sourceMap[i];
      final reservation = legacy == null
          ? base
          : base.transitionTo(
              status: legacy.status,
              reservedBy: legacy.reservedBy,
              reservedForName: legacy.reservedForName,
              reservedAt: legacy.reservedAt,
              expiresAt: legacy.expiresAt,
              completedAt: legacy.completedAt,
              softLockedBy: legacy.softLockedBy,
              softLockExpiresAt: legacy.softLockExpiresAt,
              extendedCount: legacy.extendedCount,
              source: legacy.source,
            );
      if (reservation.isCompleted) completedCount++;
      final docRef = _hizbDoc(khatma.id, i);
      batch.set(
        docRef,
        reservation.toMap(hizbNumberOverride: i),
        SetOptions(merge: true),
      );
    }

    batch.update(parentRef, {
      'reservationSchemaVersion': ReservationSchema.subcollection,
      'completedHizbCount': completedCount,
    });

    await batch.commit();
    debugPrint(
      'HizbReservationRepository: migrated ${khatma.id} → v2 ($completedCount completed)',
    );

    final map = await fetchAll(khatma.id);
    return mergeReservationsIntoKhatma(
      khatma.copyWith(
        reservationSchemaVersion: ReservationSchema.subcollection,
        completedHizbCount: completedCount,
      ),
      map,
    );
  }

  /// Initialise 60 documents available pour une nouvelle Khatma v2.
  Future<void> initializeSubcollection(
    String khatmaId, {
    required String? hizbDefinitionId,
  }) async {
    final batch = _firestore.batch();
    for (var i = 1; i <= AppConstants.totalHizb; i++) {
      final snapshot = HizbIndexRepository.reservationSnapshot(
        i,
        definitionId: hizbDefinitionId,
      );
      batch.set(
        _hizbDoc(khatmaId, i),
        snapshot.toMap(hizbNumberOverride: i),
      );
    }
    await batch.commit();
  }

  DocumentReference<Map<String, dynamic>> hizbDocumentRef(
    String khatmaId,
    int hizbNumber,
  ) =>
      _hizbDoc(khatmaId, hizbNumber);

  CollectionReference<Map<String, dynamic>> collectionRef(String khatmaId) =>
      _collection(khatmaId);

  /// Compte les réservations actives d'un participant (reserved + inProgress).
  int countActiveByUser(
    Map<int, HizbReservation> reservations,
    String userId,
  ) =>
      reservations.values
          .where((r) => r.reservedBy == userId && r.isReserved)
          .length;

  int countCompleted(Map<int, HizbReservation> reservations) =>
      reservations.values.where((r) => r.isCompleted).length;

  int countCompletedFromMap(Map<int, HizbReservation> reservations) =>
      countCompleted(reservations);
}

/// Combine le document parent Khatma et la sous-collection en un seul stream.
Stream<Khatma?> combineKhatmaAndReservationsStream(
  Stream<DocumentSnapshot<Map<String, dynamic>>> parentStream,
  Stream<QuerySnapshot<Map<String, dynamic>>> reservationsStream,
  HizbReservationRepository repository,
  String khatmaId,
) {
  Khatma? build(
    DocumentSnapshot<Map<String, dynamic>>? parent,
    QuerySnapshot<Map<String, dynamic>>? reservations,
  ) {
    if (parent == null || !parent.exists) return null;
    var khatma = Khatma.fromMap({...parent.data()!, 'id': parent.id});
    if (khatma.reservationMode && reservations != null) {
      khatma = repository.mergeReservationsIntoKhatma(
        khatma,
        repository.mapFromSnapshot(reservations),
      );
    }
    return khatma;
  }

  DocumentSnapshot<Map<String, dynamic>>? lastParent;
  QuerySnapshot<Map<String, dynamic>>? lastReservations;
  late final StreamController<Khatma?> controller;
  StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>? subParent;
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? subReservations;

  controller = StreamController<Khatma?>.broadcast(
    onListen: () {
      subParent = parentStream.listen((snap) {
        lastParent = snap;
        controller.add(build(lastParent, lastReservations));
      }, onError: controller.addError);
      subReservations = reservationsStream.listen((snap) {
        lastReservations = snap;
        controller.add(build(lastParent, lastReservations));
      }, onError: controller.addError);
    },
    onCancel: () async {
      await subParent?.cancel();
      await subReservations?.cancel();
    },
  );

  return controller.stream;
}
