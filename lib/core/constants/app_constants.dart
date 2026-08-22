/// Constantes de l'application
class AppConstants {
  AppConstants._();

  static const int totalHizb = 60;
  static const int totalSurahs = 114;
  static const int totalAyahs = 6236;

  static const List<String> supportedLocales = ['fr', 'en', 'ar'];

  /// Mettez ici l'URL de votre politique de confidentialité (obligatoire pour l'App Store)
  static const String privacyPolicyUrl =
      'https://example.com/privacy-policy';

  /// URL de l'app pour le parrainage / Inviter un ami
  static const String appWebUrl = 'https://anis-437c3.web.app';
  static const String? playStoreUrl = null; // Ex: https://play.google.com/store/apps/details?id=...
  static const String? appStoreUrl = null;  // Ex: https://apps.apple.com/app/id...
}
