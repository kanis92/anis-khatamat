import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../lib/core/models/wird.dart';
import '../../../lib/core/models/wird_plan.dart';
import '../../../lib/core/providers/wird_provider.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('SubdivisionDefinition Consistency Validation', () {
    late ProviderContainer container;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      container = ProviderContainer();
    });

    tearDown(() {
      container.dispose();
    });

    test('throws ArgumentError when plan definition mismatches wird', () async {
      // Create a plan with different definition
      final plan = WirdPlan(
        id: 'mismatch-plan',
        type: WirdPlanType.gregorianMonth,
        subdivisionDefinitionId: 'wrong_definition_id', // Mismatch!
        baselineDate: DateTime(2026, 9, 1),
        endDate: DateTime(2026, 9, 30),
        createdAt: DateTime(2026, 9, 2),
      );

      final wird = Wird(
        subdivisionDefinitionId: 'hafs_quran_foundation_rub_240_v1',
        dailyTargetRubs: 4,
        createdAt: DateTime(2026, 9, 2),
        activePlan: plan,
      );

      SharedPreferences.setMockInitialValues({
        'anis_wird_v2_demo': jsonEncode(wird.toMap()),
      });

      container = ProviderContainer();

      // wirdPlanProgressProvider should throw when validation fails
      expect(
        () async => await container.read(wirdPlanProgressProvider.future),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('succeeds when plan definition matches wird', () async {
      final plan = WirdPlan(
        id: 'matching-plan',
        type: WirdPlanType.gregorianMonth,
        subdivisionDefinitionId: 'hafs_quran_foundation_rub_240_v1', // Match!
        baselineDate: DateTime(2026, 9, 1),
        endDate: DateTime(2026, 9, 30),
        createdAt: DateTime(2026, 9, 2),
      );

      final wird = Wird(
        subdivisionDefinitionId: 'hafs_quran_foundation_rub_240_v1',
        dailyTargetRubs: 4,
        createdAt: DateTime(2026, 9, 2),
        activePlan: plan,
      );

      SharedPreferences.setMockInitialValues({
        'anis_wird_v2_demo': jsonEncode(wird.toMap()),
      });

      container = ProviderContainer();

      // Should not throw
      final progress = await container.read(wirdPlanProgressProvider.future);
      expect(progress, isA<Set<int>>());
    });
  });
}
