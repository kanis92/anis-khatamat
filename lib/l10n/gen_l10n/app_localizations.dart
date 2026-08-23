import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_ar.dart';
import 'app_localizations_en.dart';
import 'app_localizations_fr.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'gen_l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('ar'),
    Locale('en'),
    Locale('fr'),
  ];

  /// No description provided for @appTitle.
  ///
  /// In fr, this message translates to:
  /// **'ANIS Khatamat'**
  String get appTitle;

  /// No description provided for @login.
  ///
  /// In fr, this message translates to:
  /// **'Connexion'**
  String get login;

  /// No description provided for @register.
  ///
  /// In fr, this message translates to:
  /// **'Créer un compte'**
  String get register;

  /// No description provided for @email.
  ///
  /// In fr, this message translates to:
  /// **'Email'**
  String get email;

  /// No description provided for @password.
  ///
  /// In fr, this message translates to:
  /// **'Mot de passe'**
  String get password;

  /// No description provided for @settings.
  ///
  /// In fr, this message translates to:
  /// **'Paramètres'**
  String get settings;

  /// No description provided for @home.
  ///
  /// In fr, this message translates to:
  /// **'Accueil'**
  String get home;

  /// No description provided for @khatma.
  ///
  /// In fr, this message translates to:
  /// **'Khatma'**
  String get khatma;

  /// No description provided for @notifications.
  ///
  /// In fr, this message translates to:
  /// **'Notifications'**
  String get notifications;

  /// No description provided for @training.
  ///
  /// In fr, this message translates to:
  /// **'Formation'**
  String get training;

  /// No description provided for @achievements.
  ///
  /// In fr, this message translates to:
  /// **'Accomplissements'**
  String get achievements;

  /// No description provided for @createKhatma.
  ///
  /// In fr, this message translates to:
  /// **'Créer une Khatma'**
  String get createKhatma;

  /// No description provided for @createAccount.
  ///
  /// In fr, this message translates to:
  /// **'Créer un compte'**
  String get createAccount;

  /// No description provided for @changePassword.
  ///
  /// In fr, this message translates to:
  /// **'Modifier le mot de passe'**
  String get changePassword;

  /// No description provided for @manageNotifications.
  ///
  /// In fr, this message translates to:
  /// **'Gérer les notifications'**
  String get manageNotifications;

  /// No description provided for @changeLanguage.
  ///
  /// In fr, this message translates to:
  /// **'Changer la langue'**
  String get changeLanguage;

  /// No description provided for @privacyPolicy.
  ///
  /// In fr, this message translates to:
  /// **'Politique de confidentialité'**
  String get privacyPolicy;

  /// No description provided for @darkMode.
  ///
  /// In fr, this message translates to:
  /// **'Mode sombre'**
  String get darkMode;

  /// No description provided for @logout.
  ///
  /// In fr, this message translates to:
  /// **'Déconnexion'**
  String get logout;

  /// No description provided for @welcomeGreeting.
  ///
  /// In fr, this message translates to:
  /// **'Assalamu alaykum'**
  String get welcomeGreeting;

  /// No description provided for @welcomeSubtitle.
  ///
  /// In fr, this message translates to:
  /// **'Bienvenue sur votre espace de lecture'**
  String get welcomeSubtitle;

  /// No description provided for @quickActions.
  ///
  /// In fr, this message translates to:
  /// **'Actions rapides'**
  String get quickActions;

  /// No description provided for @progression.
  ///
  /// In fr, this message translates to:
  /// **'Progression'**
  String get progression;

  /// No description provided for @hizbCompleted.
  ///
  /// In fr, this message translates to:
  /// **'Hizb complétés'**
  String get hizbCompleted;

  /// No description provided for @upcomingReadings.
  ///
  /// In fr, this message translates to:
  /// **'Prochaines lectures'**
  String get upcomingReadings;

  /// No description provided for @noReadingsScheduled.
  ///
  /// In fr, this message translates to:
  /// **'Aucune lecture planifiée'**
  String get noReadingsScheduled;

  /// No description provided for @createKhatmaToStart.
  ///
  /// In fr, this message translates to:
  /// **'Créez une Khatma pour commencer à suivre votre progression.'**
  String get createKhatmaToStart;

  /// No description provided for @khatmatInProgress.
  ///
  /// In fr, this message translates to:
  /// **'{count} Khatma(s) en cours'**
  String khatmatInProgress(int count);

  /// No description provided for @continueReading.
  ///
  /// In fr, this message translates to:
  /// **'Continuez votre lecture pour avancer dans vos Khatmat.'**
  String get continueReading;

  /// No description provided for @mushaf.
  ///
  /// In fr, this message translates to:
  /// **'Mushaf'**
  String get mushaf;

  /// No description provided for @demoMode.
  ///
  /// In fr, this message translates to:
  /// **'Mode démo (tester sans connexion)'**
  String get demoMode;

  /// No description provided for @loginButton.
  ///
  /// In fr, this message translates to:
  /// **'Se connecter'**
  String get loginButton;

  /// No description provided for @individual.
  ///
  /// In fr, this message translates to:
  /// **'Individuelle'**
  String get individual;

  /// No description provided for @group.
  ///
  /// In fr, this message translates to:
  /// **'Groupe'**
  String get group;

  /// No description provided for @chooseKhatmaType.
  ///
  /// In fr, this message translates to:
  /// **'Choisissez le type de Khatma'**
  String get chooseKhatmaType;

  /// No description provided for @createNewKhatma.
  ///
  /// In fr, this message translates to:
  /// **'Créer une nouvelle Khatma'**
  String get createNewKhatma;

  /// No description provided for @myKhatmat.
  ///
  /// In fr, this message translates to:
  /// **'Vos Khatmat en cours'**
  String get myKhatmat;

  /// No description provided for @noKhatma.
  ///
  /// In fr, this message translates to:
  /// **'Aucune Khatma en cours'**
  String get noKhatma;

  /// No description provided for @readingOptions.
  ///
  /// In fr, this message translates to:
  /// **'Options de lecture'**
  String get readingOptions;

  /// No description provided for @mushafHafs.
  ///
  /// In fr, this message translates to:
  /// **'Mushaf Hafs'**
  String get mushafHafs;

  /// No description provided for @mushafHafsDesc.
  ///
  /// In fr, this message translates to:
  /// **'Version la plus répandue'**
  String get mushafHafsDesc;

  /// No description provided for @mushafWarsh.
  ///
  /// In fr, this message translates to:
  /// **'Mushaf Warsh'**
  String get mushafWarsh;

  /// No description provided for @mushafWarshDesc.
  ///
  /// In fr, this message translates to:
  /// **'Version d\'Afrique du Nord'**
  String get mushafWarshDesc;

  /// No description provided for @chooseMushafType.
  ///
  /// In fr, this message translates to:
  /// **'Choisissez le type de Mushaf'**
  String get chooseMushafType;

  /// No description provided for @mushafWomen.
  ///
  /// In fr, this message translates to:
  /// **'Mushaf Femmes'**
  String get mushafWomen;

  /// No description provided for @mushafWomenDesc.
  ///
  /// In fr, this message translates to:
  /// **'مصحف حفص — thème rose élégant'**
  String get mushafWomenDesc;

  /// No description provided for @openMushaf.
  ///
  /// In fr, this message translates to:
  /// **'Ouvrir le Mushaf'**
  String get openMushaf;

  /// No description provided for @mushafHizb.
  ///
  /// In fr, this message translates to:
  /// **'Hizb'**
  String get mushafHizb;

  /// No description provided for @mushafPage.
  ///
  /// In fr, this message translates to:
  /// **'Page'**
  String get mushafPage;

  /// Le numéro est déjà formaté par mushafNumber() : chiffres arabes-indiques en AR
  ///
  /// In fr, this message translates to:
  /// **'Hizb {number}'**
  String mushafHizbNumber(String number);

  /// No description provided for @mushafPageNumber.
  ///
  /// In fr, this message translates to:
  /// **'Page {number}'**
  String mushafPageNumber(String number);

  /// No description provided for @mushafKhatmaHizbContext.
  ///
  /// In fr, this message translates to:
  /// **'Hizb {number} de votre Khatma'**
  String mushafKhatmaHizbContext(String number);

  /// No description provided for @mushafKhatmaHizbLeft.
  ///
  /// In fr, this message translates to:
  /// **'Vous avez quitté le Hizb {number} — revenir'**
  String mushafKhatmaHizbLeft(String number);

  /// No description provided for @mushafBookmarkHere.
  ///
  /// In fr, this message translates to:
  /// **'Marquer ici'**
  String get mushafBookmarkHere;

  /// No description provided for @mushafBookmarkHereDesc.
  ///
  /// In fr, this message translates to:
  /// **'Signet pour reprendre plus tard'**
  String get mushafBookmarkHereDesc;

  /// No description provided for @mushafUnbookmark.
  ///
  /// In fr, this message translates to:
  /// **'Retirer le signet'**
  String get mushafUnbookmark;

  /// No description provided for @completionAlhamdulillah.
  ///
  /// In fr, this message translates to:
  /// **'Alhamdulillah'**
  String get completionAlhamdulillah;

  /// No description provided for @completionAccomplished.
  ///
  /// In fr, this message translates to:
  /// **'Cette Khatma est accomplie.'**
  String get completionAccomplished;

  /// No description provided for @completionDua.
  ///
  /// In fr, this message translates to:
  /// **'Qu\'Allah accepte cette lecture et les efforts de chacun.'**
  String get completionDua;

  /// No description provided for @completionHeaderSubtitle.
  ///
  /// In fr, this message translates to:
  /// **'Votre Khatma est accomplie.'**
  String get completionHeaderSubtitle;

  /// No description provided for @completionHizbAccomplished.
  ///
  /// In fr, this message translates to:
  /// **'{count} Hizb accomplis'**
  String completionHizbAccomplished(int count);

  /// No description provided for @completionParticipantsCount.
  ///
  /// In fr, this message translates to:
  /// **'{count} participants'**
  String completionParticipantsCount(int count);

  /// No description provided for @completionDurationDays.
  ///
  /// In fr, this message translates to:
  /// **'Terminée en {days} jours'**
  String completionDurationDays(int days);

  /// No description provided for @completionDurationOneDay.
  ///
  /// In fr, this message translates to:
  /// **'Terminée en 1 jour'**
  String get completionDurationOneDay;

  /// No description provided for @completionClosedOn.
  ///
  /// In fr, this message translates to:
  /// **'Clôturée le {date}'**
  String completionClosedOn(String date);

  /// No description provided for @completionCollectiveMessage.
  ///
  /// In fr, this message translates to:
  /// **'{count} personnes ont participé à cette Khatma.'**
  String completionCollectiveMessage(int count);

  /// No description provided for @completionWithParticipants.
  ///
  /// In fr, this message translates to:
  /// **'Avec {names}'**
  String completionWithParticipants(String names);

  /// No description provided for @completionStartNew.
  ///
  /// In fr, this message translates to:
  /// **'Commencer une nouvelle Khatma'**
  String get completionStartNew;

  /// No description provided for @completionShare.
  ///
  /// In fr, this message translates to:
  /// **'Partager'**
  String get completionShare;

  /// No description provided for @completionBackToMyKhatmas.
  ///
  /// In fr, this message translates to:
  /// **'Retour à mes Khatmas'**
  String get completionBackToMyKhatmas;

  /// No description provided for @completionShareMessage.
  ///
  /// In fr, this message translates to:
  /// **'Alhamdulillah, notre Khatma « {title} » vient d\'être accomplie sur Anis. Qu\'Allah accepte les efforts de chacun.'**
  String completionShareMessage(String title);

  /// No description provided for @completionViewClosure.
  ///
  /// In fr, this message translates to:
  /// **'Voir la clôture'**
  String get completionViewClosure;

  /// No description provided for @completionFinishedBadge.
  ///
  /// In fr, this message translates to:
  /// **'Terminée'**
  String get completionFinishedBadge;

  /// No description provided for @completionSee.
  ///
  /// In fr, this message translates to:
  /// **'Voir'**
  String get completionSee;

  /// No description provided for @completionProgressFraction.
  ///
  /// In fr, this message translates to:
  /// **'{completed}/{total}'**
  String completionProgressFraction(int completed, int total);

  /// No description provided for @khatmaTitle.
  ///
  /// In fr, this message translates to:
  /// **'Titre de la Khatma'**
  String get khatmaTitle;

  /// No description provided for @objectives.
  ///
  /// In fr, this message translates to:
  /// **'Objectifs'**
  String get objectives;

  /// No description provided for @inviteMembers.
  ///
  /// In fr, this message translates to:
  /// **'Inviter des membres'**
  String get inviteMembers;

  /// No description provided for @memberEmail.
  ///
  /// In fr, this message translates to:
  /// **'Email du membre'**
  String get memberEmail;

  /// No description provided for @nextDistribution.
  ///
  /// In fr, this message translates to:
  /// **'Suivant → Distribution des Hizb'**
  String get nextDistribution;

  /// No description provided for @hizbDistribution.
  ///
  /// In fr, this message translates to:
  /// **'Distribution des Hizb'**
  String get hizbDistribution;

  /// No description provided for @hizbAssigned.
  ///
  /// In fr, this message translates to:
  /// **'{count}/{total} Hizb assignés'**
  String hizbAssigned(int count, int total);

  /// No description provided for @autoDistribution.
  ///
  /// In fr, this message translates to:
  /// **'Auto'**
  String get autoDistribution;

  /// No description provided for @manualDistribution.
  ///
  /// In fr, this message translates to:
  /// **'Manuel'**
  String get manualDistribution;

  /// No description provided for @confirmDistribution.
  ///
  /// In fr, this message translates to:
  /// **'Confirmer la distribution'**
  String get confirmDistribution;

  /// No description provided for @sendReminder.
  ///
  /// In fr, this message translates to:
  /// **'Envoyer un rappel'**
  String get sendReminder;

  /// No description provided for @listOf60Hizb.
  ///
  /// In fr, this message translates to:
  /// **'Liste des 60 Hizb'**
  String get listOf60Hizb;

  /// No description provided for @unassigned.
  ///
  /// In fr, this message translates to:
  /// **'Non assigné'**
  String get unassigned;

  /// No description provided for @assignedTo.
  ///
  /// In fr, this message translates to:
  /// **'Assigné à'**
  String get assignedTo;

  /// No description provided for @assignedToLabel.
  ///
  /// In fr, this message translates to:
  /// **'Assigné à: {name}'**
  String assignedToLabel(String name);

  /// No description provided for @khatmaCompleted.
  ///
  /// In fr, this message translates to:
  /// **'Khatma terminée ! ماشاء الله'**
  String get khatmaCompleted;

  /// No description provided for @account.
  ///
  /// In fr, this message translates to:
  /// **'Compte'**
  String get account;

  /// No description provided for @preferences.
  ///
  /// In fr, this message translates to:
  /// **'Préférences'**
  String get preferences;

  /// No description provided for @legal.
  ///
  /// In fr, this message translates to:
  /// **'Légal'**
  String get legal;

  /// No description provided for @user.
  ///
  /// In fr, this message translates to:
  /// **'Utilisateur'**
  String get user;

  /// No description provided for @share.
  ///
  /// In fr, this message translates to:
  /// **'Partager'**
  String get share;

  /// No description provided for @shareAchievements.
  ///
  /// In fr, this message translates to:
  /// **'Partager'**
  String get shareAchievements;

  /// No description provided for @shareAchievementsDesc.
  ///
  /// In fr, this message translates to:
  /// **'Partagez votre progression sur WhatsApp ou d\'autres applications.'**
  String get shareAchievementsDesc;

  /// No description provided for @shareWhatsApp.
  ///
  /// In fr, this message translates to:
  /// **'Partager (WhatsApp, etc.)'**
  String get shareWhatsApp;

  /// No description provided for @shareYourProgress.
  ///
  /// In fr, this message translates to:
  /// **'Partager mes accomplissements'**
  String get shareYourProgress;

  /// No description provided for @language.
  ///
  /// In fr, this message translates to:
  /// **'Langue'**
  String get language;

  /// No description provided for @french.
  ///
  /// In fr, this message translates to:
  /// **'Français'**
  String get french;

  /// No description provided for @english.
  ///
  /// In fr, this message translates to:
  /// **'English'**
  String get english;

  /// No description provided for @arabic.
  ///
  /// In fr, this message translates to:
  /// **'العربية'**
  String get arabic;

  /// No description provided for @system.
  ///
  /// In fr, this message translates to:
  /// **'Système'**
  String get system;

  /// No description provided for @send.
  ///
  /// In fr, this message translates to:
  /// **'Envoyer'**
  String get send;

  /// No description provided for @cancel.
  ///
  /// In fr, this message translates to:
  /// **'Annuler'**
  String get cancel;

  /// No description provided for @featureComingSoon.
  ///
  /// In fr, this message translates to:
  /// **'Fonctionnalité à implémenter'**
  String get featureComingSoon;

  /// No description provided for @urlNotAvailable.
  ///
  /// In fr, this message translates to:
  /// **'URL non disponible'**
  String get urlNotAvailable;

  /// No description provided for @resetEmailMessage.
  ///
  /// In fr, this message translates to:
  /// **'Un email de réinitialisation vous sera envoyé.'**
  String get resetEmailMessage;

  /// No description provided for @bookmarks.
  ///
  /// In fr, this message translates to:
  /// **'Favoris'**
  String get bookmarks;

  /// No description provided for @completed.
  ///
  /// In fr, this message translates to:
  /// **'Terminées'**
  String get completed;

  /// No description provided for @continueAction.
  ///
  /// In fr, this message translates to:
  /// **'Continuer'**
  String get continueAction;

  /// No description provided for @groupKhatma.
  ///
  /// In fr, this message translates to:
  /// **'Khatma en groupe'**
  String get groupKhatma;

  /// No description provided for @guestBadge.
  ///
  /// In fr, this message translates to:
  /// **'Invité'**
  String get guestBadge;

  /// No description provided for @homeCollectiveProgress.
  ///
  /// In fr, this message translates to:
  /// **'Progression collective'**
  String get homeCollectiveProgress;

  /// No description provided for @homeEmptyHint.
  ///
  /// In fr, this message translates to:
  /// **'Créez une Khatma ou rejoignez-en une pour suivre votre progression.'**
  String get homeEmptyHint;

  /// No description provided for @homeEmptyTitle.
  ///
  /// In fr, this message translates to:
  /// **'Commencez votre première Khatma'**
  String get homeEmptyTitle;

  /// No description provided for @homeGoalToday.
  ///
  /// In fr, this message translates to:
  /// **'Objectif du jour'**
  String get homeGoalToday;

  /// Le numéro est déjà formaté par mushafNumber()
  ///
  /// In fr, this message translates to:
  /// **'Hizb {number} en cours'**
  String homeHizbInProgress(String number);

  /// Le numéro est déjà formaté par mushafNumber() : chiffres arabes-indiques en AR
  ///
  /// In fr, this message translates to:
  /// **'Hizb {number} réservé'**
  String homeHizbReserved(String number);

  /// No description provided for @homeLoadError.
  ///
  /// In fr, this message translates to:
  /// **'Impossible de charger vos Khatmas'**
  String get homeLoadError;

  /// No description provided for @homeLoadErrorHint.
  ///
  /// In fr, this message translates to:
  /// **'Vérifiez votre connexion, puis réessayez.'**
  String get homeLoadErrorHint;

  /// No description provided for @homePersonalProgress.
  ///
  /// In fr, this message translates to:
  /// **'Votre progression'**
  String get homePersonalProgress;

  /// No description provided for @inProgress.
  ///
  /// In fr, this message translates to:
  /// **'En cours'**
  String get inProgress;

  /// No description provided for @joinCollectiveKhatma.
  ///
  /// In fr, this message translates to:
  /// **'Rejoindre une Khatma collective'**
  String get joinCollectiveKhatma;

  /// No description provided for @khatmaInProgress.
  ///
  /// In fr, this message translates to:
  /// **'Khatma en cours'**
  String get khatmaInProgress;

  /// No description provided for @lastActivity.
  ///
  /// In fr, this message translates to:
  /// **'Dernière activité'**
  String get lastActivity;

  /// No description provided for @myTraining.
  ///
  /// In fr, this message translates to:
  /// **'Ma Formation'**
  String get myTraining;

  /// No description provided for @nextPrayer.
  ///
  /// In fr, this message translates to:
  /// **'Prière suivante'**
  String get nextPrayer;

  /// No description provided for @offlineNotice.
  ///
  /// In fr, this message translates to:
  /// **'Hors ligne — vos données seront synchronisées'**
  String get offlineNotice;

  /// No description provided for @prayerTimes.
  ///
  /// In fr, this message translates to:
  /// **'Horaires de prière'**
  String get prayerTimes;

  /// No description provided for @readingGoal.
  ///
  /// In fr, this message translates to:
  /// **'Objectif de lecture'**
  String get readingGoal;

  /// No description provided for @readingGoalAchieved.
  ///
  /// In fr, this message translates to:
  /// **'Objectif atteint !'**
  String get readingGoalAchieved;

  /// No description provided for @readingGoalProgress.
  ///
  /// In fr, this message translates to:
  /// **'{completed}/{target} Hizb'**
  String readingGoalProgress(int completed, int target);

  /// No description provided for @resume.
  ///
  /// In fr, this message translates to:
  /// **'Reprendre'**
  String get resume;

  /// No description provided for @retry.
  ///
  /// In fr, this message translates to:
  /// **'Réessayer'**
  String get retry;

  /// No description provided for @seeAll.
  ///
  /// In fr, this message translates to:
  /// **'Voir tout'**
  String get seeAll;

  /// No description provided for @statistics.
  ///
  /// In fr, this message translates to:
  /// **'Statistiques'**
  String get statistics;

  /// No description provided for @khatmaRouteNotFoundTitle.
  ///
  /// In fr, this message translates to:
  /// **'Khatma introuvable'**
  String get khatmaRouteNotFoundTitle;

  /// No description provided for @khatmaRouteNotFoundMessage.
  ///
  /// In fr, this message translates to:
  /// **'Cette Khatma n\'existe plus ou le lien n\'est pas valide.'**
  String get khatmaRouteNotFoundMessage;

  /// No description provided for @khatmaRouteDemoUnavailableTitle.
  ///
  /// In fr, this message translates to:
  /// **'Khatma indisponible en démo'**
  String get khatmaRouteDemoUnavailableTitle;

  /// No description provided for @khatmaRouteDemoUnavailableMessage.
  ///
  /// In fr, this message translates to:
  /// **'Cette Khatma n\'est pas accessible en mode démo. Revenez à la liste ou créez une Khatma locale.'**
  String get khatmaRouteDemoUnavailableMessage;

  /// No description provided for @khatmaRouteAccessDeniedTitle.
  ///
  /// In fr, this message translates to:
  /// **'Accès refusé'**
  String get khatmaRouteAccessDeniedTitle;

  /// No description provided for @khatmaRouteAccessDeniedMessage.
  ///
  /// In fr, this message translates to:
  /// **'Vous n\'avez pas accès à cette Khatma.'**
  String get khatmaRouteAccessDeniedMessage;

  /// No description provided for @khatmaRouteNetworkErrorTitle.
  ///
  /// In fr, this message translates to:
  /// **'Erreur réseau'**
  String get khatmaRouteNetworkErrorTitle;

  /// No description provided for @khatmaRouteNetworkErrorMessage.
  ///
  /// In fr, this message translates to:
  /// **'Impossible de charger la Khatma. Vérifiez votre connexion.'**
  String get khatmaRouteNetworkErrorMessage;

  /// No description provided for @khatmaRouteLoadErrorTitle.
  ///
  /// In fr, this message translates to:
  /// **'Impossible de charger la Khatma'**
  String get khatmaRouteLoadErrorTitle;

  /// No description provided for @khatmaRouteLoadErrorMessage.
  ///
  /// In fr, this message translates to:
  /// **'Une erreur est survenue. Réessayez.'**
  String get khatmaRouteLoadErrorMessage;

  /// No description provided for @khatmaRouteLoading.
  ///
  /// In fr, this message translates to:
  /// **'Chargement de la Khatma...'**
  String get khatmaRouteLoading;

  /// No description provided for @myKhatmas.
  ///
  /// In fr, this message translates to:
  /// **'Mes Khatmas'**
  String get myKhatmas;

  /// No description provided for @joinWithCode.
  ///
  /// In fr, this message translates to:
  /// **'Rejoindre avec un code'**
  String get joinWithCode;

  /// No description provided for @back.
  ///
  /// In fr, this message translates to:
  /// **'Retour'**
  String get back;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['ar', 'en', 'fr'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'ar':
      return AppLocalizationsAr();
    case 'en':
      return AppLocalizationsEn();
    case 'fr':
      return AppLocalizationsFr();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
