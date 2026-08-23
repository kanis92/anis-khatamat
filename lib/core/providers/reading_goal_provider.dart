import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/reading_goal.dart';
import '../services/reading_history_service.dart';
import 'auth_provider.dart';

const _goalKey = 'anis_reading_goal_v1';

final readingGoalProvider = FutureProvider<ReadingGoal>((ref) async {
  final user = ref.watch(currentUserProvider);
  final userId = user?.email ?? 'demo';
  final prefs = await SharedPreferences.getInstance();
  final json = prefs.getString('$_goalKey$userId');
  if (json == null) return const ReadingGoal(targetHizb: 0);
  try {
    return ReadingGoal.fromMap(jsonDecode(json) as Map<String, dynamic>);
  } catch (_) {
    return const ReadingGoal(targetHizb: 0);
  }
});

Future<void> saveReadingGoal(WidgetRef ref, ReadingGoal goal) async {
  final user = ref.read(currentUserProvider);
  final userId = user?.email ?? 'demo';
  final prefs = await SharedPreferences.getInstance();
  await prefs.setString('$_goalKey$userId', jsonEncode(goal.toMap()));
  ref.invalidate(readingGoalProvider);
  ref.invalidate(readingGoalProgressProvider);
}

/// Progression par rapport à l'objectif (Hizb lus aujourd'hui ou cette semaine)
class GoalProgress {
  final int completed;
  final int target;
  final bool isAchieved;

  const GoalProgress({required this.completed, required this.target})
    : isAchieved = target > 0 && completed >= target;
}

final readingGoalProgressProvider = FutureProvider<GoalProgress>((ref) async {
  final goal = await ref.watch(readingGoalProvider.future);
  if (goal.isEmpty) return const GoalProgress(completed: 0, target: 0);

  final historyService = ReadingHistoryService();
  final user = ref.watch(currentUserProvider);
  final userId = user?.email ?? 'demo';

  final days = goal.period == ReadingGoalPeriod.daily ? 1 : 7;
  final map = await historyService.getLastDays(userId, days);
  final completed = map.values.fold<int>(0, (a, b) => a + b);

  return GoalProgress(completed: completed, target: goal.targetHizb);
});
