import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/khatma.dart';
import '../models/reading_progress.dart';
import '../services/reading_service.dart';

import '../models/khatma_load_result.dart';
import '../services/reservation_service.dart';
import '../models/khatma_with_status.dart';
import '../utils/my_khatmat_utils.dart';
import 'auth_provider.dart';

final readingServiceProvider = Provider<ReadingService>(
  (ref) => ReadingService(),
);

/// Identité utilisateur pour Mes Khatmas / dashboard Home.
final myKhatmatIdentityProvider =
    Provider<({String? email, String? authUid, String progressUserId})>((ref) {
      return _myKhatmatIdentity(ref);
    });

/// Identifiants pour « Mes Khatmas » : email (compte) + uid Firebase (invité).
({String? email, String? authUid, String progressUserId}) _myKhatmatIdentity(
  Ref ref,
) {
  final isDemo = ref.watch(demoModeProvider);
  if (isDemo) {
    return (
      email: 'demo@test.com',
      authUid: null,
      progressUserId: 'demo@test.com',
    );
  }
  final fbUser = ref.watch(authStateProvider).valueOrNull;
  if (fbUser == null) {
    return (email: null, authUid: null, progressUserId: '');
  }
  final email = fbUser.isAnonymous ? null : fbUser.email;
  final authUid = fbUser.uid;
  final progressUserId = email ?? authUid;
  return (email: email, authUid: authUid, progressUserId: progressUserId);
}

final khatmaProgressProvider = FutureProvider.family<ReadingProgress?, String>((
  ref,
  khatmaId,
) async {
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

final reservationServiceProvider = Provider<ReservationService>(
  (ref) => ReservationService(),
);

/// Chargement explicite par ID (navigation / deep links) avec états d'erreur.
final khatmaLoadProvider = FutureProvider.family<KhatmaLoadResult, String>((
  ref,
  khatmaId,
) async {
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

final khatmaByIdProvider = FutureProvider.family<Khatma?, String>((
  ref,
  khatmaId,
) async {
  final result = await ref.watch(khatmaLoadProvider(khatmaId).future);
  return result.khatma;
});

final khatmaStreamProvider = StreamProvider.family<Khatma?, String>((
  ref,
  khatmaId,
) {
  final service = ref.watch(readingServiceProvider);
  return service.streamKhatmaById(khatmaId);
});

final khatmatWithStatusProvider = FutureProvider<List<KhatmaWithStatus>>((
  ref,
) async {
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
