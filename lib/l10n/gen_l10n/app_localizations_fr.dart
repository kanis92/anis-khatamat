// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for French (`fr`).
class AppLocalizationsFr extends AppLocalizations {
  AppLocalizationsFr([String locale = 'fr']) : super(locale);

  @override
  String get appTitle => 'ANIS Khatamat';

  @override
  String get login => 'Connexion';

  @override
  String get register => 'Créer un compte';

  @override
  String get email => 'Email';

  @override
  String get password => 'Mot de passe';

  @override
  String get settings => 'Paramètres';

  @override
  String get home => 'Accueil';

  @override
  String get khatma => 'Khatma';

  @override
  String get notifications => 'Notifications';

  @override
  String get training => 'Formation';

  @override
  String get achievements => 'Accomplissements';

  @override
  String get createKhatma => 'Créer une Khatma';

  @override
  String get createAccount => 'Créer un compte';

  @override
  String get changePassword => 'Modifier le mot de passe';

  @override
  String get manageNotifications => 'Gérer les notifications';

  @override
  String get changeLanguage => 'Changer la langue';

  @override
  String get privacyPolicy => 'Politique de confidentialité';

  @override
  String get darkMode => 'Mode sombre';

  @override
  String get logout => 'Déconnexion';

  @override
  String get welcomeGreeting => 'Assalamu alaykum';

  @override
  String get welcomeSubtitle => 'Bienvenue sur votre espace de lecture';

  @override
  String get quickActions => 'Actions rapides';

  @override
  String get progression => 'Progression';

  @override
  String get hizbCompleted => 'Hizb complétés';

  @override
  String get upcomingReadings => 'Prochaines lectures';

  @override
  String get noReadingsScheduled => 'Aucune lecture planifiée';

  @override
  String get createKhatmaToStart =>
      'Créez une Khatma pour commencer à suivre votre progression.';

  @override
  String khatmatInProgress(int count) {
    return '$count Khatma(s) en cours';
  }

  @override
  String get continueReading =>
      'Continuez votre lecture pour avancer dans vos Khatmat.';

  @override
  String get mushaf => 'Mushaf';

  @override
  String get demoMode => 'Mode démo (tester sans connexion)';

  @override
  String get loginButton => 'Se connecter';

  @override
  String get individual => 'Individuelle';

  @override
  String get group => 'Groupe';

  @override
  String get chooseKhatmaType => 'Choisissez le type de Khatma';

  @override
  String get createNewKhatma => 'Créer une nouvelle Khatma';

  @override
  String get myKhatmat => 'Vos Khatmat en cours';

  @override
  String get noKhatma => 'Aucune Khatma en cours';

  @override
  String get readingOptions => 'Options de lecture';

  @override
  String get mushafHafs => 'Mushaf Hafs';

  @override
  String get mushafHafsDesc => 'Version la plus répandue';

  @override
  String get mushafWarsh => 'Mushaf Warsh';

  @override
  String get mushafWarshDesc => 'Version d\'Afrique du Nord';

  @override
  String get mushafWomen => 'Mushaf Femmes';

  @override
  String get mushafWomenDesc => 'مصحف حفص — thème rose élégant';

  @override
  String get chooseMushafType => 'Choisissez le type de Mushaf';

  @override
  String get openMushaf => 'Ouvrir le Mushaf';

  @override
  String get mushafHizb => 'Hizb';

  @override
  String get mushafPage => 'Page';

  @override
  String mushafHizbNumber(String number) {
    return 'Hizb $number';
  }

  @override
  String mushafPageNumber(String number) {
    return 'Page $number';
  }

  @override
  String mushafKhatmaHizbContext(String number) {
    return 'Hizb $number de votre Khatma';
  }

  @override
  String mushafKhatmaHizbLeft(String number) {
    return 'Vous avez quitté le Hizb $number — revenir';
  }

  @override
  String get mushafBookmarkHere => 'Marquer ici';

  @override
  String get mushafBookmarkHereDesc => 'Signet pour reprendre plus tard';

  @override
  String get mushafUnbookmark => 'Retirer le signet';

  @override
  String get khatmaTitle => 'Titre de la Khatma';

  @override
  String get objectives => 'Objectifs';

  @override
  String get inviteMembers => 'Inviter des membres';

  @override
  String get memberEmail => 'Email du membre';

  @override
  String get nextDistribution => 'Suivant → Distribution des Hizb';

  @override
  String get hizbDistribution => 'Distribution des Hizb';

  @override
  String hizbAssigned(int count, int total) {
    return '$count/$total Hizb assignés';
  }

  @override
  String get autoDistribution => 'Auto';

  @override
  String get manualDistribution => 'Manuel';

  @override
  String get confirmDistribution => 'Confirmer la distribution';

  @override
  String get sendReminder => 'Envoyer un rappel';

  @override
  String get listOf60Hizb => 'Liste des 60 Hizb';

  @override
  String get unassigned => 'Non assigné';

  @override
  String get assignedTo => 'Assigné à';

  @override
  String assignedToLabel(String name) {
    return 'Assigné à: $name';
  }

  @override
  String get openMushaf => 'Ouvrir le Mushaf';

  @override
  String get completionAlhamdulillah => 'Alhamdulillah';

  @override
  String get completionAccomplished => 'Cette Khatma est accomplie.';

  @override
  String get completionDua =>
      'Qu\'Allah accepte cette lecture et les efforts de chacun.';

  @override
  String get completionHeaderSubtitle => 'Votre Khatma est accomplie.';

  @override
  String completionHizbAccomplished(int count) {
    return '$count Hizb accomplis';
  }

  @override
  String completionParticipantsCount(int count) {
    return '$count participants';
  }

  @override
  String completionDurationDays(int days) {
    return 'Terminée en $days jours';
  }

  @override
  String get completionDurationOneDay => 'Terminée en 1 jour';

  @override
  String completionClosedOn(String date) {
    return 'Clôturée le $date';
  }

  @override
  String completionCollectiveMessage(int count) {
    return '$count personnes ont participé à cette Khatma.';
  }

  @override
  String completionWithParticipants(String names) {
    return 'Avec $names';
  }

  @override
  String get completionStartNew => 'Commencer une nouvelle Khatma';

  @override
  String get completionShare => 'Partager';

  @override
  String get completionBackToMyKhatmas => 'Retour à mes Khatmas';

  @override
  String completionShareMessage(String title) {
    return 'Alhamdulillah, notre Khatma « $title » vient d\'être accomplie sur Anis. Qu\'Allah accepte les efforts de chacun.';
  }

  @override
  String get completionViewClosure => 'Voir la clôture';

  @override
  String get completionFinishedBadge => 'Terminée';

  @override
  String get completionSee => 'Voir';

  @override
  String completionProgressFraction(int completed, int total) {
    return '$completed/$total';
  }
  @override
  String get khatmaCompleted => 'Khatma terminée ! ماشاء الله';

  @override
  String get account => 'Compte';

  @override
  String get preferences => 'Préférences';

  @override
  String get legal => 'Légal';

  @override
  String get user => 'Utilisateur';

  @override
  String get share => 'Partager';

  @override
  String get shareAchievements => 'Partager';

  @override
  String get shareAchievementsDesc =>
      'Partagez votre progression sur WhatsApp ou d\'autres applications.';

  @override
  String get shareWhatsApp => 'Partager (WhatsApp, etc.)';

  @override
  String get shareYourProgress => 'Partager mes accomplissements';

  @override
  String get language => 'Langue';

  @override
  String get french => 'Français';

  @override
  String get english => 'English';

  @override
  String get arabic => 'العربية';

  @override
  String get system => 'Système';

  @override
  String get send => 'Envoyer';

  @override
  String get cancel => 'Annuler';

  @override
  String get featureComingSoon => 'Fonctionnalité à implémenter';

  @override
  String get urlNotAvailable => 'URL non disponible';

  @override
  String get resetEmailMessage =>
      'Un email de réinitialisation vous sera envoyé.';
}
