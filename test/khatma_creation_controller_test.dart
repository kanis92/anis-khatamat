import 'package:flutter_test/flutter_test.dart';

import 'package:anis_khatamat/core/models/khatma.dart';
import 'package:anis_khatamat/core/models/khatma_creation_failure.dart';
import 'package:anis_khatamat/core/models/khatma_creation_state.dart';
import 'package:anis_khatamat/core/providers/khatma_creation_provider.dart';
import 'package:anis_khatamat/core/services/khatma_creation_service.dart';

class _FakeCreator implements KhatmaCreator {
  _FakeCreator({this.onCreate});

  static const fixedId = 'alloc-1';
  final Future<Khatma> Function({
    required String title,
    required String createdBy,
    required bool isGroup,
    required bool isPublic,
    required String? hizbDefinitionId,
    String? resumeKhatmaId,
    String? objectives,
    List<String> members,
  })? onCreate;

  int allocateCount = 0;
  int createCount = 0;
  final List<String?> resumeIds = [];

  @override
  String allocateKhatmaId() {
    allocateCount++;
    return fixedId;
  }

  @override
  Future<Khatma> createKhatma({
    required String title,
    required String createdBy,
    required bool isGroup,
    required bool isPublic,
    required String? hizbDefinitionId,
    String? resumeKhatmaId,
    String? objectives,
    List<String> members = const [],
  }) async {
    createCount++;
    resumeIds.add(resumeKhatmaId);
    if (onCreate != null) {
      return onCreate!(
        title: title,
        createdBy: createdBy,
        isGroup: isGroup,
        isPublic: isPublic,
        hizbDefinitionId: hizbDefinitionId,
        resumeKhatmaId: resumeKhatmaId,
        objectives: objectives,
        members: members,
      );
    }
    return Khatma(
      id: resumeKhatmaId ?? fixedId,
      title: title,
      createdBy: createdBy,
      createdAt: DateTime(2026, 1, 1),
      isGroup: isGroup,
      isPublic: isPublic,
      reservationMode: true,
      creationState: KhatmaCreationState.ready,
    );
  }
}

void main() {
  KhatmaCreationController controllerOf(_FakeCreator fake) {
    return KhatmaCreationController(fake);
  }

  Future<Khatma> submit(KhatmaCreationController c) {
    return c.submit(
      title: 'Famille',
      createdBy: 'jaouad@test.com',
      isGroup: true,
      isPublic: false,
      hizbDefinitionId: null,
    );
  }

  test('preallocated ID is stable and reused on retry', () async {
    var failOnce = true;
    final fake = _FakeCreator(
      onCreate: ({
        required title,
        required createdBy,
        required isGroup,
        required isPublic,
        required hizbDefinitionId,
        resumeKhatmaId,
        objectives,
        members = const [],
      }) async {
        if (failOnce) {
          failOnce = false;
          throw NetworkError(khatmaId: resumeKhatmaId);
        }
        return Khatma(
          id: resumeKhatmaId ?? 'alloc-1',
          title: title,
          createdBy: createdBy,
          createdAt: DateTime(2026, 1, 1),
          isGroup: true,
          reservationMode: true,
          creationState: KhatmaCreationState.ready,
        );
      },
    );
    final c = controllerOf(fake);

    try {
      await submit(c);
      fail('expected network failure');
    } on NetworkError catch (e) {
      expect(e.khatmaId, 'alloc-1');
    }
    expect(c.state.khatmaId, 'alloc-1');
    expect(c.state.phase, KhatmaCreationPhase.idle);

    final ready = await submit(c);
    expect(ready.id, 'alloc-1');
    expect(fake.allocateCount, 1);
    expect(fake.createCount, 2);
    expect(fake.resumeIds, ['alloc-1', 'alloc-1']);
    expect(c.state.phase, KhatmaCreationPhase.ready);
  });

  test('duplicate tap while busy is rejected and does not allocate twice', () async {
    final fake = _FakeCreator(
      onCreate: ({
        required title,
        required createdBy,
        required isGroup,
        required isPublic,
        required hizbDefinitionId,
        resumeKhatmaId,
        objectives,
        members = const [],
      }) async {
        await Future<void>.delayed(const Duration(milliseconds: 30));
        return Khatma(
          id: resumeKhatmaId ?? 'alloc-1',
          title: title,
          createdBy: createdBy,
          createdAt: DateTime(2026, 1, 1),
          isGroup: true,
          reservationMode: true,
          creationState: KhatmaCreationState.ready,
        );
      },
    );
    final c = controllerOf(fake);
    final first = submit(c);
    expect(c.state.isBusy, isTrue);
    expect(submit(c), throwsA(isA<UnknownCreationError>()));
    final ready = await first;
    expect(ready.id, 'alloc-1');
    expect(fake.createCount, 1);
    expect(fake.allocateCount, 1);
  });

  test('typed failures propagate and keep allocated id', () async {
    final fake = _FakeCreator(
      onCreate: ({
        required title,
        required createdBy,
        required isGroup,
        required isPublic,
        required hizbDefinitionId,
        resumeKhatmaId,
        objectives,
        members = const [],
      }) async {
        throw PermissionDenied(khatmaId: resumeKhatmaId);
      },
    );
    final c = controllerOf(fake);
    expect(submit(c), throwsA(isA<PermissionDenied>()));
    await Future<void>.delayed(Duration.zero);
    expect(c.state.failure, isA<PermissionDenied>());
    expect(c.state.khatmaId, 'alloc-1');
    expect(c.state.phase, KhatmaCreationPhase.idle);
  });

  test('returned id must equal allocated id', () async {
    final fake = _FakeCreator(
      onCreate: ({
        required title,
        required createdBy,
        required isGroup,
        required isPublic,
        required hizbDefinitionId,
        resumeKhatmaId,
        objectives,
        members = const [],
      }) async {
        return Khatma(
          id: 'other-id',
          title: title,
          createdBy: createdBy,
          createdAt: DateTime(2026, 1, 1),
          isGroup: true,
          reservationMode: true,
          creationState: KhatmaCreationState.ready,
        );
      },
    );
    final c = controllerOf(fake);
    expect(submit(c), throwsA(isA<InitializationFailed>()));
  });
}
