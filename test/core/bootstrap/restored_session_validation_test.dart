import 'package:flutter_test/flutter_test.dart';

import 'package:anis_khatamat/core/bootstrap/firebase_development_guard.dart';

/// Une session restaurée que l'émulateur Auth ne reconnaît plus est la cause
/// des `permission-denied` inexpliqués en développement. La production, elle,
/// ne doit jamais voir ce comportement.
void main() {
  group('decideRestoredSessionValidation', () {
    test('production keeps its session untouched, even with a restored user',
        () {
      expect(
        decideRestoredSessionValidation(
          envMode: 'production',
          hasRestoredUser: true,
          isWeb: false,
          debugMode: false,
        ),
        RestoredSessionDecision.keepProductionSession,
      );
    });

    test('a production release build is never revalidated', () {
      expect(
        decideRestoredSessionValidation(
          envMode: 'production',
          hasRestoredUser: true,
          isWeb: false,
          debugMode: true,
        ),
        RestoredSessionDecision.keepProductionSession,
      );
    });

    test('an unrecognised env mode fails closed onto the development guard',
        () {
      expect(
        decideRestoredSessionValidation(
          envMode: 'PRODUCTION',
          hasRestoredUser: true,
          isWeb: false,
          debugMode: true,
        ),
        RestoredSessionDecision.validateAgainstEmulator,
        reason: 'an unknown env mode must never be treated as production',
      );
    });

    test('development revalidates a restored session', () {
      expect(
        decideRestoredSessionValidation(
          envMode: 'development',
          hasRestoredUser: true,
          isWeb: false,
          debugMode: true,
        ),
        RestoredSessionDecision.validateAgainstEmulator,
      );
    });

    test('development with no restored session has nothing to validate', () {
      expect(
        decideRestoredSessionValidation(
          envMode: 'development',
          hasRestoredUser: false,
          isWeb: false,
          debugMode: true,
        ),
        RestoredSessionDecision.noRestoredSession,
      );
    });

    test('web development does not use the native emulator guard', () {
      expect(
        decideRestoredSessionValidation(
          envMode: 'development',
          hasRestoredUser: true,
          isWeb: true,
          debugMode: true,
        ),
        RestoredSessionDecision.keepProductionSession,
      );
    });
  });

  group('shouldDiscardRestoredSession', () {
    test('a session whose token cannot be refreshed is discarded', () {
      expect(
        shouldDiscardRestoredSession(tokenRefreshSucceeded: false),
        isTrue,
      );
    });

    test('a session the emulator still accepts is kept', () {
      expect(
        shouldDiscardRestoredSession(tokenRefreshSucceeded: true),
        isFalse,
      );
    });
  });
}
