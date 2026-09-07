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

  /// No description provided for @wird.
  ///
  /// In fr, this message translates to:
  /// **'Wird'**
  String get wird;

  /// No description provided for @formations.
  ///
  /// In fr, this message translates to:
  /// **'Formations'**
  String get formations;

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

  /// No description provided for @viewMyKhatmat.
  ///
  /// In fr, this message translates to:
  /// **'Voir mes Khatmat'**
  String get viewMyKhatmat;

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

  /// No description provided for @participantSingular.
  ///
  /// In fr, this message translates to:
  /// **'1 participant'**
  String get participantSingular;

  /// No description provided for @participantPlural.
  ///
  /// In fr, this message translates to:
  /// **'{count} participants'**
  String participantPlural(int count);

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

  /// No description provided for @wirdCompleteFinalPage.
  ///
  /// In fr, this message translates to:
  /// **'Terminer le Coran'**
  String get wirdCompleteFinalPage;

  /// No description provided for @wirdFinalPageCompleted.
  ///
  /// In fr, this message translates to:
  /// **'Alhamdulillah ! Vous avez terminé le Coran.'**
  String get wirdFinalPageCompleted;

  /// No description provided for @wirdMyWird.
  ///
  /// In fr, this message translates to:
  /// **'Mon Wird'**
  String get wirdMyWird;

  /// No description provided for @wirdPlanTooltip.
  ///
  /// In fr, this message translates to:
  /// **'Plan'**
  String get wirdPlanTooltip;

  /// No description provided for @wirdConfigureTooltip.
  ///
  /// In fr, this message translates to:
  /// **'Configurer'**
  String get wirdConfigureTooltip;

  /// No description provided for @wirdDailySectionTitle.
  ///
  /// In fr, this message translates to:
  /// **'Lecture du jour'**
  String get wirdDailySectionTitle;

  /// No description provided for @wirdObjectiveLabel.
  ///
  /// In fr, this message translates to:
  /// **'Objectif: {target}'**
  String wirdObjectiveLabel(String target);

  /// No description provided for @wirdDailyCompleted.
  ///
  /// In fr, this message translates to:
  /// **'{target} • Wird du jour accompli'**
  String wirdDailyCompleted(String target);

  /// No description provided for @wirdRemainingOneRub.
  ///
  /// In fr, this message translates to:
  /// **'Il vous reste 1 Rub\''**
  String get wirdRemainingOneRub;

  /// No description provided for @wirdRemainingManyRubs.
  ///
  /// In fr, this message translates to:
  /// **'Il vous reste {count} Rub\''**
  String wirdRemainingManyRubs(int count);

  /// No description provided for @wirdContinueSectionTitle.
  ///
  /// In fr, this message translates to:
  /// **'Continuer ma lecture'**
  String get wirdContinueSectionTitle;

  /// No description provided for @wirdContinueSubtitle.
  ///
  /// In fr, this message translates to:
  /// **'Reprenez là où vous vous êtes arrêté'**
  String get wirdContinueSubtitle;

  /// No description provided for @wirdHizbNumber.
  ///
  /// In fr, this message translates to:
  /// **'Hizb {number}'**
  String wirdHizbNumber(int number);

  /// No description provided for @wirdSurahAyah.
  ///
  /// In fr, this message translates to:
  /// **'Sourate {surah} • Ayah {ayah}'**
  String wirdSurahAyah(int surah, int ayah);

  /// No description provided for @wirdPageNumber.
  ///
  /// In fr, this message translates to:
  /// **'Page {page}'**
  String wirdPageNumber(int page);

  /// No description provided for @wirdReadingMushaf.
  ///
  /// In fr, this message translates to:
  /// **'Lecture: {mushaf}'**
  String wirdReadingMushaf(String mushaf);

  /// No description provided for @wirdNoReadingInProgress.
  ///
  /// In fr, this message translates to:
  /// **'Aucune lecture en cours'**
  String get wirdNoReadingInProgress;

  /// No description provided for @wirdResumeReading.
  ///
  /// In fr, this message translates to:
  /// **'Reprendre ma lecture'**
  String get wirdResumeReading;

  /// No description provided for @wirdStartReading.
  ///
  /// In fr, this message translates to:
  /// **'Commencer ma lecture'**
  String get wirdStartReading;

  /// No description provided for @wirdDailyGoalTitle.
  ///
  /// In fr, this message translates to:
  /// **'Objectif quotidien'**
  String get wirdDailyGoalTitle;

  /// No description provided for @wirdDailyGoalSubtitle.
  ///
  /// In fr, this message translates to:
  /// **'Choisissez votre objectif de lecture quotidienne'**
  String get wirdDailyGoalSubtitle;

  /// No description provided for @wirdLoadError.
  ///
  /// In fr, this message translates to:
  /// **'Impossible de charger votre Wird'**
  String get wirdLoadError;

  /// No description provided for @personalKhatmaTitle.
  ///
  /// In fr, this message translates to:
  /// **'MA KHATMA PERSONNELLE'**
  String get personalKhatmaTitle;

  /// No description provided for @personalKhatmaProgressionLabel.
  ///
  /// In fr, this message translates to:
  /// **'Progression'**
  String get personalKhatmaProgressionLabel;

  /// No description provided for @personalKhatmaDaysRemainingLabel.
  ///
  /// In fr, this message translates to:
  /// **'Jours restants'**
  String get personalKhatmaDaysRemainingLabel;

  /// No description provided for @personalKhatmaDaysRemainingValue.
  ///
  /// In fr, this message translates to:
  /// **'{days} {daysLabel}'**
  String personalKhatmaDaysRemainingValue(int days, String daysLabel);

  /// No description provided for @personalKhatmaDaysUnit.
  ///
  /// In fr, this message translates to:
  /// **'jours'**
  String get personalKhatmaDaysUnit;

  /// No description provided for @personalKhatmaDayUnit.
  ///
  /// In fr, this message translates to:
  /// **'jour'**
  String get personalKhatmaDayUnit;

  /// No description provided for @personalKhatmaScheduled.
  ///
  /// In fr, this message translates to:
  /// **'Programmé'**
  String get personalKhatmaScheduled;

  /// No description provided for @personalKhatmaCompleted.
  ///
  /// In fr, this message translates to:
  /// **'Khatma accomplie — Al-hamdu lillāh'**
  String get personalKhatmaCompleted;

  /// No description provided for @personalKhatmaCreateNew.
  ///
  /// In fr, this message translates to:
  /// **'Créer un nouveau plan'**
  String get personalKhatmaCreateNew;

  /// No description provided for @personalKhatmaRemainingToRead.
  ///
  /// In fr, this message translates to:
  /// **'Il reste {remaining} à lire'**
  String personalKhatmaRemainingToRead(String remaining);

  /// No description provided for @personalKhatmaContinueWithoutDeadline.
  ///
  /// In fr, this message translates to:
  /// **'Vous pouvez continuer votre lecture sans deadline'**
  String get personalKhatmaContinueWithoutDeadline;

  /// No description provided for @personalKhatmaManagePlan.
  ///
  /// In fr, this message translates to:
  /// **'Gérer mon plan'**
  String get personalKhatmaManagePlan;

  /// No description provided for @readingPlanTitle.
  ///
  /// In fr, this message translates to:
  /// **'Plan de lecture'**
  String get readingPlanTitle;

  /// No description provided for @readingPlanFreeGoalTitle.
  ///
  /// In fr, this message translates to:
  /// **'Objectif quotidien libre'**
  String get readingPlanFreeGoalTitle;

  /// No description provided for @readingPlanFreeGoalSubtitle.
  ///
  /// In fr, this message translates to:
  /// **'Lecture quotidienne sans deadline'**
  String get readingPlanFreeGoalSubtitle;

  /// No description provided for @readingPlanHijriMonthTitle.
  ///
  /// In fr, this message translates to:
  /// **'1 Khatma / mois hégirien'**
  String get readingPlanHijriMonthTitle;

  /// No description provided for @readingPlanHijriMonthSubtitle.
  ///
  /// In fr, this message translates to:
  /// **'Finir le Quran en 1 mois lunaire'**
  String get readingPlanHijriMonthSubtitle;

  /// No description provided for @readingPlanGregorianMonthTitle.
  ///
  /// In fr, this message translates to:
  /// **'1 Khatma / mois grégorien'**
  String get readingPlanGregorianMonthTitle;

  /// No description provided for @readingPlanGregorianMonthSubtitle.
  ///
  /// In fr, this message translates to:
  /// **'Finir le Quran en 1 mois'**
  String get readingPlanGregorianMonthSubtitle;

  /// No description provided for @readingPlanStartingLabel.
  ///
  /// In fr, this message translates to:
  /// **'Démarrage'**
  String get readingPlanStartingLabel;

  /// No description provided for @readingPlanStartNowLabel.
  ///
  /// In fr, this message translates to:
  /// **'Commencer maintenant'**
  String get readingPlanStartNowLabel;

  /// No description provided for @readingPlanStartNextLabel.
  ///
  /// In fr, this message translates to:
  /// **'Commencer le prochain mois'**
  String get readingPlanStartNextLabel;

  /// No description provided for @readingPlanStartNowHijriDescription.
  ///
  /// In fr, this message translates to:
  /// **'Reste du mois de {month}'**
  String readingPlanStartNowHijriDescription(String month);

  /// No description provided for @readingPlanStartNowGregorianDescription.
  ///
  /// In fr, this message translates to:
  /// **'Reste du mois ({days} jours)'**
  String readingPlanStartNowGregorianDescription(int days);

  /// No description provided for @readingPlanActivateFreeGoal.
  ///
  /// In fr, this message translates to:
  /// **'Activer l\'objectif libre'**
  String get readingPlanActivateFreeGoal;

  /// No description provided for @readingPlanCreatePlan.
  ///
  /// In fr, this message translates to:
  /// **'Créer le plan'**
  String get readingPlanCreatePlan;

  /// No description provided for @readingPlanPreviewTitle.
  ///
  /// In fr, this message translates to:
  /// **'Aperçu'**
  String get readingPlanPreviewTitle;

  /// No description provided for @readingPlanPreviewPeriod.
  ///
  /// In fr, this message translates to:
  /// **'Période'**
  String get readingPlanPreviewPeriod;

  /// No description provided for @readingPlanPreviewReadingDays.
  ///
  /// In fr, this message translates to:
  /// **'Jours de lecture'**
  String get readingPlanPreviewReadingDays;

  /// No description provided for @readingPlanPreviewReadingDaysValue.
  ///
  /// In fr, this message translates to:
  /// **'{days} jours'**
  String readingPlanPreviewReadingDaysValue(int days);

  /// No description provided for @readingPlanPreviewPace.
  ///
  /// In fr, this message translates to:
  /// **'Rythme recommandé'**
  String get readingPlanPreviewPace;

  /// No description provided for @readingPlanError.
  ///
  /// In fr, this message translates to:
  /// **'Erreur: {error}'**
  String readingPlanError(String error);

  /// No description provided for @hijriMonthMuharram.
  ///
  /// In fr, this message translates to:
  /// **'Muharram'**
  String get hijriMonthMuharram;

  /// No description provided for @hijriMonthSafar.
  ///
  /// In fr, this message translates to:
  /// **'Safar'**
  String get hijriMonthSafar;

  /// No description provided for @hijriMonthRabiAlAwwal.
  ///
  /// In fr, this message translates to:
  /// **'Rabi\' al-awwal'**
  String get hijriMonthRabiAlAwwal;

  /// No description provided for @hijriMonthRabiAlThani.
  ///
  /// In fr, this message translates to:
  /// **'Rabi\' al-thani'**
  String get hijriMonthRabiAlThani;

  /// No description provided for @hijriMonthJumadaAlAwwal.
  ///
  /// In fr, this message translates to:
  /// **'Jumada al-awwal'**
  String get hijriMonthJumadaAlAwwal;

  /// No description provided for @hijriMonthJumadaAlThani.
  ///
  /// In fr, this message translates to:
  /// **'Jumada al-thani'**
  String get hijriMonthJumadaAlThani;

  /// No description provided for @hijriMonthRajab.
  ///
  /// In fr, this message translates to:
  /// **'Rajab'**
  String get hijriMonthRajab;

  /// No description provided for @hijriMonthShaban.
  ///
  /// In fr, this message translates to:
  /// **'Sha\'ban'**
  String get hijriMonthShaban;

  /// No description provided for @hijriMonthRamadan.
  ///
  /// In fr, this message translates to:
  /// **'Ramadan'**
  String get hijriMonthRamadan;

  /// No description provided for @hijriMonthShawwal.
  ///
  /// In fr, this message translates to:
  /// **'Shawwal'**
  String get hijriMonthShawwal;

  /// No description provided for @hijriMonthDhuAlQidah.
  ///
  /// In fr, this message translates to:
  /// **'Dhu al-Qi\'dah'**
  String get hijriMonthDhuAlQidah;

  /// No description provided for @hijriMonthDhuAlHijjah.
  ///
  /// In fr, this message translates to:
  /// **'Dhu al-Hijjah'**
  String get hijriMonthDhuAlHijjah;

  /// No description provided for @gregorianMonthJanuary.
  ///
  /// In fr, this message translates to:
  /// **'janvier'**
  String get gregorianMonthJanuary;

  /// No description provided for @gregorianMonthFebruary.
  ///
  /// In fr, this message translates to:
  /// **'février'**
  String get gregorianMonthFebruary;

  /// No description provided for @gregorianMonthMarch.
  ///
  /// In fr, this message translates to:
  /// **'mars'**
  String get gregorianMonthMarch;

  /// No description provided for @gregorianMonthApril.
  ///
  /// In fr, this message translates to:
  /// **'avril'**
  String get gregorianMonthApril;

  /// No description provided for @gregorianMonthMay.
  ///
  /// In fr, this message translates to:
  /// **'mai'**
  String get gregorianMonthMay;

  /// No description provided for @gregorianMonthJune.
  ///
  /// In fr, this message translates to:
  /// **'juin'**
  String get gregorianMonthJune;

  /// No description provided for @gregorianMonthJuly.
  ///
  /// In fr, this message translates to:
  /// **'juillet'**
  String get gregorianMonthJuly;

  /// No description provided for @gregorianMonthAugust.
  ///
  /// In fr, this message translates to:
  /// **'août'**
  String get gregorianMonthAugust;

  /// No description provided for @gregorianMonthSeptember.
  ///
  /// In fr, this message translates to:
  /// **'septembre'**
  String get gregorianMonthSeptember;

  /// No description provided for @gregorianMonthOctober.
  ///
  /// In fr, this message translates to:
  /// **'octobre'**
  String get gregorianMonthOctober;

  /// No description provided for @gregorianMonthNovember.
  ///
  /// In fr, this message translates to:
  /// **'novembre'**
  String get gregorianMonthNovember;

  /// No description provided for @gregorianMonthDecember.
  ///
  /// In fr, this message translates to:
  /// **'décembre'**
  String get gregorianMonthDecember;

  /// No description provided for @monthOfHijri.
  ///
  /// In fr, this message translates to:
  /// **'Mois de {month}'**
  String monthOfHijri(String month);

  /// No description provided for @monthOfGregorian.
  ///
  /// In fr, this message translates to:
  /// **'Mois de {month}'**
  String monthOfGregorian(String month);

  /// No description provided for @homePrayerPill.
  ///
  /// In fr, this message translates to:
  /// **'{prayerName} · {timeRemaining}'**
  String homePrayerPill(String prayerName, String timeRemaining);

  /// No description provided for @homeNextPrayerSemantic.
  ///
  /// In fr, this message translates to:
  /// **'Prochaine prière : {prayerName} dans {timeRemaining}'**
  String homeNextPrayerSemantic(String prayerName, String timeRemaining);

  /// No description provided for @prayerFajr.
  ///
  /// In fr, this message translates to:
  /// **'Fajr'**
  String get prayerFajr;

  /// No description provided for @prayerDhuhr.
  ///
  /// In fr, this message translates to:
  /// **'Dhuhr'**
  String get prayerDhuhr;

  /// No description provided for @prayerAsr.
  ///
  /// In fr, this message translates to:
  /// **'Asr'**
  String get prayerAsr;

  /// No description provided for @prayerMaghrib.
  ///
  /// In fr, this message translates to:
  /// **'Maghrib'**
  String get prayerMaghrib;

  /// No description provided for @prayerIsha.
  ///
  /// In fr, this message translates to:
  /// **'Isha'**
  String get prayerIsha;

  /// No description provided for @timeIn.
  ///
  /// In fr, this message translates to:
  /// **'dans {duration}'**
  String timeIn(String duration);

  /// No description provided for @courseLevelBeginner.
  ///
  /// In fr, this message translates to:
  /// **'Débutant'**
  String get courseLevelBeginner;

  /// No description provided for @courseLevelIntermediate.
  ///
  /// In fr, this message translates to:
  /// **'Intermédiaire'**
  String get courseLevelIntermediate;

  /// No description provided for @courseLevelAdvanced.
  ///
  /// In fr, this message translates to:
  /// **'Avancé'**
  String get courseLevelAdvanced;

  /// No description provided for @courseCategoryTajweed.
  ///
  /// In fr, this message translates to:
  /// **'Tajweed'**
  String get courseCategoryTajweed;

  /// No description provided for @courseCategoryTafsir.
  ///
  /// In fr, this message translates to:
  /// **'Tafsir'**
  String get courseCategoryTafsir;

  /// No description provided for @courseCategoryFiqh.
  ///
  /// In fr, this message translates to:
  /// **'Fiqh'**
  String get courseCategoryFiqh;

  /// No description provided for @courseCategorySira.
  ///
  /// In fr, this message translates to:
  /// **'Sîra'**
  String get courseCategorySira;

  /// No description provided for @courseCategoryAqida.
  ///
  /// In fr, this message translates to:
  /// **'Aqida'**
  String get courseCategoryAqida;

  /// No description provided for @courseCategoryArabic.
  ///
  /// In fr, this message translates to:
  /// **'Arabe'**
  String get courseCategoryArabic;

  /// No description provided for @courseCategoryMemorization.
  ///
  /// In fr, this message translates to:
  /// **'Mémorisation'**
  String get courseCategoryMemorization;

  /// No description provided for @courseCategorySpirituality.
  ///
  /// In fr, this message translates to:
  /// **'Spiritualité'**
  String get courseCategorySpirituality;

  /// No description provided for @courseCategoryOther.
  ///
  /// In fr, this message translates to:
  /// **'Autre'**
  String get courseCategoryOther;

  /// No description provided for @homeRamadanPillFr.
  ///
  /// In fr, this message translates to:
  /// **'Ramadan · Jour {day} sur 30'**
  String homeRamadanPillFr(int day);

  /// No description provided for @homeRamadanPillEn.
  ///
  /// In fr, this message translates to:
  /// **'Ramadan · Day {day} of 30'**
  String homeRamadanPillEn(int day);

  /// No description provided for @homeRamadanPillAr.
  ///
  /// In fr, this message translates to:
  /// **'رمضان · اليوم {day} من 30'**
  String homeRamadanPillAr(int day);

  /// No description provided for @notificationsTitle.
  ///
  /// In fr, this message translates to:
  /// **'Notifications'**
  String get notificationsTitle;

  /// No description provided for @notificationsEmptyTitle.
  ///
  /// In fr, this message translates to:
  /// **'Aucune notification'**
  String get notificationsEmptyTitle;

  /// No description provided for @notificationsEmptySubtitle.
  ///
  /// In fr, this message translates to:
  /// **'Vous êtes à jour'**
  String get notificationsEmptySubtitle;

  /// No description provided for @notificationsSettingsTitle.
  ///
  /// In fr, this message translates to:
  /// **'Paramètres des notifications'**
  String get notificationsSettingsTitle;

  /// No description provided for @notificationsEnableReadingReminders.
  ///
  /// In fr, this message translates to:
  /// **'Activer les rappels de lecture'**
  String get notificationsEnableReadingReminders;

  /// No description provided for @notificationsReceiveHizbReminders.
  ///
  /// In fr, this message translates to:
  /// **'Recevoir des rappels pour vos Hizb'**
  String get notificationsReceiveHizbReminders;

  /// No description provided for @notificationsGroupNotifications.
  ///
  /// In fr, this message translates to:
  /// **'Notifications de groupe'**
  String get notificationsGroupNotifications;

  /// No description provided for @notificationsWorkshopReminders.
  ///
  /// In fr, this message translates to:
  /// **'Rappels d\'ateliers'**
  String get notificationsWorkshopReminders;

  /// No description provided for @notificationsMarkAsRead.
  ///
  /// In fr, this message translates to:
  /// **'Marquer comme lu'**
  String get notificationsMarkAsRead;

  /// No description provided for @notificationsDelete.
  ///
  /// In fr, this message translates to:
  /// **'Supprimer'**
  String get notificationsDelete;

  /// No description provided for @notificationsDemoReadingTime.
  ///
  /// In fr, this message translates to:
  /// **'C\'est l\'heure de lire'**
  String get notificationsDemoReadingTime;

  /// No description provided for @notificationsDemoReadingTimeBody.
  ///
  /// In fr, this message translates to:
  /// **'N\'oubliez pas de compléter votre Hizb du jour'**
  String get notificationsDemoReadingTimeBody;

  /// No description provided for @notificationsDemoKhatmaReminder.
  ///
  /// In fr, this message translates to:
  /// **'Rappel Khatma'**
  String get notificationsDemoKhatmaReminder;

  /// No description provided for @notificationsDemoKhatmaBody.
  ///
  /// In fr, this message translates to:
  /// **'Votre Khatma de groupe attend votre participation'**
  String get notificationsDemoKhatmaBody;

  /// No description provided for @notificationsDemoWorkshop.
  ///
  /// In fr, this message translates to:
  /// **'Atelier de formation'**
  String get notificationsDemoWorkshop;

  /// No description provided for @notificationsDemoWorkshopBody.
  ///
  /// In fr, this message translates to:
  /// **'Nouvelle session disponible la semaine prochaine'**
  String get notificationsDemoWorkshopBody;

  /// No description provided for @notificationsTimeHoursAgo.
  ///
  /// In fr, this message translates to:
  /// **'Il y a {hours} heures'**
  String notificationsTimeHoursAgo(int hours);

  /// No description provided for @notificationsTimeYesterday.
  ///
  /// In fr, this message translates to:
  /// **'Hier'**
  String get notificationsTimeYesterday;

  /// No description provided for @notificationsTimeDaysAgo.
  ///
  /// In fr, this message translates to:
  /// **'Il y a {days} jours'**
  String notificationsTimeDaysAgo(int days);

  /// No description provided for @wirdTodayObjective.
  ///
  /// In fr, this message translates to:
  /// **'Objectif aujourd\'hui'**
  String get wirdTodayObjective;

  /// No description provided for @wirdPlusQuarterNext.
  ///
  /// In fr, this message translates to:
  /// **'Puis {quarters} quart du Hizb suivant'**
  String wirdPlusQuarterNext(int quarters);

  /// No description provided for @wirdPlusQuartersNext.
  ///
  /// In fr, this message translates to:
  /// **'Puis {quarters} quarts du Hizb suivant'**
  String wirdPlusQuartersNext(int quarters);

  /// No description provided for @wirdMonthlyProgress.
  ///
  /// In fr, this message translates to:
  /// **'Progression'**
  String get wirdMonthlyProgress;

  /// No description provided for @wirdHizbCompleted.
  ///
  /// In fr, this message translates to:
  /// **'{count} Hizb terminés'**
  String wirdHizbCompleted(int count);

  /// No description provided for @wirdInProgressFirstHizb.
  ///
  /// In fr, this message translates to:
  /// **'En cours du 1er Hizb'**
  String get wirdInProgressFirstHizb;

  /// No description provided for @wirdDaysRemaining.
  ///
  /// In fr, this message translates to:
  /// **'{days} jours restants'**
  String wirdDaysRemaining(int days);

  /// No description provided for @wirdPersonalKhatma.
  ///
  /// In fr, this message translates to:
  /// **'Ma Khatma personnelle'**
  String get wirdPersonalKhatma;

  /// No description provided for @wirdHizbUnit.
  ///
  /// In fr, this message translates to:
  /// **'Hizb'**
  String get wirdHizbUnit;

  /// No description provided for @wirdHizbOver.
  ///
  /// In fr, this message translates to:
  /// **'{current} / {total}'**
  String wirdHizbOver(int current, int total);

  /// No description provided for @wirdHizbCompleted_one.
  ///
  /// In fr, this message translates to:
  /// **'1 Hizb terminé'**
  String get wirdHizbCompleted_one;

  /// No description provided for @wirdHizbCompleted_other.
  ///
  /// In fr, this message translates to:
  /// **'{count} Hizb terminés'**
  String wirdHizbCompleted_other(int count);

  /// No description provided for @wirdNextHizbInProgress.
  ///
  /// In fr, this message translates to:
  /// **'Hizb suivant en cours'**
  String get wirdNextHizbInProgress;

  /// No description provided for @wirdKhatmaInProgress.
  ///
  /// In fr, this message translates to:
  /// **'Khatma en cours'**
  String get wirdKhatmaInProgress;

  /// No description provided for @wirdPercentOfKhatma.
  ///
  /// In fr, this message translates to:
  /// **'{percent}% de ma Khatma'**
  String wirdPercentOfKhatma(int percent);

  /// No description provided for @wirdHizbCompletedOutOf.
  ///
  /// In fr, this message translates to:
  /// **'{completed} Hizb terminé sur {total}'**
  String wirdHizbCompletedOutOf(int completed, int total);

  /// No description provided for @wirdHizbCompletedOutOf_other.
  ///
  /// In fr, this message translates to:
  /// **'{completed} Hizb terminés sur {total}'**
  String wirdHizbCompletedOutOf_other(int completed, int total);

  /// No description provided for @wirdOfMyKhatma.
  ///
  /// In fr, this message translates to:
  /// **'de ma Khatma'**
  String get wirdOfMyKhatma;

  /// No description provided for @inviteFamilyFriends.
  ///
  /// In fr, this message translates to:
  /// **'Invitez votre famille et vos amis'**
  String get inviteFamilyFriends;

  /// No description provided for @createCollaborativeKhatma.
  ///
  /// In fr, this message translates to:
  /// **'Créer une Khatma collaborative'**
  String get createCollaborativeKhatma;

  /// No description provided for @khatmaExampleTitle.
  ///
  /// In fr, this message translates to:
  /// **'Ex: Khatma Ramadan 2025'**
  String get khatmaExampleTitle;

  /// No description provided for @describeObjectives.
  ///
  /// In fr, this message translates to:
  /// **'Décrivez vos objectifs...'**
  String get describeObjectives;

  /// No description provided for @myKhatma.
  ///
  /// In fr, this message translates to:
  /// **'Ma Khatma'**
  String get myKhatma;

  /// No description provided for @khatmaEmptyMessage.
  ///
  /// In fr, this message translates to:
  /// **'Créez une Khatma de groupe, invitez vos proches et répartissez les Hizb.'**
  String get khatmaEmptyMessage;

  /// No description provided for @quickActionMushafSubtitle.
  ///
  /// In fr, this message translates to:
  /// **'Reprendre ma lecture'**
  String get quickActionMushafSubtitle;

  /// No description provided for @quickActionKhatmaSubtitle.
  ///
  /// In fr, this message translates to:
  /// **'Mes Khatmat'**
  String get quickActionKhatmaSubtitle;

  /// No description provided for @quickActionFormationsTitle.
  ///
  /// In fr, this message translates to:
  /// **'Formations'**
  String get quickActionFormationsTitle;

  /// No description provided for @quickActionFormationsSubtitle.
  ///
  /// In fr, this message translates to:
  /// **'Mes formations'**
  String get quickActionFormationsSubtitle;

  /// No description provided for @quickActionNotificationsSubtitle.
  ///
  /// In fr, this message translates to:
  /// **'Gérer mes alertes'**
  String get quickActionNotificationsSubtitle;

  /// No description provided for @loginWelcome.
  ///
  /// In fr, this message translates to:
  /// **'Bienvenue'**
  String get loginWelcome;

  /// No description provided for @loginSubtitle.
  ///
  /// In fr, this message translates to:
  /// **'Connectez-vous pour poursuivre votre Khatma'**
  String get loginSubtitle;

  /// No description provided for @loginContinueOtherwise.
  ///
  /// In fr, this message translates to:
  /// **'Continuer autrement'**
  String get loginContinueOtherwise;

  /// No description provided for @loginDiscoverDemo.
  ///
  /// In fr, this message translates to:
  /// **'Découvrir en mode démo'**
  String get loginDiscoverDemo;

  /// No description provided for @loginFirebaseUnavailable.
  ///
  /// In fr, this message translates to:
  /// **'Firebase indisponible. Utilisez le mode démo ou relancez l\'app.'**
  String get loginFirebaseUnavailable;

  /// No description provided for @loginEmailRequired.
  ///
  /// In fr, this message translates to:
  /// **'Email requis'**
  String get loginEmailRequired;

  /// No description provided for @loginEmailInvalid.
  ///
  /// In fr, this message translates to:
  /// **'Email invalide'**
  String get loginEmailInvalid;

  /// No description provided for @loginPasswordRequired.
  ///
  /// In fr, this message translates to:
  /// **'Mot de passe requis'**
  String get loginPasswordRequired;

  /// No description provided for @loginUserNotFound.
  ///
  /// In fr, this message translates to:
  /// **'Aucun compte associé à cet email.'**
  String get loginUserNotFound;

  /// No description provided for @loginWrongPassword.
  ///
  /// In fr, this message translates to:
  /// **'Mot de passe incorrect.'**
  String get loginWrongPassword;

  /// No description provided for @loginInvalidEmail.
  ///
  /// In fr, this message translates to:
  /// **'Email invalide.'**
  String get loginInvalidEmail;

  /// No description provided for @loginErrorGeneric.
  ///
  /// In fr, this message translates to:
  /// **'Erreur: {error}'**
  String loginErrorGeneric(String error);

  /// No description provided for @khatmaCreationAuthRequired.
  ///
  /// In fr, this message translates to:
  /// **'Connexion requise pour créer une Khatma'**
  String get khatmaCreationAuthRequired;

  /// No description provided for @khatmaCreationPermissionDenied.
  ///
  /// In fr, this message translates to:
  /// **'Permission refusée. Vérifiez votre connexion.'**
  String get khatmaCreationPermissionDenied;

  /// No description provided for @khatmaCreationNetworkError.
  ///
  /// In fr, this message translates to:
  /// **'Erreur réseau. Vérifiez votre connexion internet.'**
  String get khatmaCreationNetworkError;

  /// No description provided for @khatmaCreationInitFailed.
  ///
  /// In fr, this message translates to:
  /// **'Échec d\'initialisation. Veuillez réessayer.'**
  String get khatmaCreationInitFailed;

  /// No description provided for @khatmaCreationUnknown.
  ///
  /// In fr, this message translates to:
  /// **'Erreur inattendue. Contactez le support si le problème persiste.'**
  String get khatmaCreationUnknown;

  /// No description provided for @khatmaCreationRetry.
  ///
  /// In fr, this message translates to:
  /// **'Réessayer'**
  String get khatmaCreationRetry;

  /// No description provided for @khatmaCreated.
  ///
  /// In fr, this message translates to:
  /// **'Khatma créée avec succès'**
  String get khatmaCreated;

  /// No description provided for @khatmaCreationFailed.
  ///
  /// In fr, this message translates to:
  /// **'Échec de création de la Khatma'**
  String get khatmaCreationFailed;

  /// No description provided for @khatmaCreationSubmitting.
  ///
  /// In fr, this message translates to:
  /// **'Création…'**
  String get khatmaCreationSubmitting;

  /// No description provided for @khatmaCreationInitializing.
  ///
  /// In fr, this message translates to:
  /// **'Initialisation des 60 Hizb…'**
  String get khatmaCreationInitializing;

  /// No description provided for @reserveThisHizb.
  ///
  /// In fr, this message translates to:
  /// **'Réserver ce Hizb'**
  String get reserveThisHizb;

  /// No description provided for @reserveForMe.
  ///
  /// In fr, this message translates to:
  /// **'Pour moi'**
  String get reserveForMe;

  /// No description provided for @reserveForSomeoneElse.
  ///
  /// In fr, this message translates to:
  /// **'Pour quelqu\'un d\'autre'**
  String get reserveForSomeoneElse;

  /// No description provided for @reserveForSomeoneElseHint.
  ///
  /// In fr, this message translates to:
  /// **'Personne hors de l\'app (prénom uniquement)'**
  String get reserveForSomeoneElseHint;

  /// No description provided for @personShortName.
  ///
  /// In fr, this message translates to:
  /// **'Prénom'**
  String get personShortName;

  /// No description provided for @reservedForPerson.
  ///
  /// In fr, this message translates to:
  /// **'Réservé pour {name}'**
  String reservedForPerson(String name);

  /// No description provided for @reservedByPerson.
  ///
  /// In fr, this message translates to:
  /// **'par {name}'**
  String reservedByPerson(String name);

  /// No description provided for @takeNextAvailableHizb.
  ///
  /// In fr, this message translates to:
  /// **'Prendre le prochain Hizb disponible'**
  String get takeNextAvailableHizb;

  /// No description provided for @collectiveHizbSummary.
  ///
  /// In fr, this message translates to:
  /// **'{completed} terminés · {reserved} réservés · {available} disponibles'**
  String collectiveHizbSummary(int completed, int reserved, int available);

  /// No description provided for @noHizbAvailable.
  ///
  /// In fr, this message translates to:
  /// **'Aucun Hizb disponible'**
  String get noHizbAvailable;

  /// No description provided for @createdBy.
  ///
  /// In fr, this message translates to:
  /// **'Créée par'**
  String get createdBy;

  /// No description provided for @createdOn.
  ///
  /// In fr, this message translates to:
  /// **'Créée le'**
  String get createdOn;
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
