import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/bootstrap/firebase_bootstrap.dart';
import '../../../core/providers/auth_provider.dart';

/// Signale qu'une lecture Formation protégée a été demandée sans credentials
/// Firebase utilisables.
///
/// C'est un état de domaine, pas une erreur Firestore : aucune requête n'est
/// émise. L'UI doit le traduire en « Connexion requise », jamais en catalogue
/// vide.
class FormationsAuthRequiredException implements Exception {
  const FormationsAuthRequiredException();

  @override
  String toString() =>
      'FormationsAuthRequiredException: Firebase sign-in required '
      'before reading protected Formation content.';
}

/// Attend un ID token utilisable avant la première lecture Firestore.
///
/// `authStateChanges` peut émettre un `User` avant que le client Firestore
/// ait un token. Sans cette barrière, la première query échoue en
/// `permission-denied` et l'UI Formations n'a jamais de contenu.
///
/// Si Firebase n'est pas initialisé (tests widget), la fonction est un no-op.
Future<void> ensureFormationAuthToken({
  Future<String?> Function()? refreshIdToken,
}) async {
  if (refreshIdToken != null) {
    await refreshIdToken();
    return;
  }
  final user = tryFirebaseAuth()?.currentUser;
  if (user == null) return;
  await user.getIdToken().timeout(
    const Duration(seconds: 8),
    onTimeout: () => throw TimeoutException(
      'Formation auth token refresh timed out.',
    ),
  );
}

/// Applique le contrat de readiness avant toute lecture Firestore protégée.
///
/// - [AuthReadiness.initializing] : reste en chargement, aucune requête émise.
/// - [AuthReadiness.signedOut] : erreur de domaine typée, aucune requête émise.
/// - [AuthReadiness.signedIn] : token prêt, puis délégation à [read].
Future<T> guardedFormationRead<T>(Ref ref, Future<T> Function() read) {
  switch (ref.watch(authReadinessProvider).status) {
    case AuthStatus.initializing:
      return _pendingUntilRebuild<T>(ref);
    case AuthStatus.signedOut:
      return Future<T>.error(const FormationsAuthRequiredException());
    case AuthStatus.signedIn:
      return ensureFormationAuthToken().then((_) => read());
  }
}

/// Équivalent stream de [guardedFormationRead].
Stream<T> guardedFormationStream<T>(Ref ref, Stream<T> Function() watch) {
  switch (ref.watch(authReadinessProvider).status) {
    case AuthStatus.initializing:
      return _neverEmit<T>(ref);
    case AuthStatus.signedOut:
      return Stream<T>.error(const FormationsAuthRequiredException());
    case AuthStatus.signedIn:
      return Stream.fromFuture(ensureFormationAuthToken()).asyncExpand((_) {
        return watch();
      });
  }
}

/// Future qui ne se résout pas : le provider reste en [AsyncLoading] jusqu'à
/// ce que [authReadinessProvider] change et reconstruise le graphe.
Future<T> _pendingUntilRebuild<T>(Ref _) {
  // Intentionally never completes. Riverpod rebuilds the provider as soon as
  // auth readiness changes, and drops this future.
  return Completer<T>().future;
}

/// Stream qui n'émet jamais et ne se termine pas tout seul.
///
/// `Stream.empty()` se ferme immédiatement : Riverpod peut alors quitter
/// [AsyncLoading], ce qui casserait le contrat « AUTH INITIALIZING ».
Stream<T> _neverEmit<T>(Ref ref) {
  final controller = StreamController<T>();
  ref.onDispose(() {
    if (!controller.isClosed) {
      unawaited(controller.close());
    }
  });
  return controller.stream;
}
