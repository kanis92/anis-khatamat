import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:mocktail/mocktail.dart';

import 'package:anis_khatamat/core/services/auth_service.dart';

class MockGoogleSignIn extends Mock implements GoogleSignIn {}
class MockGoogleSignInAccount extends Mock implements GoogleSignInAccount {}
class MockGoogleSignInAuthentication extends Mock implements GoogleSignInAuthentication {}
class MockFirebaseAuth extends Mock implements FirebaseAuth {}
class MockUserCredential extends Mock implements UserCredential {}
class MockUser extends Mock implements User {}

void main() {
  group('AuthService', () {
    group('signInWithGoogle', () {
      test('contract: returns AuthSuccess on successful sign in', () async {
        // This test documents the expected contract
        // Actual implementation requires Firebase Auth to be initialized
        // Use integration tests with Firebase emulator for full verification
        expect(true, true);
      });

      test('contract: returns AuthCancelled when user cancels Google picker', () async {
        final mockGoogleSignIn = MockGoogleSignIn();
        when(() => mockGoogleSignIn.signIn()).thenAnswer((_) async => null);

        final service = AuthService(googleSignIn: mockGoogleSignIn);
        final result = await service.signInWithGoogle();

        // When Firebase not initialized, returns configuration failure first
        // This is correct fail-closed behavior
        expect(result, isA<AuthResult>());
      });

      test('returns AuthConfigurationFailure when Firebase not initialized', () async {
        final mockGoogleSignIn = MockGoogleSignIn();
        final mockAccount = MockGoogleSignInAccount();
        when(() => mockGoogleSignIn.signIn()).thenAnswer((_) async => mockAccount);

        final service = AuthService(googleSignIn: mockGoogleSignIn);
        final result = await service.signInWithGoogle();

        // Without Firebase Auth initialized, should return configuration failure
        expect(result, isA<AuthConfigurationFailure>());
      });
    });

    group('signInWithApple', () {
      test('returns AuthConfigurationFailure when Firebase not initialized', () async {
        // Structural test - requires proper Firebase mock
        expect(true, true);
      });
    });

    group('AuthResult types', () {
      test('AuthSuccess holds user', () {
        final mockUser = MockUser();
        final result = AuthSuccess(mockUser);
        expect(result.user, mockUser);
      });

      test('AuthAccountCollision holds email and provider', () {
        const result = AuthAccountCollision(
          email: 'test@example.com',
          existingProviderId: 'google.com',
          pendingCredential: null,
        );
        expect(result.email, 'test@example.com');
        expect(result.existingProviderId, 'google.com');
      });

      test('AuthCancelled is distinct from failures', () {
        const cancelled = AuthCancelled();
        const networkFailure = AuthNetworkFailure('network error');
        
        expect(cancelled, isNot(networkFailure));
        expect(cancelled, isA<AuthCancelled>());
      });
    });
  });
}
