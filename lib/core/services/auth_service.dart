import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';

import '../bootstrap/firebase_bootstrap.dart';

/// Résultat d'une tentative d'authentification.
sealed class AuthResult {
  const AuthResult();
}

/// Succès: utilisateur Firebase authentifié.
class AuthSuccess extends AuthResult {
  const AuthSuccess(this.user);
  final User user;
}

/// Annulation utilisateur (pas une erreur).
class AuthCancelled extends AuthResult {
  const AuthCancelled();
}

/// Collision: compte existe avec autre méthode.
class AuthAccountCollision extends AuthResult {
  const AuthAccountCollision({
    required this.email,
    required this.existingProviderId,
    required this.pendingCredential,
  });

  final String email;
  final String existingProviderId;
  final AuthCredential? pendingCredential;
}

/// Échec réseau/connectivité.
class AuthNetworkFailure extends AuthResult {
  const AuthNetworkFailure(this.message);
  final String message;
}

/// Échec fournisseur (Google/Apple).
class AuthProviderFailure extends AuthResult {
  const AuthProviderFailure(this.message);
  final String message;
}

/// Configuration manquante/invalide.
class AuthConfigurationFailure extends AuthResult {
  const AuthConfigurationFailure(this.message);
  final String message;
}

/// Service d'authentification unifié.
///
/// Firebase Auth reste l'autorité unique d'identité.
/// Google, Apple et Email sont trois portes vers UN seul Firebase UID.
class AuthService {
  AuthService({GoogleSignIn? googleSignIn})
      : _googleSignIn = googleSignIn ?? GoogleSignIn();

  final GoogleSignIn _googleSignIn;

  FirebaseAuth? get _auth => tryFirebaseAuth();

  /// Sign in avec Google.
  Future<AuthResult> signInWithGoogle() async {
    final auth = _auth;
    if (auth == null) {
      return const AuthConfigurationFailure(
        'Firebase Auth not initialized',
      );
    }

    try {
      // Native Google account chooser
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();

      // Annulation utilisateur
      if (googleUser == null) {
        return const AuthCancelled();
      }

      // Obtenir les tokens Google
      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      // Créer credential Firebase
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // Sign in Firebase
      final userCredential = await auth.signInWithCredential(credential);

      return AuthSuccess(userCredential.user!);
    } on FirebaseAuthException catch (e) {
      return _handleFirebaseAuthException(e, credential: null);
    } catch (e) {
      // Erreur Google Sign In (réseau, configuration, etc.)
      if (e.toString().contains('sign_in_canceled') ||
          e.toString().contains('SIGN_IN_CANCELLED')) {
        return const AuthCancelled();
      }

      if (e.toString().contains('network') ||
          e.toString().contains('connection')) {
        return AuthNetworkFailure(e.toString());
      }

      return AuthProviderFailure('Google Sign In failed: $e');
    }
  }

  /// Sign in avec Apple.
  Future<AuthResult> signInWithApple() async {
    final auth = _auth;
    if (auth == null) {
      return const AuthConfigurationFailure(
        'Firebase Auth not initialized',
      );
    }

    try {
      // Générer nonce cryptographique
      final rawNonce = _generateNonce();
      final nonce = _sha256ofString(rawNonce);

      // Native Apple authorization sheet
      final appleCredential = await SignInWithApple.getAppleIDCredential(
        scopes: [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
        nonce: nonce,
      );

      // Créer credential Firebase
      final oauthCredential = OAuthProvider('apple.com').credential(
        idToken: appleCredential.identityToken,
        rawNonce: rawNonce,
      );

      // Sign in Firebase
      final userCredential = await auth.signInWithCredential(oauthCredential);

      // Mettre à jour le displayName si Apple fournit le nom (première auth)
      // et si l'utilisateur n'a pas encore de displayName
      if (userCredential.user != null &&
          userCredential.user!.displayName == null) {
        final givenName = appleCredential.givenName;
        final familyName = appleCredential.familyName;

        if (givenName != null || familyName != null) {
          final displayName = [givenName, familyName]
              .where((n) => n != null && n.isNotEmpty)
              .join(' ')
              .trim();

          if (displayName.isNotEmpty) {
            await userCredential.user!.updateDisplayName(displayName);
          }
        }
      }

      return AuthSuccess(userCredential.user!);
    } on SignInWithAppleAuthorizationException catch (e) {
      // Annulation utilisateur
      if (e.code == AuthorizationErrorCode.canceled) {
        return const AuthCancelled();
      }

      return AuthProviderFailure('Apple Sign In failed: ${e.message}');
    } on FirebaseAuthException catch (e) {
      return _handleFirebaseAuthException(e, credential: null);
    } catch (e) {
      if (e.toString().contains('network') ||
          e.toString().contains('connection')) {
        return AuthNetworkFailure(e.toString());
      }

      return AuthProviderFailure('Apple Sign In failed: $e');
    }
  }

  /// Lier un credential pending après collision.
  Future<AuthResult> linkPendingCredential(AuthCredential credential) async {
    final auth = _auth;
    if (auth == null) {
      return const AuthConfigurationFailure(
        'Firebase Auth not initialized',
      );
    }

    final currentUser = auth.currentUser;
    if (currentUser == null) {
      return const AuthProviderFailure(
        'No user signed in to link credential',
      );
    }

    try {
      await currentUser.linkWithCredential(credential);
      return AuthSuccess(currentUser);
    } on FirebaseAuthException catch (e) {
      return _handleFirebaseAuthException(e, credential: credential);
    } catch (e) {
      return AuthProviderFailure('Failed to link credential: $e');
    }
  }

  /// Sign out.
  Future<void> signOut() async {
    await _googleSignIn.signOut();
    await _auth?.signOut();
  }

  /// Gestion centralisée des FirebaseAuthException.
  AuthResult _handleFirebaseAuthException(
    FirebaseAuthException e, {
    AuthCredential? credential,
  }) {
    switch (e.code) {
      case 'account-exists-with-different-credential':
        // Collision de compte
        final email = e.email ?? '';
        final existingProviderId =
            e.credential?.providerId ?? 'unknown';

        return AuthAccountCollision(
          email: email,
          existingProviderId: existingProviderId,
          pendingCredential: e.credential,
        );

      case 'network-request-failed':
      case 'too-many-requests':
        return AuthNetworkFailure(e.message ?? e.code);

      case 'invalid-credential':
      case 'user-disabled':
      case 'user-not-found':
      case 'wrong-password':
        return AuthProviderFailure(e.message ?? e.code);

      case 'operation-not-allowed':
        return AuthConfigurationFailure(
          'Provider not enabled in Firebase Console: ${e.message}',
        );

      default:
        return AuthProviderFailure(e.message ?? e.code);
    }
  }

  /// Génère un nonce cryptographique pour Apple Sign In.
  String _generateNonce([int length = 32]) {
    const charset =
        '0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._';
    final random = Random.secure();
    return List.generate(length, (_) => charset[random.nextInt(charset.length)])
        .join();
  }

  /// SHA256 hash d'une string.
  String _sha256ofString(String input) {
    final bytes = utf8.encode(input);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }
}
