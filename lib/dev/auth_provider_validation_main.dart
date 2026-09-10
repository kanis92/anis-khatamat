import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../firebase_options.dart';
import 'auth_provider_validation_screen.dart';

/// Isolated authentication provider validation harness.
///
/// SAFETY:
/// - Requires kDebugMode (debug build)
/// - Requires --dart-define=AUTH_PROVIDER_VALIDATION=true
/// - Does NOT initialize Firestore business repositories
/// - Does NOT initialize Khatma/Formations/Wird
/// - Does NOT call ANIS business APIs
///
/// Purpose:
/// Validate REAL Google and Apple Sign-In against Firebase Auth (anis-437c3)
/// without launching the full ANIS production application.
///
/// Run:
/// ```
/// flutter run -d [device] \
///   --dart-define=AUTH_PROVIDER_VALIDATION=true \
///   -t lib/dev/auth_provider_validation_main.dart
/// ```

const bool _kAuthValidationEnabled =
    bool.fromEnvironment('AUTH_PROVIDER_VALIDATION');

void main() async {
  // HARD SAFETY GUARD: Fail closed if conditions not met
  if (!kDebugMode || !_kAuthValidationEnabled) {
    throw StateError(
      'Auth provider validation harness requires BOTH:\n'
      '  1. Debug build (kDebugMode)\n'
      '  2. --dart-define=AUTH_PROVIDER_VALIDATION=true\n\n'
      'This harness is a developer validation tool and must never ship to production.',
    );
  }

  WidgetsFlutterBinding.ensureInitialized();

  // Initialize ONLY Firebase Core and Auth
  // Do NOT initialize Firestore
  // Do NOT initialize business repositories
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(const AuthProviderValidationApp());
}

class AuthProviderValidationApp extends StatelessWidget {
  const AuthProviderValidationApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ANIS Auth Validation',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.teal),
        useMaterial3: true,
      ),
      home: const AuthProviderValidationScreen(),
    );
  }
}
