import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';

import 'app/app.dart';
import 'core/providers/auth_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  bool firebaseReady = false;
  try {
    await Firebase.initializeApp();
    firebaseReady = true;
  } catch (e) {
    debugPrint('Firebase non configuré: $e → Mode démo activé');
  }

  runApp(
    ProviderScope(
      overrides: firebaseReady ? [] : [demoModeProvider.overrideWith((ref) => true)],
      child: const AnisKhatamatApp(),
    ),
  );
}
