import '../config/app_config.dart';
import '../models/khatma.dart';

/// URLs et chemins de navigation Khatma — source unique pour partage et routing.
///
/// **Web V1 — PATH URLs** (Firebase Hosting SPA rewrite) :
/// - Invitation : `https://<domain>/join/{khatmaId}`
/// - Détail :     `https://<domain>/khatma/{khatmaId}`
///
/// **In-app (GoRouter)** — route canonique interne :
/// - `/join/{khatmaId}` — parcours rejoindre
/// - `/khatma/{khatmaId}` — détail (collaboratif ou classique)
class KhatmaLinkService {
  KhatmaLinkService._();

  static String get webBaseUrl => AppConfig.webJoinBaseUrl;

  /// Normalise et valide un identifiant Khatma pour `/join/:id`.
  static String? normalizeJoinKhatmaId(String? raw) {
    if (raw == null) return null;
    final id = raw.trim();
    if (id.isEmpty || id.length > 128) return null;
    if (id.contains('/') || id.contains('\\') || id.contains(' ')) return null;
    return id;
  }

  /// Redirige un lien legacy `#/join/{id}` vers le PATH canonique `/join/{id}`.
  ///
  /// Retourne `null` si l'URI est déjà canonique ou ne contient pas de join legacy.
  static String? redirectPathForLegacyJoinUri(Uri uri) {
    if (uri.path.startsWith('/join/')) return null;
    final fragment = uri.fragment;
    if (fragment.isEmpty) return null;
    if (!fragment.contains('join')) return null;

    final id = parseJoinKhatmaIdFromUri(uri);
    if (id == null) return null;
    return joinPath(id);
  }

  /// Extrait un identifiant depuis une URL externe (path ou legacy hash).
  static String? parseJoinKhatmaIdFromUri(Uri uri) {
    final path = uri.path;
    const pathPrefix = '/join/';
    if (path.startsWith(pathPrefix)) {
      return normalizeJoinKhatmaId(path.substring(pathPrefix.length));
    }

    // Legacy hash: https://domain/#/join/{id}
    if (uri.fragment.startsWith('/join/')) {
      return normalizeJoinKhatmaId(uri.fragment.substring('/join/'.length));
    }
    if (uri.fragment.startsWith('join/')) {
      return normalizeJoinKhatmaId(uri.fragment.substring('join/'.length));
    }

    return null;
  }

  /// Lien externe d'invitation (WhatsApp, SMS, QR futur).
  static String joinUrl(String khatmaId) => '$webBaseUrl/join/$khatmaId';

  /// Lien Web de consultation directe.
  static String webDetailUrl(String khatmaId) => '$webBaseUrl/khatma/$khatmaId';

  /// Route GoRouter écran de clôture (WOW 01).
  static String completionPath(String khatmaId) => '/khatma/$khatmaId/completion';

  /// Onglet / liste Mes Khatmas.
  static const myKhatmasPath = '/khatma';

  /// Mes Khatmas + ouverture du choix de création (individuelle / groupe).
  static const myKhatmasCreatePath = '/khatma?create=1';

  /// Corps du message de partage clôture + lien (texte localisé fourni par l'UI).
  static String completionShareText({
    required String localizedBody,
    required String khatmaId,
  }) =>
      '$localizedBody\n\n${webDetailUrl(khatmaId)}';

  /// Chemins GoRouter internes (sans domaine).
  static String joinPath(String khatmaId) => '/join/$khatmaId';

  static String detailPath(String khatmaId) => '/khatma/$khatmaId';

  static String chatPath(String khatmaId) => '/khatma/$khatmaId/chat';

  /// Message de partage invitation (groupe / publique).
  static String joinInviteMessage(Khatma khatma, {String? bodyPrefix}) {
    final prefix = bodyPrefix ??
        '🕌 Rejoignez la Khatma "${khatma.title}" sur ANIS Khatamat !\n\n';
    return '$prefix'
        'Lien : ${joinUrl(khatma.id)}\n'
        'Ou dans l\'app : "Rejoindre avec un code" → ${khatma.id}';
  }

  /// Message de partage progression (détail / réservation).
  static String progressShareMessage({
    required Khatma khatma,
    required int completedCount,
    required int totalHizb,
    bool includeJoinLink = true,
  }) {
    final pct = totalHizb > 0 ? ((completedCount / totalHizb) * 100).round() : 0;
    final joinLine = includeJoinLink && (khatma.isGroup || khatma.isPublic)
        ? '\n\n${joinInviteMessage(khatma, bodyPrefix: 'Rejoindre : ')}'
        : '';
    if (completedCount >= totalHizb && totalHizb > 0) {
      return '🕌 Khatma terminée ! ماشاء الله\n\n'
          'J\'ai complété la Khatma "${khatma.title}" - $totalHizb Hizb du Coran.\n\n'
          'Téléchargez ANIS Khatamat pour suivre vos Khatmat.$joinLine';
    }
    return '🕌 Ma Khatma "${khatma.title}" en cours\n\n'
        'Progression : $completedCount/$totalHizb Hizb ($pct%)\n\n'
        'Téléchargez ANIS Khatamat pour suivre vos Khatmat.$joinLine';
  }
}
