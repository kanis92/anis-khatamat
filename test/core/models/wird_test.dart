import 'package:flutter_test/flutter_test.dart';
import 'package:anis_khatamat/core/models/wird.dart';
import 'package:anis_khatamat/core/models/wird_plan.dart';

void main() {
  group('Wird Model — Persistence Migration', () {
    test('legacy JSON without subdivisionDefinitionId defaults to Hafs ID', () {
      // Simuler un ancien enregistrement sans subdivisionDefinitionId
      final legacyJson = {
        'dailyTargetRubs': 4,
        'lastMushafType': 'hafs',
        'lastPage': 42,
        'lastReadAt': '2026-09-03T20:00:00.000Z',
        'createdAt': '2026-01-01T00:00:00.000Z',
      };

      final wird = Wird.fromMap(legacyJson);

      expect(wird.subdivisionDefinitionId, 'hafs_quran_foundation_rub_240_v1',
          reason: 'Legacy records must default to Hafs 240 Rub definition');
      expect(wird.dailyTargetRubs, 4);
      expect(wird.lastMushafType, 'hafs');
      expect(wird.lastPage, 42);
    });

    test('new JSON with subdivisionDefinitionId roundtrips correctly', () {
      final originalWird = Wird(
        subdivisionDefinitionId: 'hafs_quran_foundation_rub_240_v1',
        dailyTargetRubs: 8,
        lastMushafType: 'warsh',
        lastPage: 100,
        lastReadAt: DateTime.parse('2026-09-03T21:00:00.000Z'),
        createdAt: DateTime.parse('2026-02-01T00:00:00.000Z'),
      );

      final json = originalWird.toMap();
      final deserializedWird = Wird.fromMap(json);

      expect(deserializedWird.subdivisionDefinitionId,
          'hafs_quran_foundation_rub_240_v1');
      expect(deserializedWird.dailyTargetRubs, 8);
      expect(deserializedWird.lastMushafType, 'warsh');
      expect(deserializedWird.lastPage, 100);
      expect(deserializedWird.lastReadAt?.toIso8601String(),
          '2026-09-03T21:00:00.000Z');
      expect(deserializedWird.createdAt.toIso8601String(),
          '2026-02-01T00:00:00.000Z');
    });

    test('toMap serializes subdivisionDefinitionId explicitly', () {
      final wird = Wird(
        subdivisionDefinitionId: 'hafs_quran_foundation_rub_240_v1',
        dailyTargetRubs: 4,
        createdAt: DateTime.parse('2026-01-01T00:00:00.000Z'),
      );

      final map = wird.toMap();

      expect(map.containsKey('subdivisionDefinitionId'), true,
          reason: 'toMap must serialize subdivisionDefinitionId');
      expect(map['subdivisionDefinitionId'], 'hafs_quran_foundation_rub_240_v1');
    });

    test('defaultWird has explicit Hafs subdivision definition ID', () {
      final wird = Wird.defaultWird();

      expect(wird.subdivisionDefinitionId, 'hafs_quran_foundation_rub_240_v1',
          reason: 'Default Wird must have explicit Hafs definition');
      expect(wird.dailyTargetRubs, 4);
    });

    test('copyWith preserves ID when omitted', () {
      final original = Wird(
        subdivisionDefinitionId: 'hafs_quran_foundation_rub_240_v1',
        dailyTargetRubs: 4,
        lastMushafType: 'hafs',
        lastPage: 10,
        createdAt: DateTime.parse('2026-01-01T00:00:00.000Z'),
      );

      final updated = original.copyWith(
        dailyTargetRubs: 8,
        lastPage: 20,
      );

      expect(updated.subdivisionDefinitionId, 'hafs_quran_foundation_rub_240_v1',
          reason: 'copyWith must preserve subdivisionDefinitionId when omitted');
      expect(updated.dailyTargetRubs, 8);
      expect(updated.lastPage, 20);
      expect(updated.lastMushafType, 'hafs');
    });

    test('copyWith can explicitly change ID', () {
      final original = Wird(
        subdivisionDefinitionId: 'hafs_quran_foundation_rub_240_v1',
        dailyTargetRubs: 4,
        createdAt: DateTime.parse('2026-01-01T00:00:00.000Z'),
      );

      final updated = original.copyWith(
        subdivisionDefinitionId: 'warsh_wikisource_thumun_480_v1',
        dailyTargetRubs: 8,
      );

      expect(updated.subdivisionDefinitionId, 'warsh_wikisource_thumun_480_v1',
          reason: 'copyWith must update subdivisionDefinitionId when provided');
      expect(updated.dailyTargetRubs, 8);
    });

    test('Equatable treats different subdivisionDefinitionId as different', () {
      final wird1 = Wird(
        subdivisionDefinitionId: 'hafs_quran_foundation_rub_240_v1',
        dailyTargetRubs: 4,
        createdAt: DateTime.parse('2026-01-01T00:00:00.000Z'),
      );

      final wird2 = Wird(
        subdivisionDefinitionId: 'warsh_wikisource_thumun_480_v1',
        dailyTargetRubs: 4,
        createdAt: DateTime.parse('2026-01-01T00:00:00.000Z'),
      );

      expect(wird1 == wird2, false,
          reason: 'Different subdivisionDefinitionId must make Wird instances unequal');
    });

    test('Equatable treats same subdivisionDefinitionId as equal when all fields match', () {
      final createdAt = DateTime.parse('2026-01-01T00:00:00.000Z');

      final wird1 = Wird(
        subdivisionDefinitionId: 'hafs_quran_foundation_rub_240_v1',
        dailyTargetRubs: 4,
        createdAt: createdAt,
      );

      final wird2 = Wird(
        subdivisionDefinitionId: 'hafs_quran_foundation_rub_240_v1',
        dailyTargetRubs: 4,
        createdAt: createdAt,
      );

      expect(wird1 == wird2, true,
          reason: 'Identical Wird instances must be equal');
    });

    test('legacy minimal JSON without optional fields deserializes', () {
      final minimalJson = {
        'dailyTargetRubs': 2,
        'createdAt': '2026-01-01T00:00:00.000Z',
      };

      final wird = Wird.fromMap(minimalJson);

      expect(wird.subdivisionDefinitionId, 'hafs_quran_foundation_rub_240_v1');
      expect(wird.dailyTargetRubs, 2);
      expect(wird.lastMushafType, null);
      expect(wird.lastPage, null);
      expect(wird.lastReadAt, null);
    });

    test('empty legacy JSON gets all defaults', () {
      final emptyJson = <String, dynamic>{};

      final wird = Wird.fromMap(emptyJson);

      expect(wird.subdivisionDefinitionId, 'hafs_quran_foundation_rub_240_v1');
      expect(wird.dailyTargetRubs, 4, reason: 'Default is 1 Hizb = 4 Rub');
      expect(wird.lastMushafType, null);
      expect(wird.lastPage, null);
      expect(wird.lastReadAt, null);
      // createdAt gets DateTime.now() as fallback
      expect(wird.createdAt, isNotNull);
    });
  });

  group('Wird Model — Personal Khatma Plan Integration', () {
    test('legacy Wird without activePlan defaults to free mode (null)', () {
      final legacyJson = {
        'subdivisionDefinitionId': 'hafs_quran_foundation_rub_240_v1',
        'dailyTargetRubs': 4,
        'createdAt': '2026-01-01T00:00:00.000Z',
      };

      final wird = Wird.fromMap(legacyJson);

      expect(wird.activePlan, null,
          reason: 'Legacy Wird without activePlan must remain in free mode');
    });

    test('Wird with activePlan serializes and deserializes correctly', () {
      final plan = WirdPlan(
        id: 'test-plan-id',
        type: WirdPlanType.gregorianMonth,
        subdivisionDefinitionId: 'hafs_quran_foundation_rub_240_v1',
        baselineDate: DateTime(2026, 9, 1),
        endDate: DateTime(2026, 9, 30),
        createdAt: DateTime(2026, 9, 2),
      );

      final wird = Wird(
        subdivisionDefinitionId: 'hafs_quran_foundation_rub_240_v1',
        dailyTargetRubs: 4,
        createdAt: DateTime(2026, 9, 1),
        activePlan: plan,
      );

      final json = wird.toMap();
      expect(json.containsKey('activePlan'), true);

      final restored = Wird.fromMap(json);
      expect(restored.activePlan, isNotNull);
      expect(restored.activePlan!.id, 'test-plan-id');
      expect(restored.activePlan!.type, WirdPlanType.gregorianMonth);
    });

    test('Wird without activePlan omits field from serialization', () {
      final wird = Wird(
        subdivisionDefinitionId: 'hafs_quran_foundation_rub_240_v1',
        dailyTargetRubs: 4,
        createdAt: DateTime(2026, 9, 1),
        activePlan: null,
      );

      final json = wird.toMap();
      expect(json.containsKey('activePlan'), false,
          reason: 'Null activePlan should not be serialized');
    });

    test('copyWith preserves activePlan when omitted', () {
      final plan = WirdPlan(
        id: 'original-plan',
        type: WirdPlanType.hijriMonth,
        subdivisionDefinitionId: 'hafs_quran_foundation_rub_240_v1',
        baselineDate: DateTime(2026, 9, 1),
        createdAt: DateTime(2026, 9, 1),
      );

      final original = Wird(
        subdivisionDefinitionId: 'hafs_quran_foundation_rub_240_v1',
        dailyTargetRubs: 4,
        createdAt: DateTime(2026, 9, 1),
        activePlan: plan,
      );

      final updated = original.copyWith(dailyTargetRubs: 8);

      expect(updated.activePlan, plan);
      expect(updated.dailyTargetRubs, 8);
    });

    test('copyWith can set activePlan', () {
      final original = Wird(
        subdivisionDefinitionId: 'hafs_quran_foundation_rub_240_v1',
        dailyTargetRubs: 4,
        createdAt: DateTime(2026, 9, 1),
        activePlan: null,
      );

      final plan = WirdPlan(
        id: 'new-plan',
        type: WirdPlanType.gregorianMonth,
        subdivisionDefinitionId: 'hafs_quran_foundation_rub_240_v1',
        baselineDate: DateTime(2026, 9, 1),
        createdAt: DateTime(2026, 9, 1),
      );

      final updated = original.copyWith(activePlan: plan);

      expect(updated.activePlan, plan);
    });

    test('subdivisionDefinitionId consistency between Wird and Plan', () {
      final plan = WirdPlan(
        id: 'plan-1',
        type: WirdPlanType.gregorianMonth,
        subdivisionDefinitionId: 'hafs_quran_foundation_rub_240_v1',
        baselineDate: DateTime(2026, 9, 1),
        createdAt: DateTime(2026, 9, 1),
      );

      final wird = Wird(
        subdivisionDefinitionId: 'hafs_quran_foundation_rub_240_v1',
        dailyTargetRubs: 4,
        createdAt: DateTime(2026, 9, 1),
        activePlan: plan,
      );

      expect(wird.subdivisionDefinitionId, wird.activePlan!.subdivisionDefinitionId,
          reason: 'Wird and its active plan must share the same subdivisionDefinitionId');
    });

    test('Equatable includes activePlan in equality', () {
      final plan1 = WirdPlan(
        id: 'plan-1',
        type: WirdPlanType.gregorianMonth,
        subdivisionDefinitionId: 'hafs_quran_foundation_rub_240_v1',
        baselineDate: DateTime(2026, 9, 1),
        createdAt: DateTime(2026, 9, 1),
      );

      final plan2 = WirdPlan(
        id: 'plan-2',
        type: WirdPlanType.hijriMonth,
        subdivisionDefinitionId: 'hafs_quran_foundation_rub_240_v1',
        baselineDate: DateTime(2026, 9, 1),
        createdAt: DateTime(2026, 9, 1),
      );

      final createdAt = DateTime(2026, 9, 1);

      final wird1 = Wird(
        subdivisionDefinitionId: 'hafs_quran_foundation_rub_240_v1',
        dailyTargetRubs: 4,
        createdAt: createdAt,
        activePlan: plan1,
      );

      final wird2 = Wird(
        subdivisionDefinitionId: 'hafs_quran_foundation_rub_240_v1',
        dailyTargetRubs: 4,
        createdAt: createdAt,
        activePlan: plan2,
      );

      expect(wird1 == wird2, false,
          reason: 'Different activePlan must make Wird instances unequal');
    });
  });
}

