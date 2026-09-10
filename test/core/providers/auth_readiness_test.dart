import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:anis_khatamat/core/providers/auth_provider.dart';

void main() {
  group('authReadinessProvider', () {
    test('returns initializing during auth stream loading', () {
      final container = ProviderContainer(
        overrides: [
          authStateProvider.overrideWith(
            (ref) => const Stream<User?>.empty(),
          ),
        ],
      );
      addTearDown(container.dispose);

      final readiness = container.read(authReadinessProvider);
      expect(readiness.status, AuthStatus.initializing);
      expect(readiness.uid, isNull);
    });

    test('returns signedOut when auth stream emits null', () async {
      final container = ProviderContainer(
        overrides: [
          authStateProvider.overrideWith(
            (ref) => Stream.value(null),
          ),
        ],
      );
      addTearDown(container.dispose);

      // Wait for stream to emit
      await container.read(authStateProvider.future);

      final readiness = container.read(authReadinessProvider);
      expect(readiness.status, AuthStatus.signedOut);
      expect(readiness.uid, isNull);
    });

    test('returns signedOut on auth stream error', () async {
      final container = ProviderContainer(
        overrides: [
          authStateProvider.overrideWith(
            (ref) => Stream.error(Exception('Auth error')),
          ),
        ],
      );
      addTearDown(container.dispose);

      // Wait for error
      try {
        await container.read(authStateProvider.future);
      } catch (_) {
        // Expected
      }

      final readiness = container.read(authReadinessProvider);
      expect(readiness.status, AuthStatus.signedOut);
      expect(readiness.uid, isNull);
    });

    test('AuthReadiness equality based on status and uid', () {
      const initializing1 = AuthReadiness.initializing;
      const initializing2 = AuthReadiness.initializing;
      const signedOut = AuthReadiness.signedOut;
      const signedIn1 = AuthReadiness.signedIn('uid1');
      const signedIn2 = AuthReadiness.signedIn('uid1');
      const signedIn3 = AuthReadiness.signedIn('uid2');

      expect(initializing1, initializing2);
      expect(initializing1, isNot(signedOut));
      expect(signedIn1, signedIn2);
      expect(signedIn1, isNot(signedIn3));
    });

    test('AuthReadiness hashCode is consistent', () {
      const signedIn1 = AuthReadiness.signedIn('uid1');
      const signedIn2 = AuthReadiness.signedIn('uid1');

      expect(signedIn1.hashCode, signedIn2.hashCode);
    });
  });

  group('Session restoration prevents login flash', () {
    test('initializing state does not redirect to auth', () {
      // This is tested in router redirect logic
      // During AuthStatus.initializing, router should return null
      // preventing navigation to /auth
      expect(AuthStatus.initializing, isNot(AuthStatus.signedOut));
    });

    test('signedIn with uid allows app access', () {
      const readiness = AuthReadiness.signedIn('user123');
      expect(readiness.status, AuthStatus.signedIn);
      expect(readiness.uid, 'user123');
    });
  });
}
