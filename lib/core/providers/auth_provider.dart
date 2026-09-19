import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../bootstrap/firebase_bootstrap.dart';
import '../services/auth_service.dart';

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

/// Provider pour l'état d'authentification Firebase.
///
/// Source de vérité **session** : `FirebaseAuth.authStateChanges`.
/// Les lectures Firestore Formations attendent ensuite un ID token avant
/// de s'abonner (voir `guardedFormationRead` / `ensureFormationAuthToken`).
final authStateProvider = StreamProvider<User?>((ref) {
  final auth = tryFirebaseAuth();
  if (auth == null) return Stream.value(null);
  return auth.authStateChanges();
});

/// Statut explicite des credentials Firebase.
///
/// [authStateProvider] seul ne suffit pas : `valueOrNull` renvoie `null` aussi
/// bien pendant la restauration de session que pour un utilisateur déconnecté.
/// Les deux situations n'ont pas le même contrat produit, donc elles ne doivent
/// jamais être confondues.
enum AuthStatus {
  /// La session Firebase n'a pas encore été restaurée.
  initializing,

  /// Aucun credential Firebase utilisable (déconnecté ou auth en erreur).
  signedOut,

  /// Utilisateur Firebase authentifié : les lectures protégées sont permises.
  signedIn,
}

/// Readiness canonique dérivée de [authStateProvider].
///
/// L'`uid` fait partie de l'identité de la valeur : un changement
/// d'utilisateur invalide donc automatiquement tout provider en aval.
class AuthReadiness {
  const AuthReadiness._(this.status, this.uid);

  final AuthStatus status;
  final String? uid;

  static const initializing = AuthReadiness._(AuthStatus.initializing, null);
  static const signedOut = AuthReadiness._(AuthStatus.signedOut, null);

  const AuthReadiness.signedIn(String uid)
      : this._(AuthStatus.signedIn, uid);

  @override
  bool operator ==(Object other) =>
      other is AuthReadiness && other.status == status && other.uid == uid;

  @override
  int get hashCode => Object.hash(status, uid);

  @override
  String toString() => 'AuthReadiness(${status.name}, uid: $uid)';
}

final authReadinessProvider = Provider<AuthReadiness>((ref) {
  return ref.watch(authStateProvider).when(
        loading: () => AuthReadiness.initializing,
        error: (_, __) => AuthReadiness.signedOut,
        data: (user) => user == null
            ? AuthReadiness.signedOut
            : AuthReadiness.signedIn(user.uid),
      );
});

/// UID Firebase courant, `null` tant que [AuthStatus.signedIn] n'est pas atteint.
final firebaseUidProvider = Provider<String?>(
  (ref) => ref.watch(authReadinessProvider).uid,
);

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
  final user = ref.watch(authStateProvider).valueOrNull;
  return user != null ? AppUser.fromFirebase(user) : null;
});

/// Provider pour savoir si l'utilisateur est connecté
final isAuthenticatedProvider = Provider<bool>((ref) {
  return ref.watch(currentUserProvider) != null;
});

/// Provider pour le service d'authentification
final authServiceProvider = Provider<AuthService>((ref) {
  return AuthService();
});
