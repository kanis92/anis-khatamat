/// Configuration applicative (env, build flags, fallbacks)
/// URL partage invité : --dart-define=WEB_JOIN_BASE_URL=https://...
class AppConfig {
  AppConfig._();

  /// URL base pour les liens d'invitation web (Rejoindre avec un code).
  /// Priorité : dart-define > fallback Firebase Hosting.
  static String get webJoinBaseUrl {
    const fromEnv = String.fromEnvironment(
      'WEB_JOIN_BASE_URL',
      defaultValue: '',
    );
    if (fromEnv.isNotEmpty) return fromEnv;
    return _fallbackWebJoinBaseUrl;
  }

  /// Fallback : URL Firebase Hosting du projet anis-437c3
  static const String _fallbackWebJoinBaseUrl = 'https://anis-437c3.web.app';
}
