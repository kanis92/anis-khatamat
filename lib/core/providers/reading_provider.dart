import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/khatma.dart';
import '../models/reading_progress.dart';
import '../services/reading_service.dart';

import '../models/khatma_load_result.dart';
import '../services/reservation_service.dart';
import '../models/khatma_with_status.dart';
import '../utils/my_khatmat_utils.dart';
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


final reservationServiceProvider = Provider<ReservationService>((ref) => ReservationService());

/// Chargement explicite par ID (navigation / deep links) avec états d'erreur.
final khatmaLoadProvider =
    FutureProvider.family<KhatmaLoadResult, String>((ref, khatmaId) async {
  final service = ref.read(readingServiceProvider);
  try {
    final k = await service.loadKhatmaById(khatmaId);
    return KhatmaLoadResult.data(k);
  } on KhatmaNotFoundException {
    return const KhatmaLoadResult.failure(KhatmaLoadFailure.notFound);
  } on KhatmaAccessDeniedException {
    return const KhatmaLoadResult.failure(KhatmaLoadFailure.accessDenied);
  } on KhatmaNetworkException {
    return const KhatmaLoadResult.failure(KhatmaLoadFailure.network);
  }
});

final khatmaByIdProvider =
    FutureProvider.family<Khatma?, String>((ref, khatmaId) async {
  final result = await ref.watch(khatmaLoadProvider(khatmaId).future);
  return result.khatma;
});

final khatmaStreamProvider =
    StreamProvider.family<Khatma?, String>((ref, khatmaId) {
  final service = ref.watch(readingServiceProvider);
  return service.streamKhatmaById(khatmaId);
});


final khatmatWithStatusProvider =
    FutureProvider<List<KhatmaWithStatus>>((ref) async {
  final khatmat = await ref.watch(khatmatProvider.future);
  return sortMyKhatmatStatuses(
    khatmat.map((k) => buildKhatmaWithStatus(k, null)).toList(),
  );
});

final totalCompletedHizbProvider = FutureProvider<int>((ref) async {
  final service = ref.watch(readingServiceProvider);
  final user = ref.watch(currentUserProvider);
  final userId = user?.email ?? 'demo';
  return service.getTotalCompletedHizb(userId);
});
