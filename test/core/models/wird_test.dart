import 'package:flutter_test/flutter_test.dart';
import 'package:anis_khatamat/core/models/wird.dart';

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
}
