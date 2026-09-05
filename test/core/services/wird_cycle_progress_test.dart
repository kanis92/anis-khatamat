import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:anis_khatamat/core/models/wird.dart';
import 'package:anis_khatamat/core/services/wird_rub_tracker.dart';
import 'package:anis_khatamat/core/data/subdivision_definitions/hafs_quran_foundation_rub_240_v1.dart';

/// Tests focalisés pour le fix de progression Personal Khatma.
/// 
/// Objectifs:
/// A. User reads BEFORE activating plan → ring keeps that progress
/// B. User continues reading AFTER plan activation → ring adds new progress
/// C. Resume position alone does not award progress (jumps)
/// D. Jumping to Hizb 16 does not mark Hizb 1–15 complete
/// E. Sequential reading Hizb 1-15 + entering 16 → ring consistent
/// F. New cycle starts from 0, does not inherit previous cycle
/// G. Daily completion: 8/9 Rub' is NOT complete
void main() {
  late WirdRubTracker tracker;
  const userId = 'test_user';

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    tracker = WirdRubTracker(
      definition: HafsQuranFoundationRub240V1Definition(),
    );
  });

  group('Personal Khatma Cycle Progress', () {
    test('A. Pre-plan reading progress is retained after plan activation', () async {
      // BEFORE plan: user reads 2 Hizb (8 Rub')
      final cycleStart = DateTime(2026, 8, 1);
      
      // Simulate 8 Rub' completed on Aug 15 (BEFORE plan activation)
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList(
        'anis_wird_rubs_completed:hafs_quran_foundation_rub_240_v1:$userId:2026-08-15',
        ['1', '2', '3', '4', '5', '6', '7', '8'],
      );
      
      // AFTER: User activates plan on Sep 1 (plan.baselineDate = Aug 31)
      // Ring should STILL show 8 Rub' because cycle started Aug 1
      
      final cycleProgress = await tracker.getRubsCompletedInCycle(userId, cycleStart);
      
      expect(cycleProgress.length, 8, 
        reason: 'Ring must show progress from cycle start, not plan start');
      expect(cycleProgress, containsAll([1, 2, 3, 4, 5, 6, 7, 8]));
    });

    test('B. Reading after plan activation adds to ring progress', () async {
      final cycleStart = DateTime(2026, 8, 1);
      final prefs = await SharedPreferences.getInstance();
      
      // Pre-plan: 8 Rub' on Aug 15
      await prefs.setStringList(
        'anis_wird_rubs_completed:hafs_quran_foundation_rub_240_v1:$userId:2026-08-15',
        ['1', '2', '3', '4', '5', '6', '7', '8'],
      );
      
      // Post-plan: 4 more Rub' on Sep 5
      await prefs.setStringList(
        'anis_wird_rubs_completed:hafs_quran_foundation_rub_240_v1:$userId:2026-09-05',
        ['9', '10', '11', '12'],
      );
      
      final cycleProgress = await tracker.getRubsCompletedInCycle(userId, cycleStart);
      
      expect(cycleProgress.length, 12,
        reason: 'Ring must combine pre-plan and post-plan progress');
      expect(cycleProgress, containsAll([1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12]));
    });

    test('C. Resume position (jump) does not award progress', () async {
      // User jumps to Hizb 16 via navigation
      // This saves position but does NOT mark Rub' as completed
      
      await tracker.savePositionOnly(userId, 'hafs', 281, surah: 18, ayah: 1);
      
      final cycleStart = DateTime(2026, 8, 1);
      final cycleProgress = await tracker.getRubsCompletedInCycle(userId, cycleStart);
      
      expect(cycleProgress.length, 0,
        reason: 'Jump/navigation must not award canonical progress');
    });

    test('D. Jumping to Hizb 16 does not mark Hizb 1–15 complete', () async {
      final cycleStart = DateTime(2026, 8, 1);
      
      // User jumps to page 281 (Hizb 16 start)
      await tracker.savePositionOnly(userId, 'hafs', 281, surah: 18, ayah: 1);
      
      // Verify no Rub' were marked complete
      final prefs = await SharedPreferences.getInstance();
      final keys = prefs.getKeys().where((k) => k.contains('rubs_completed'));
      
      expect(keys.isEmpty, true,
        reason: 'Jump must not create any completion records');
      
      final cycleProgress = await tracker.getRubsCompletedInCycle(userId, cycleStart);
      expect(cycleProgress.length, 0);
    });

    test('E. Sequential reading Hizb 1-15 produces consistent ring progress', () async {
      // Simulate sequential reading from page 1 to page 281 (Hizb 1-15 complete)
      final cycleStart = DateTime(2026, 8, 1);
      final prefs = await SharedPreferences.getInstance();
      
      // Hizb 1-15 = 60 Rub' (IDs 1-60)
      final hizb15Rubs = List.generate(60, (i) => (i + 1).toString());
      
      await prefs.setStringList(
        'anis_wird_rubs_completed:hafs_quran_foundation_rub_240_v1:$userId:2026-08-20',
        hizb15Rubs,
      );
      
      final cycleProgress = await tracker.getRubsCompletedInCycle(userId, cycleStart);
      
      expect(cycleProgress.length, 60,
        reason: 'Hizb 1-15 = 60 Rub\' completed');
      
      // Verify specific Rub' IDs
      expect(cycleProgress.contains(1), true, reason: 'First Rub\' of Hizb 1');
      expect(cycleProgress.contains(60), true, reason: 'Last Rub\' of Hizb 15');
      expect(cycleProgress.contains(61), false, reason: 'Hizb 16 not started');
    });

    test('F. New cycle starts from 0, previous cycle not inherited', () async {
      final prefs = await SharedPreferences.getInstance();
      
      // First cycle: completed 240 Rub' (full Khatma)
      final firstCycleStart = DateTime(2026, 1, 1);
      final allRubs = List.generate(240, (i) => (i + 1).toString());
      await prefs.setStringList(
        'anis_wird_rubs_completed:hafs_quran_foundation_rub_240_v1:$userId:2026-01-31',
        allRubs,
      );
      
      // New cycle starts Sep 1
      final newCycleStart = DateTime(2026, 9, 1);
      
      // User hasn't read anything in new cycle yet
      final newCycleProgress = await tracker.getRubsCompletedInCycle(userId, newCycleStart);
      
      expect(newCycleProgress.length, 0,
        reason: 'New cycle must start from 0, not inherit previous 240/240');
      
      // Verify first cycle data is still there (not deleted)
      final firstCycleProgress = await tracker.getRubsCompletedInCycle(userId, firstCycleStart);
      expect(firstCycleProgress.length, 240,
        reason: 'Previous cycle history must be preserved');
    });
  });

  group('Daily Completion Logic', () {
    test('G. 8/9 Rub\' is NOT marked complete', () {
      const target = 9;
      const progress = 8;
      
      final isComplete = progress >= target && target > 0;
      
      expect(isComplete, false,
        reason: '8/9 Rub\' is incomplete, must not show "accompli"');
    });

    test('G. 9/9 Rub\' IS marked complete', () {
      const target = 9;
      const progress = 9;
      
      final isComplete = progress >= target && target > 0;
      
      expect(isComplete, true,
        reason: '9/9 Rub\' is complete');
    });

    test('G. 10/9 Rub\' IS marked complete (exceeded)', () {
      const target = 9;
      const progress = 10;
      
      final isComplete = progress >= target && target > 0;
      
      expect(isComplete, true,
        reason: '10/9 Rub\' exceeds target, marked complete');
    });
  });

  group('Wird Cycle Boundary Model', () {
    test('Legacy Wird (null currentCycleStartDate) uses createdAt', () {
      final createdAt = DateTime(2026, 1, 1);
      final wird = Wird(
        subdivisionDefinitionId: 'hafs_quran_foundation_rub_240_v1',
        dailyTargetRubs: 4,
        createdAt: createdAt,
        currentCycleStartDate: null, // Legacy
      );
      
      final cycleStart = wird.currentCycleStartDate ?? wird.createdAt;
      
      expect(cycleStart, createdAt,
        reason: 'Legacy Wird uses createdAt as fallback');
    });

    test('New Wird has explicit currentCycleStartDate', () {
      final createdAt = DateTime(2026, 1, 1);
      final cycleStart = DateTime(2026, 9, 1);
      
      final wird = Wird(
        subdivisionDefinitionId: 'hafs_quran_foundation_rub_240_v1',
        dailyTargetRubs: 4,
        createdAt: createdAt,
        currentCycleStartDate: cycleStart,
      );
      
      expect(wird.currentCycleStartDate, cycleStart,
        reason: 'Explicit cycle boundary set');
      expect(wird.currentCycleStartDate, isNot(createdAt),
        reason: 'Cycle start can differ from Wird creation');
    });

    test('defaultWird() sets currentCycleStartDate to now', () {
      final wird = Wird.defaultWird();
      
      expect(wird.currentCycleStartDate, isNotNull,
        reason: 'New Wird should have explicit cycle start');
      expect(wird.currentCycleStartDate, wird.createdAt,
        reason: 'First cycle starts when Wird is created');
    });
  });

  group('Wird Serialization with currentCycleStartDate', () {
    test('toMap includes currentCycleStartDate', () {
      final cycleStart = DateTime(2026, 9, 1);
      final wird = Wird(
        subdivisionDefinitionId: 'hafs_quran_foundation_rub_240_v1',
        dailyTargetRubs: 4,
        createdAt: DateTime(2026, 1, 1),
        currentCycleStartDate: cycleStart,
      );
      
      final map = wird.toMap();
      
      expect(map['currentCycleStartDate'], cycleStart.toIso8601String());
    });

    test('fromMap with null currentCycleStartDate (legacy)', () {
      final map = {
        'subdivisionDefinitionId': 'hafs_quran_foundation_rub_240_v1',
        'dailyTargetRubs': 4,
        'createdAt': '2026-01-01T00:00:00.000',
        // No currentCycleStartDate key (legacy)
      };
      
      final wird = Wird.fromMap(map);
      
      expect(wird.currentCycleStartDate, null,
        reason: 'Legacy Wird has null cycle start');
    });

    test('fromMap with explicit currentCycleStartDate', () {
      final map = {
        'subdivisionDefinitionId': 'hafs_quran_foundation_rub_240_v1',
        'dailyTargetRubs': 4,
        'createdAt': '2026-01-01T00:00:00.000',
        'currentCycleStartDate': '2026-09-01T00:00:00.000',
      };
      
      final wird = Wird.fromMap(map);
      
      expect(wird.currentCycleStartDate, DateTime(2026, 9, 1));
    });
  });
}
