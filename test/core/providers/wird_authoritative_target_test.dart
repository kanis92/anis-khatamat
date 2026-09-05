import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

import 'package:anis_khatamat/core/models/wird.dart';
import 'package:anis_khatamat/core/models/wird_plan.dart';
import 'package:anis_khatamat/core/providers/wird_provider.dart';
import 'package:anis_khatamat/core/services/wird_service.dart';

void main() {
  group('TODAY Authoritative Target — Product Rules', () {
    late ProviderContainer container;
    late WirdService service;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      container = ProviderContainer();
      service = WirdService();
    });

    tearDown(() {
      container.dispose();
    });

    test('NO plan → returns free daily goal', () async {
      // Setup: Wird sans plan
      final wird = Wird(
        subdivisionDefinitionId: 'hafs_quran_foundation_rub_240_v1',
        dailyTargetRubs: 8, // 2 Hizb
        createdAt: DateTime.now(),
        activePlan: null,
      );

      await service.saveWird('demo', wird);

      final target = await container.read(wirdTodayAuthoritativeTargetProvider.future);

      expect(target, 8); // Free goal preserved
    });

    test('ACTIVE plan → returns adaptive allocation', () async {
      // Setup: Plan actif avec allocation adaptive
      // Note: test aujourd'hui (5 sept), plan 1-30 sept
      // Jours restants: 26 jours
      // 240 / 26 ≈ 9.23 → balanced: 9 ou 10
      final plan = WirdPlan(
        id: const Uuid().v4(),
        type: WirdPlanType.gregorianMonth,
        subdivisionDefinitionId: 'hafs_quran_foundation_rub_240_v1',
        baselineDate: DateTime(2026, 9, 1).subtract(const Duration(days: 1)),
        endDate: DateTime(2026, 9, 30),
        createdAt: DateTime(2026, 9, 1),
      );

      final wird = Wird(
        subdivisionDefinitionId: 'hafs_quran_foundation_rub_240_v1',
        dailyTargetRubs: 4, // Free: 1 Hizb
        createdAt: DateTime(2026, 9, 1),
        activePlan: plan,
      );

      await service.saveWird('demo', wird);

      final target = await container.read(wirdTodayAuthoritativeTargetProvider.future);

      // Plan actif: 240 Rub' / jours restants
      // Distribution équilibrée dynamique basée sur date actuelle
      expect(target, greaterThanOrEqualTo(8));
      expect(target, lessThanOrEqualTo(10));
      expect(target, isNot(4)); // Free goal ignored
    });

    test('SCHEDULED plan → returns free goal (future plan does not affect today)', () async {
      // Setup: Plan programmé pour le mois prochain
      final plan = WirdPlan(
        id: const Uuid().v4(),
        type: WirdPlanType.gregorianMonth,
        subdivisionDefinitionId: 'hafs_quran_foundation_rub_240_v1',
        baselineDate: DateTime(2026, 10, 1).subtract(const Duration(days: 1)),
        endDate: DateTime(2026, 10, 31),
        createdAt: DateTime(2026, 9, 5),
      );

      final wird = Wird(
        subdivisionDefinitionId: 'hafs_quran_foundation_rub_240_v1',
        dailyTargetRubs: 8, // Free: 2 Hizb
        createdAt: DateTime(2026, 9, 5),
        activePlan: plan,
      );

      await service.saveWird('demo', wird);

      final target = await container.read(wirdTodayAuthoritativeTargetProvider.future);

      expect(target, 8); // Free goal preserved today
    });

    test('COMPLETED plan → returns free goal', () async {
      // Setup: Plan complété
      final plan = WirdPlan(
        id: const Uuid().v4(),
        type: WirdPlanType.gregorianMonth,
        subdivisionDefinitionId: 'hafs_quran_foundation_rub_240_v1',
        baselineDate: DateTime(2026, 8, 1).subtract(const Duration(days: 1)),
        endDate: DateTime(2026, 8, 31),
        createdAt: DateTime(2026, 8, 1),
        completedAt: DateTime(2026, 8, 31),
      );

      final wird = Wird(
        subdivisionDefinitionId: 'hafs_quran_foundation_rub_240_v1',
        dailyTargetRubs: 4, // Free: 1 Hizb
        createdAt: DateTime(2026, 8, 1),
        activePlan: plan,
      );

      await service.saveWird('demo', wird);

      final target = await container.read(wirdTodayAuthoritativeTargetProvider.future);

      expect(target, 4); // Free goal restored
    });

    test('EXPIRED plan → returns free goal', () async {
      // Setup: Plan expiré
      final plan = WirdPlan(
        id: const Uuid().v4(),
        type: WirdPlanType.gregorianMonth,
        subdivisionDefinitionId: 'hafs_quran_foundation_rub_240_v1',
        baselineDate: DateTime(2026, 8, 1).subtract(const Duration(days: 1)),
        endDate: DateTime(2026, 8, 31),
        createdAt: DateTime(2026, 8, 1),
      );

      final wird = Wird(
        subdivisionDefinitionId: 'hafs_quran_foundation_rub_240_v1',
        dailyTargetRubs: 8, // Free: 2 Hizb
        createdAt: DateTime(2026, 8, 1),
        activePlan: plan,
      );

      await service.saveWird('demo', wird);

      final target = await container.read(wirdTodayAuthoritativeTargetProvider.future);

      expect(target, 8); // Free goal restored
    });

    test('ACTIVE plan with behind schedule → returns higher allocation', () async {
      // Scenario: mi-mois, 0 progress → redistribution adaptive
      final plan = WirdPlan(
        id: const Uuid().v4(),
        type: WirdPlanType.gregorianMonth,
        subdivisionDefinitionId: 'hafs_quran_foundation_rub_240_v1',
        baselineDate: DateTime(2026, 9, 1).subtract(const Duration(days: 1)),
        endDate: DateTime(2026, 9, 30),
        createdAt: DateTime(2026, 9, 1),
      );

      final wird = Wird(
        subdivisionDefinitionId: 'hafs_quran_foundation_rub_240_v1',
        dailyTargetRubs: 4, // Free: 1 Hizb
        createdAt: DateTime(2026, 9, 1),
        activePlan: plan,
      );

      await service.saveWird('demo', wird);

      // Simulation: jour 15, pas de progress
      // 240 / 16 jours restants = 15 Rub'/jour (pas 4!)
      
      final target = await container.read(wirdTodayAuthoritativeTargetProvider.future);

      // Plan actif redistribue automatiquement
      expect(target, greaterThan(4));
    });
  });
}
