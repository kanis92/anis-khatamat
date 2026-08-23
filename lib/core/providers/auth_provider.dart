import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../bootstrap/firebase_bootstrap.dart';

/// Mode démo explicite (utilisateur ou bootstrap sans Firebase).
final demoModeProvider = StateProvider<bool>((ref) => false);

/// Résultat du bootstrap Firebase (injecté depuis [main]).
final firebaseBootstrapProvider = Provider<FirebaseBootstrapResult>(
  (ref) => anisFirebaseBootstrapResult,
);

/// Mode runtime dérivé : production / demo / config manquante / échec init.
final anisRuntimeModeProvider = Provider<AnisRuntimeMode>((ref) {
  final bootstrap = ref.watch(firebaseBootstrapProvider);
  final demo = ref.watch(demoModeProvider);
  return bootstrap.resolveAppMode(demoModeActive: demo);
});

final firebaseRuntimeStateProvider = Provider<FirebaseRuntimeState>(
  (ref) => ref.watch(firebaseBootstrapProvider).state,
);

final firebaseReadyProvider = Provider<bool>(
  (ref) => ref.watch(firebaseBootstrapProvider).isConfigured,
);

/// Provider pour l'état d'authentification Firebase
final authStateProvider = StreamProvider<User?>((ref) {
  final auth = tryFirebaseAuth();
  if (auth == null) return Stream.value(null);
  return auth.authStateChanges();
});

/// Utilisateur actuel (Firebase ou démo)
class AppUser {
  final String? uid;
  final String? email;
  final String? displayName;

  AppUser({this.uid, this.email, this.displayName});

  factory AppUser.fromFirebase(User user) =>
      AppUser(uid: user.uid, email: user.email, displayName: user.displayName);

  static AppUser get demo => AppUser(
    uid: 'demo-user',
    email: 'demo@test.com',
    displayName: 'Utilisateur démo',
  );
}

/// Provider pour l'utilisateur actuel
final currentUserProvider = Provider<AppUser?>((ref) {
  final isDemo = ref.watch(demoModeProvider);
  if (isDemo) return AppUser.demo;
  final user = ref.watch(authStateProvider).valueOrNull;
  return user != null ? AppUser.fromFirebase(user) : null;
});

/// Provider pour savoir si l'utilisateur est connecté
final isAuthenticatedProvider = Provider<bool>((ref) {
  return ref.watch(currentUserProvider) != null;
});
