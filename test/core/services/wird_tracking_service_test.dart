import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:anis_khatamat/core/services/wird_tracking_service.dart';
import 'package:anis_khatamat/core/services/wird_rub_tracker.dart';
import 'package:anis_khatamat/core/models/wird.dart';
import 'package:anis_khatamat/core/resolvers/subdivision_definition_resolver.dart';

void main() {
  group('WirdTrackingService', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    test('production service supports exactly Hafs 240 V1', () {
      final service = WirdTrackingService.production();

      final available = service.availableDefinitions;
      expect(available, hasLength(1));
      expect(available, contains('hafs_quran_foundation_rub_240_v1'));
    });

    test('createTracker for Hafs wird returns working tracker', () async {
      final service = WirdTrackingService.production();
      final wird = Wird.defaultWird();

      final tracker = service.createTracker(wird);

      expect(tracker, isA<WirdRubTracker>());

      // Vérifier que le tracker fonctionne
      const userId = 'test@anis.ma';
      await tracker.recordSequentialPageTurn(userId, 'hafs', 1, 2, 2, 27);
      final count = await tracker.getUniqueRubsCompletedToday(userId);
      expect(count, greaterThan(0));
    });

    test('createTracker throws for unknown subdivision definition', () {
      final service = WirdTrackingService.production();
      final wird = Wird(
        subdivisionDefinitionId: 'warsh_wikisource_thumun_480_v1',
        dailyTargetRubs: 4,
        createdAt: DateTime.now(),
      );

      expect(
        () => service.createTracker(wird),
        throwsA(isA<UnknownSubdivisionDefinitionException>()),
      );
    });

    test('isDefinitionSupported returns true for Hafs', () {
      final service = WirdTrackingService.production();
      final wird = Wird.defaultWird();

      expect(service.isDefinitionSupported(wird), true);
    });

    test('isDefinitionSupported returns false for unknown definition', () {
      final service = WirdTrackingService.production();
      final wird = Wird(
        subdivisionDefinitionId: 'warsh_wikisource_thumun_480_v1',
        dailyTargetRubs: 4,
        createdAt: DateTime.now(),
      );

      expect(service.isDefinitionSupported(wird), false);
    });

    test('tracker namespace is derived from definition.id', () async {
      final service = WirdTrackingService.production();
      final wird = Wird.defaultWird();
      final tracker = service.createTracker(wird);

      // Écrire des données avec ce tracker
      const userId = 'test@anis.ma';
      await tracker.recordSequentialPageTurn(userId, 'hafs', 1, 2, 2, 27);

      // Vérifier que les clés utilisent le bon namespace
      final prefs = await SharedPreferences.getInstance();
      final today =
          '${DateTime.now().year}-${DateTime.now().month.toString().padLeft(2, '0')}-${DateTime.now().day.toString().padLeft(2, '0')}';
      final expectedKey =
          'anis_wird_rubs_completed:hafs_quran_foundation_rub_240_v1:$userId:$today';

      expect(prefs.containsKey(expectedKey), true,
          reason: 'Tracker should use namespaced key derived from definition.id');
    });

    test('multiple trackers from different wird instances are independent',
        () async {
      final service = WirdTrackingService.production();

      final wird1 = Wird.defaultWird();
      final wird2 = Wird.defaultWird();

      final tracker1 = service.createTracker(wird1);
      final tracker2 = service.createTracker(wird2);

      // Ils devraient utiliser la même définition Hafs
      const userId1 = 'user1@anis.ma';
      const userId2 = 'user2@anis.ma';

      await tracker1.recordSequentialPageTurn(userId1, 'hafs', 1, 2, 2, 27);
      await tracker2.recordSequentialPageTurn(userId2, 'hafs', 1, 2, 2, 27);

      final count1 = await tracker1.getUniqueRubsCompletedToday(userId1);
      final count2 = await tracker2.getUniqueRubsCompletedToday(userId2);

      expect(count1, greaterThan(0));
      expect(count2, greaterThan(0));

      // Mais les utilisateurs sont différents, donc pas de collision
      final countCross = await tracker1.getUniqueRubsCompletedToday(userId2);
      expect(countCross, greaterThan(0),
          reason: 'Different users but same definition share namespace');
    });

    test('REGRESSION: default Wird uses Hafs definition', () {
      final service = WirdTrackingService.production();
      final wird = Wird.defaultWird();

      expect(wird.subdivisionDefinitionId, 'hafs_quran_foundation_rub_240_v1');
      expect(service.isDefinitionSupported(wird), true);

      final tracker = service.createTracker(wird);
      expect(tracker, isNotNull);
    });

    test('REGRESSION: legacy Wird.fromMap defaults to Hafs and is supported',
        () {
      final service = WirdTrackingService.production();

      // Simuler legacy data sans subdivisionDefinitionId
      final wird = Wird.fromMap({
        'dailyTargetRubs': 4,
        'createdAt': DateTime.now().toIso8601String(),
      });

      expect(wird.subdivisionDefinitionId, 'hafs_quran_foundation_rub_240_v1',
          reason: 'Legacy data should default to Hafs');
      expect(service.isDefinitionSupported(wird), true);

      final tracker = service.createTracker(wird);
      expect(tracker, isNotNull);
    });
  });
}
