import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Mode démo pour tester sans connexion Firebase
final demoModeProvider = StateProvider<bool>((ref) => false);

/// Provider pour l'état d'authentification Firebase
final authStateProvider = StreamProvider<User?>((ref) {
  try {
    return FirebaseAuth.instance.authStateChanges();
  } catch (_) {
    return Stream.value(null); // Firebase non configuré
  }
});

/// Utilisateur actuel (Firebase ou démo)
class AppUser {
  final String? email;
  final String? displayName;

  AppUser({this.email, this.displayName});

  factory AppUser.fromFirebase(User user) =>
      AppUser(email: user.email, displayName: user.displayName);

  static AppUser get demo => AppUser(
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
