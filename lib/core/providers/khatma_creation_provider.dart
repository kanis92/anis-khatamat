import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/khatma.dart';
import '../models/khatma_creation_failure.dart';
import '../services/khatma_creation_service.dart';

final khatmaCreationServiceProvider = Provider<KhatmaCreator>((ref) {
  return KhatmaCreationService(
    firestore: FirebaseFirestore.instance,
  );
});

enum KhatmaCreationPhase { idle, submitting, initializing, ready }

class KhatmaCreationSession {
  const KhatmaCreationSession({
    this.phase = KhatmaCreationPhase.idle,
    this.khatmaId,
    this.failure,
  });

  final KhatmaCreationPhase phase;
  final String? khatmaId;
  final KhatmaCreationFailure? failure;

  bool get isBusy =>
      phase == KhatmaCreationPhase.submitting ||
      phase == KhatmaCreationPhase.initializing;
}

class KhatmaCreationController extends StateNotifier<KhatmaCreationSession> {
  KhatmaCreationController(this._service) : super(const KhatmaCreationSession());

  final KhatmaCreator _service;

  /// Alloue l'ID dès la première tentative ; le retry réutilise le même ID.
  String ensureAllocatedId() {
    final existing = state.khatmaId;
    if (existing != null && existing.isNotEmpty) return existing;
    final id = _service.allocateKhatmaId();
    state = KhatmaCreationSession(khatmaId: id, failure: state.failure);
    return id;
  }

  Future<Khatma> submit({
    required String title,
    required String createdBy,
    required bool isGroup,
    required bool isPublic,
    required String? hizbDefinitionId,
    String? objectives,
    List<String> members = const [],
  }) async {
    if (state.isBusy) {
      throw const UnknownCreationError('duplicate submit ignored');
    }

    final allocatedId = ensureAllocatedId();

    state = KhatmaCreationSession(
      phase: KhatmaCreationPhase.submitting,
      khatmaId: allocatedId,
    );

    try {
      state = KhatmaCreationSession(
        phase: KhatmaCreationPhase.initializing,
        khatmaId: allocatedId,
      );
      final khatma = await _service.createKhatma(
        title: title,
        createdBy: createdBy,
        isGroup: isGroup,
        isPublic: isPublic,
        hizbDefinitionId: hizbDefinitionId,
        resumeKhatmaId: allocatedId,
        objectives: objectives,
        members: members,
      );
      if (khatma.id != allocatedId) {
        throw InitializationFailed(
          'Returned id ${khatma.id} != allocated $allocatedId',
          khatmaId: allocatedId,
        );
      }
      state = KhatmaCreationSession(
        phase: KhatmaCreationPhase.ready,
        khatmaId: khatma.id,
      );
      return khatma;
    } on KhatmaCreationFailure catch (e) {
      state = KhatmaCreationSession(
        phase: KhatmaCreationPhase.idle,
        khatmaId: e.khatmaId ?? allocatedId,
        failure: e,
      );
      rethrow;
    } catch (e) {
      final failure = UnknownCreationError(
        e.runtimeType.toString(),
        khatmaId: allocatedId,
      );
      state = KhatmaCreationSession(
        phase: KhatmaCreationPhase.idle,
        khatmaId: allocatedId,
        failure: failure,
      );
      throw failure;
    }
  }
}

final khatmaCreationControllerProvider =
    StateNotifierProvider.autoDispose<KhatmaCreationController, KhatmaCreationSession>(
  (ref) => KhatmaCreationController(ref.read(khatmaCreationServiceProvider)),
);
