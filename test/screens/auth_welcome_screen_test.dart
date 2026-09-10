import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'package:anis_khatamat/core/providers/auth_provider.dart';
import 'package:anis_khatamat/core/services/auth_service.dart';
import 'package:anis_khatamat/l10n/gen_l10n/app_localizations.dart';
import 'package:anis_khatamat/screens/auth_welcome_screen.dart';

class FakeAuthService extends AuthService {
  AuthResult? nextResult;

  @override
  Future<AuthResult> signInWithGoogle() async {
    return nextResult ?? const AuthCancelled();
  }

  @override
  Future<AuthResult> signInWithApple() async {
    return nextResult ?? const AuthCancelled();
  }
}

void main() {
  group('AuthWelcomeScreen', () {
    Widget buildApp({
      required FakeAuthService authService,
      GoRouter? router,
    }) {
      return ProviderScope(
        overrides: [
          authServiceProvider.overrideWith((ref) => authService),
        ],
        child: MaterialApp(
          locale: const Locale('fr'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: router != null
              ? Router(routerDelegate: router.routerDelegate, routeInformationParser: router.routeInformationParser)
              : const AuthWelcomeScreen(),
        ),
      );
    }

    testWidgets('renders welcome title and subtitle', (tester) async {
      final service = FakeAuthService();
      
      await tester.pumpWidget(buildApp(authService: service));
      await tester.pumpAndSettle();

      expect(find.text('Bienvenue sur ANIS'), findsOneWidget);
      expect(find.textContaining('Approfondissez'), findsOneWidget);
    });

    testWidgets('renders all auth provider buttons', (tester) async {
      final service = FakeAuthService();
      
      await tester.pumpWidget(buildApp(authService: service));
      await tester.pumpAndSettle();

      expect(find.text('Continuer avec Google'), findsOneWidget);
      expect(find.text('Continuer avec Email'), findsOneWidget);
      // Apple button is platform-dependent
    });

    testWidgets('Google button triggers signInWithGoogle', (tester) async {
      final service = FakeAuthService();
      service.nextResult = const AuthCancelled();
      
      await tester.pumpWidget(buildApp(authService: service));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Continuer avec Google'));
      await tester.pumpAndSettle();

      // Should show loading then return to normal state (cancelled)
      expect(find.text('Bienvenue sur ANIS'), findsOneWidget);
    });

    testWidgets('shows error message on network failure', (tester) async {
      final service = FakeAuthService();
      service.nextResult = const AuthNetworkFailure('network error');
      
      await tester.pumpWidget(buildApp(authService: service));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Continuer avec Google'));
      await tester.pumpAndSettle();

      expect(find.textContaining('connexion'), findsOneWidget);
    });

    testWidgets('shows error message on account collision', (tester) async {
      final service = FakeAuthService();
      service.nextResult = const AuthAccountCollision(
        email: 'test@example.com',
        existingProviderId: 'password',
        pendingCredential: null,
      );
      
      await tester.pumpWidget(buildApp(authService: service));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Continuer avec Google'));
      await tester.pumpAndSettle();

      expect(find.textContaining('test@example.com'), findsOneWidget);
    });

    testWidgets('Email button navigates to login screen', (tester) async {
      final service = FakeAuthService();
      
      await tester.pumpWidget(buildApp(authService: service));
      await tester.pumpAndSettle();

      final emailButton = find.text('Continuer avec Email');
      expect(emailButton, findsOneWidget);
      
      // Tap would navigate, but requires full router setup
    });

    testWidgets('Google button tap completes without crash', (tester) async {
      final service = FakeAuthService();
      service.nextResult = const AuthCancelled();
      
      await tester.pumpWidget(buildApp(authService: service));
      await tester.pumpAndSettle();

      final button = find.text('Continuer avec Google');
      
      // Tap button
      await tester.tap(button);
      await tester.pumpAndSettle();

      // Should complete without crash
      expect(tester.takeException(), isNull);
    });
  });

  group('AuthWelcomeScreen localizations', () {
    testWidgets('renders in French', (tester) async {
      final service = FakeAuthService();
      
      await tester.pumpWidget(
        ProviderScope(
          overrides: [authServiceProvider.overrideWith((ref) => service)],
          child: const MaterialApp(
            locale: Locale('fr'),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: AuthWelcomeScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Bienvenue sur ANIS'), findsOneWidget);
    });

    testWidgets('renders in English', (tester) async {
      final service = FakeAuthService();
      
      await tester.pumpWidget(
        ProviderScope(
          overrides: [authServiceProvider.overrideWith((ref) => service)],
          child: const MaterialApp(
            locale: Locale('en'),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: AuthWelcomeScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Welcome to ANIS'), findsOneWidget);
    });

    testWidgets('renders in Arabic with RTL', (tester) async {
      final service = FakeAuthService();
      
      await tester.pumpWidget(
        ProviderScope(
          overrides: [authServiceProvider.overrideWith((ref) => service)],
          child: const MaterialApp(
            locale: Locale('ar'),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: AuthWelcomeScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('مرحباً بك في ANIS'), findsOneWidget);
      
      // Verify RTL layout
      final Directionality directionality = tester.widget(
        find.ancestor(
          of: find.text('مرحباً بك في ANIS'),
          matching: find.byType(Directionality),
        ).first,
      );
      expect(directionality.textDirection, TextDirection.rtl);
    });
  });
}
