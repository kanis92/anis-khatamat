import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/khatma.dart';
import '../models/reading_progress.dart';
import '../services/reading_service.dart';
import 'auth_provider.dart';

final readingServiceProvider = Provider<ReadingService>((ref) => ReadingService());

final khatmaProgressProvider =
    FutureProvider.family<ReadingProgress?, String>((ref, khatmaId) async {
  final service = ref.watch(readingServiceProvider);
  final user = ref.watch(currentUserProvider);
  final userId = user?.email ?? 'demo';
  return service.getProgress(khatmaId, userId);
});

final khatmatProvider = FutureProvider<List<Khatma>>((ref) async {
  final service = ref.watch(readingServiceProvider);
  final user = ref.watch(currentUserProvider);
  final userId = user?.email ?? 'demo';
  return service.getKhatmat(userId);
});

final totalCompletedHizbProvider = FutureProvider<int>((ref) async {
  final service = ref.watch(readingServiceProvider);
  final user = ref.watch(currentUserProvider);
  final userId = user?.email ?? 'demo';
  return service.getTotalCompletedHizb(userId);
});
