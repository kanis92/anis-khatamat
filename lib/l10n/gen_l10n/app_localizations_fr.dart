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
  String get wird => 'Wird';

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
  String get chooseMushafType => 'Choisissez le type de Mushaf';

  @override
  String get mushafWomen => 'Mushaf Femmes';

  @override
  String get mushafWomenDesc => 'مصحف حفص — thème rose élégant';

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

  @override
  String get bookmarks => 'Favoris';

  @override
  String get completed => 'Terminées';

  @override
  String get continueAction => 'Continuer';

  @override
  String get groupKhatma => 'Khatma en groupe';

  @override
  String get guestBadge => 'Invité';

  @override
  String get homeCollectiveProgress => 'Progression collective';

  @override
  String get homeEmptyHint =>
      'Créez une Khatma ou rejoignez-en une pour suivre votre progression.';

  @override
  String get homeEmptyTitle => 'Commencez votre première Khatma';

  @override
  String get homeGoalToday => 'Objectif du jour';

  @override
  String homeHizbInProgress(String number) {
    return 'Hizb $number en cours';
  }

  @override
  String homeHizbReserved(String number) {
    return 'Hizb $number réservé';
  }

  @override
  String get homeLoadError => 'Impossible de charger vos Khatmas';

  @override
  String get homeLoadErrorHint => 'Vérifiez votre connexion, puis réessayez.';

  @override
  String get homePersonalProgress => 'Votre progression';

  @override
  String get inProgress => 'En cours';

  @override
  String get joinCollectiveKhatma => 'Rejoindre une Khatma collective';

  @override
  String get khatmaInProgress => 'Khatma en cours';

  @override
  String get lastActivity => 'Dernière activité';

  @override
  String get myTraining => 'Ma Formation';

  @override
  String get nextPrayer => 'Prière suivante';

  @override
  String get offlineNotice => 'Hors ligne — vos données seront synchronisées';

  @override
  String get prayerTimes => 'Horaires de prière';

  @override
  String get readingGoal => 'Objectif de lecture';

  @override
  String get readingGoalAchieved => 'Objectif atteint !';

  @override
  String readingGoalProgress(int completed, int target) {
    return '$completed/$target Hizb';
  }

  @override
  String get resume => 'Reprendre';

  @override
  String get retry => 'Réessayer';

  @override
  String get seeAll => 'Voir tout';

  @override
  String get statistics => 'Statistiques';

  @override
  String get khatmaRouteNotFoundTitle => 'Khatma introuvable';

  @override
  String get khatmaRouteNotFoundMessage =>
      'Cette Khatma n\'existe plus ou le lien n\'est pas valide.';

  @override
  String get khatmaRouteDemoUnavailableTitle => 'Khatma indisponible en démo';

  @override
  String get khatmaRouteDemoUnavailableMessage =>
      'Cette Khatma n\'est pas accessible en mode démo. Revenez à la liste ou créez une Khatma locale.';

  @override
  String get khatmaRouteAccessDeniedTitle => 'Accès refusé';

  @override
  String get khatmaRouteAccessDeniedMessage =>
      'Vous n\'avez pas accès à cette Khatma.';

  @override
  String get khatmaRouteNetworkErrorTitle => 'Erreur réseau';

  @override
  String get khatmaRouteNetworkErrorMessage =>
      'Impossible de charger la Khatma. Vérifiez votre connexion.';

  @override
  String get khatmaRouteLoadErrorTitle => 'Impossible de charger la Khatma';

  @override
  String get khatmaRouteLoadErrorMessage =>
      'Une erreur est survenue. Réessayez.';

  @override
  String get khatmaRouteLoading => 'Chargement de la Khatma...';

  @override
  String get myKhatmas => 'Mes Khatmas';

  @override
  String get joinWithCode => 'Rejoindre avec un code';

  @override
  String get back => 'Retour';

  @override
  String get wirdCompleteFinalPage => 'Terminer le Coran';

  @override
  String get wirdFinalPageCompleted =>
      'Alhamdulillah ! Vous avez terminé le Coran.';

  @override
  String get wirdMyWird => 'Mon Wird';

  @override
  String get wirdPlanTooltip => 'Plan';

  @override
  String get wirdConfigureTooltip => 'Configurer';

  @override
  String get wirdDailySectionTitle => 'Lecture du jour';

  @override
  String wirdObjectiveLabel(String target) {
    return 'Objectif: $target';
  }

  @override
  String wirdDailyCompleted(String target) {
    return '$target • Wird du jour accompli';
  }

  @override
  String get wirdRemainingOneRub => 'Il vous reste 1 Rub\'';

  @override
  String wirdRemainingManyRubs(int count) {
    return 'Il vous reste $count Rub\'';
  }

  @override
  String get wirdContinueSectionTitle => 'Continuer ma lecture';

  @override
  String get wirdContinueSubtitle => 'Reprenez là où vous vous êtes arrêté';

  @override
  String wirdHizbNumber(int number) {
    return 'Hizb $number';
  }

  @override
  String wirdSurahAyah(int surah, int ayah) {
    return 'Sourate $surah • Ayah $ayah';
  }

  @override
  String wirdPageNumber(int page) {
    return 'Page $page';
  }

  @override
  String wirdReadingMushaf(String mushaf) {
    return 'Lecture: $mushaf';
  }

  @override
  String get wirdNoReadingInProgress => 'Aucune lecture en cours';

  @override
  String get wirdResumeReading => 'Reprendre ma lecture';

  @override
  String get wirdStartReading => 'Commencer ma lecture';

  @override
  String get wirdDailyGoalTitle => 'Objectif quotidien';

  @override
  String get wirdDailyGoalSubtitle =>
      'Choisissez votre objectif de lecture quotidienne';

  @override
  String get wirdLoadError => 'Impossible de charger votre Wird';

  @override
  String get personalKhatmaTitle => 'MA KHATMA PERSONNELLE';

  @override
  String get personalKhatmaProgressionLabel => 'Progression';

  @override
  String get personalKhatmaDaysRemainingLabel => 'Jours restants';

  @override
  String personalKhatmaDaysRemainingValue(int days, String daysLabel) {
    return '$days $daysLabel';
  }

  @override
  String get personalKhatmaDaysUnit => 'jours';

  @override
  String get personalKhatmaDayUnit => 'jour';

  @override
  String get personalKhatmaScheduled => 'Programmé';

  @override
  String get personalKhatmaCompleted => 'Khatma accomplie — Al-hamdu lillāh';

  @override
  String get personalKhatmaCreateNew => 'Créer un nouveau plan';

  @override
  String personalKhatmaRemainingToRead(String remaining) {
    return 'Il reste $remaining à lire';
  }

  @override
  String get personalKhatmaContinueWithoutDeadline =>
      'Vous pouvez continuer votre lecture sans deadline';

  @override
  String get personalKhatmaManagePlan => 'Gérer mon plan';

  @override
  String get readingPlanTitle => 'Plan de lecture';

  @override
  String get readingPlanFreeGoalTitle => 'Objectif quotidien libre';

  @override
  String get readingPlanFreeGoalSubtitle => 'Lecture quotidienne sans deadline';

  @override
  String get readingPlanHijriMonthTitle => '1 Khatma / mois hégirien';

  @override
  String get readingPlanHijriMonthSubtitle =>
      'Finir le Quran en 1 mois lunaire';

  @override
  String get readingPlanGregorianMonthTitle => '1 Khatma / mois grégorien';

  @override
  String get readingPlanGregorianMonthSubtitle => 'Finir le Quran en 1 mois';

  @override
  String get readingPlanStartingLabel => 'Démarrage';

  @override
  String get readingPlanStartNowLabel => 'Commencer maintenant';

  @override
  String get readingPlanStartNextLabel => 'Commencer le prochain mois';

  @override
  String readingPlanStartNowHijriDescription(String month) {
    return 'Reste du mois de $month';
  }

  @override
  String readingPlanStartNowGregorianDescription(int days) {
    return 'Reste du mois ($days jours)';
  }

  @override
  String get readingPlanActivateFreeGoal => 'Activer l\'objectif libre';

  @override
  String get readingPlanCreatePlan => 'Créer le plan';

  @override
  String get readingPlanPreviewTitle => 'Aperçu';

  @override
  String get readingPlanPreviewPeriod => 'Période';

  @override
  String get readingPlanPreviewReadingDays => 'Jours de lecture';

  @override
  String readingPlanPreviewReadingDaysValue(int days) {
    return '$days jours';
  }

  @override
  String get readingPlanPreviewPace => 'Rythme recommandé';

  @override
  String readingPlanError(String error) {
    return 'Erreur: $error';
  }

  @override
  String get hijriMonthMuharram => 'Muharram';

  @override
  String get hijriMonthSafar => 'Safar';

  @override
  String get hijriMonthRabiAlAwwal => 'Rabi\' al-awwal';

  @override
  String get hijriMonthRabiAlThani => 'Rabi\' al-thani';

  @override
  String get hijriMonthJumadaAlAwwal => 'Jumada al-awwal';

  @override
  String get hijriMonthJumadaAlThani => 'Jumada al-thani';

  @override
  String get hijriMonthRajab => 'Rajab';

  @override
  String get hijriMonthShaban => 'Sha\'ban';

  @override
  String get hijriMonthRamadan => 'Ramadan';

  @override
  String get hijriMonthShawwal => 'Shawwal';

  @override
  String get hijriMonthDhuAlQidah => 'Dhu al-Qi\'dah';

  @override
  String get hijriMonthDhuAlHijjah => 'Dhu al-Hijjah';

  @override
  String get gregorianMonthJanuary => 'janvier';

  @override
  String get gregorianMonthFebruary => 'février';

  @override
  String get gregorianMonthMarch => 'mars';

  @override
  String get gregorianMonthApril => 'avril';

  @override
  String get gregorianMonthMay => 'mai';

  @override
  String get gregorianMonthJune => 'juin';

  @override
  String get gregorianMonthJuly => 'juillet';

  @override
  String get gregorianMonthAugust => 'août';

  @override
  String get gregorianMonthSeptember => 'septembre';

  @override
  String get gregorianMonthOctober => 'octobre';

  @override
  String get gregorianMonthNovember => 'novembre';

  @override
  String get gregorianMonthDecember => 'décembre';

  @override
  String monthOfHijri(String month) {
    return 'Mois de $month';
  }

  @override
  String monthOfGregorian(String month) {
    return 'Mois de $month';
  }

  @override
  String homePrayerPill(String prayerName, String timeRemaining) {
    return '$prayerName · $timeRemaining';
  }

  @override
  String homeNextPrayerSemantic(String prayerName, String timeRemaining) {
    return 'Prochaine prière : $prayerName dans $timeRemaining';
  }

  @override
  String homeRamadanPillFr(int day) {
    return 'Ramadan · Jour $day sur 30';
  }

  @override
  String homeRamadanPillEn(int day) {
    return 'Ramadan · Day $day of 30';
  }

  @override
  String homeRamadanPillAr(int day) {
    return 'رمضان · اليوم $day من 30';
  }

  @override
  String get notificationsTitle => 'Notifications';

  @override
  String get notificationsEmptyTitle => 'Aucune notification';

  @override
  String get notificationsEmptySubtitle => 'Vous êtes à jour';

  @override
  String get notificationsSettingsTitle => 'Paramètres des notifications';

  @override
  String get notificationsEnableReadingReminders =>
      'Activer les rappels de lecture';

  @override
  String get notificationsReceiveHizbReminders =>
      'Recevoir des rappels pour vos Hizb';

  @override
  String get notificationsGroupNotifications => 'Notifications de groupe';

  @override
  String get notificationsWorkshopReminders => 'Rappels d\'ateliers';

  @override
  String get notificationsMarkAsRead => 'Marquer comme lu';

  @override
  String get notificationsDelete => 'Supprimer';

  @override
  String get notificationsDemoReadingTime => 'C\'est l\'heure de lire';

  @override
  String get notificationsDemoReadingTimeBody =>
      'N\'oubliez pas de compléter votre Hizb du jour';

  @override
  String get notificationsDemoKhatmaReminder => 'Rappel Khatma';

  @override
  String get notificationsDemoKhatmaBody =>
      'Votre Khatma de groupe attend votre participation';

  @override
  String get notificationsDemoWorkshop => 'Atelier de formation';

  @override
  String get notificationsDemoWorkshopBody =>
      'Nouvelle session disponible la semaine prochaine';

  @override
  String notificationsTimeHoursAgo(int hours) {
    return 'Il y a $hours heures';
  }

  @override
  String get notificationsTimeYesterday => 'Hier';

  @override
  String notificationsTimeDaysAgo(int days) {
    return 'Il y a $days jours';
  }

  @override
  String get wirdTodayObjective => 'Objectif aujourd\'hui';

  @override
  String wirdPlusQuarterNext(int quarters) {
    return 'Puis $quarters quart du Hizb suivant';
  }

  @override
  String wirdPlusQuartersNext(int quarters) {
    return 'Puis $quarters quarts du Hizb suivant';
  }

  @override
  String get wirdMonthlyProgress => 'Progression';

  @override
  String wirdHizbCompleted(int count) {
    return '$count Hizb terminés';
  }

  @override
  String get wirdInProgressFirstHizb => 'En cours du 1er Hizb';

  @override
  String wirdDaysRemaining(int days) {
    return '$days jours restants';
  }

  @override
  String get wirdPersonalKhatma => 'Ma Khatma personnelle';

  @override
  String get wirdHizbUnit => 'Hizb';

  @override
  String wirdHizbOver(int current, int total) {
    return '$current / $total';
  }

  @override
  String get wirdHizbCompleted_one => '1 Hizb terminé';

  @override
  String wirdHizbCompleted_other(int count) {
    return '$count Hizb terminés';
  }

  @override
  String get wirdNextHizbInProgress => 'Hizb suivant en cours';

  @override
  String get wirdKhatmaInProgress => 'Khatma en cours';

  @override
  String wirdPercentOfKhatma(int percent) {
    return '$percent% de ma Khatma';
  }

  @override
  String wirdHizbCompletedOutOf(int completed, int total) {
    return '$completed Hizb terminé sur $total';
  }

  @override
  String wirdHizbCompletedOutOf_other(int completed, int total) {
    return '$completed Hizb terminés sur $total';
  }

  @override
  String get wirdOfMyKhatma => 'de ma Khatma';
}
