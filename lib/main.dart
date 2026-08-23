import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_web_plugins/url_strategy.dart';

import 'app/app.dart';
import 'core/bootstrap/firebase_bootstrap.dart';
import 'core/providers/auth_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  if (kIsWeb) {
    usePathUrlStrategy();
  }

  final bootstrap = await bootstrapFirebase();
  anisFirebaseBootstrapResult = bootstrap;

  final autoDemo = !bootstrap.isConfigured;

  runApp(
    ProviderScope(
      overrides: [
        firebaseBootstrapProvider.overrideWithValue(bootstrap),
        if (autoDemo) demoModeProvider.overrideWith((ref) => true),
      ],
      child: const AnisKhatamatApp(),
    ),
  );
}
