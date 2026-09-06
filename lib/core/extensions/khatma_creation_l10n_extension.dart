import '../../l10n/gen_l10n/app_localizations.dart';

/// Extension pour traduire les clés d'erreur de création de Khatma.
extension KhatmaCreationL10nExtension on AppLocalizations {
  /// Traduit une clé d'erreur de création de Khatma.
  String translateKhatmaCreationKey(String key) {
    switch (key) {
      case 'khatmaCreationAuthRequired':
        return khatmaCreationAuthRequired;
      case 'khatmaCreationPermissionDenied':
        return khatmaCreationPermissionDenied;
      case 'khatmaCreationNetworkError':
        return khatmaCreationNetworkError;
      case 'khatmaCreationInitFailed':
        return khatmaCreationInitFailed;
      case 'khatmaCreationUnknown':
        return khatmaCreationUnknown;
      case 'khatmaCreationRetry':
        return khatmaCreationRetry;
      case 'khatmaCreated':
        return khatmaCreated;
      case 'khatmaCreationFailed':
        return khatmaCreationFailed;
      default:
        return key; // Fallback à la clé elle-même
    }
  }
}
