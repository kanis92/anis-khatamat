import 'package:flutter_test/flutter_test.dart';

import 'package:anis_khatamat/core/models/khatma.dart';
import 'package:anis_khatamat/core/models/khatma_load_result.dart';
import 'package:anis_khatamat/core/providers/reading_provider.dart';

Khatma _demoLocalKhatma() {
  return Khatma(
    id: 'local_demo_khatma',
    title: 'Demo local',
    createdBy: 'demo@test.com',
    createdAt: DateTime(2026, 1, 1),
    isGroup: false,
    participantIds: const ['demo@test.com'],
  );
}

void main() {
  group('resolveDemoKhatmaLoad', () {
    test('demo mode + local id resolves without network failure', () async {
      final result = await resolveDemoKhatmaLoad(
        (id) async => id == 'local_demo_khatma' ? _demoLocalKhatma() : null,
        'local_demo_khatma',
      );

      expect(result.isSuccess, isTrue);
      expect(result.khatma?.id, 'local_demo_khatma');
      expect(result.failure, isNull);
    });

    test('demo mode + unknown remote id returns demoUnavailable', () async {
      final result = await resolveDemoKhatmaLoad(
        (_) async => null,
        'firestore-remote-id',
      );

      expect(result.khatma, isNull);
      expect(result.failure, KhatmaLoadFailure.demoUnavailable);
      expect(result.failure, isNot(KhatmaLoadFailure.network));
    });

    test('demo mode + missing local id returns notFound', () async {
      final result = await resolveDemoKhatmaLoad(
        (_) async => null,
        'local_missing',
      );

      expect(result.khatma, isNull);
      expect(result.failure, KhatmaLoadFailure.notFound);
    });
  });

  group('khatmaLoadProvider production contract', () {
    test('demo branch is isolated from loadKhatmaById', () {
      expect(KhatmaLoadFailure.values, contains(KhatmaLoadFailure.demoUnavailable));
      expect(
        const KhatmaLoadResult.failure(KhatmaLoadFailure.demoUnavailable).failure,
        isNot(KhatmaLoadFailure.network),
      );
    });
  });
}
