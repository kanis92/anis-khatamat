// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'ANIS Khatamat';

  @override
  String get login => 'Login';

  @override
  String get register => 'Create account';

  @override
  String get email => 'Email';

  @override
  String get password => 'Password';

  @override
  String get settings => 'Settings';

  @override
  String get home => 'Home';

  @override
  String get khatma => 'Khatma';

  @override
  String get notifications => 'Notifications';

  @override
  String get training => 'Training';

  @override
  String get achievements => 'Achievements';

  @override
  String get createKhatma => 'Create Khatma';

  @override
  String get createAccount => 'Create account';

  @override
  String get changePassword => 'Change password';

  @override
  String get manageNotifications => 'Manage notifications';

  @override
  String get changeLanguage => 'Change language';

  @override
  String get privacyPolicy => 'Privacy policy';

  @override
  String get darkMode => 'Dark mode';

  @override
  String get logout => 'Logout';

  @override
  String get welcomeGreeting => 'Assalamu alaykum';

  @override
  String get welcomeSubtitle => 'Welcome to your reading space';

  @override
  String get quickActions => 'Quick actions';

  @override
  String get progression => 'Progression';

  @override
  String get hizbCompleted => 'Hizb completed';

  @override
  String get upcomingReadings => 'Upcoming readings';

  @override
  String get noReadingsScheduled => 'No readings scheduled';

  @override
  String get createKhatmaToStart =>
      'Create a Khatma to start tracking your progress.';

  @override
  String khatmatInProgress(int count) {
    return '$count Khatma(s) in progress';
  }

  @override
  String get continueReading => 'Continue reading to advance in your Khatmat.';

  @override
  String get mushaf => 'Mushaf';

  @override
  String get demoMode => 'Demo mode (test without login)';

  @override
  String get loginButton => 'Log in';

  @override
  String get individual => 'Individual';

  @override
  String get group => 'Group';

  @override
  String get chooseKhatmaType => 'Choose Khatma type';

  @override
  String get createNewKhatma => 'Create a new Khatma';

  @override
  String get myKhatmat => 'Your Khatmat in progress';

  @override
  String get noKhatma => 'No Khatma in progress';

  @override
  String get readingOptions => 'Reading options';

  @override
  String get mushafHafs => 'Mushaf Hafs';

  @override
  String get mushafHafsDesc => 'Most widespread version';

  @override
  String get mushafWarsh => 'Mushaf Warsh';

  @override
  String get mushafWarshDesc => 'North African version';

  @override
  String get chooseMushafType => 'Choose Mushaf type';

  @override
  String get mushafWomen => 'Women\'s Mushaf';

  @override
  String get mushafWomenDesc => 'Hafs Mushaf — elegant rose theme';

  @override
  String get openMushaf => 'Open Mushaf';

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
    return 'Hizb $number from your Khatma';
  }

  @override
  String mushafKhatmaHizbLeft(String number) {
    return 'You left Hizb $number — go back';
  }

  @override
  String get mushafBookmarkHere => 'Bookmark here';

  @override
  String get mushafBookmarkHereDesc => 'Bookmark to continue later';

  @override
  String get mushafUnbookmark => 'Remove bookmark';

  @override
  String get completionAlhamdulillah => 'Alhamdulillah';

  @override
  String get completionAccomplished => 'This Khatma is complete.';

  @override
  String get completionDua =>
      'May Allah accept this recitation and everyone\'s efforts.';

  @override
  String get completionHeaderSubtitle => 'Your Khatma is complete.';

  @override
  String completionHizbAccomplished(int count) {
    return '$count Hizb completed';
  }

  @override
  String completionParticipantsCount(int count) {
    return '$count participants';
  }

  @override
  String completionDurationDays(int days) {
    return 'Completed in $days days';
  }

  @override
  String get completionDurationOneDay => 'Completed in 1 day';

  @override
  String completionClosedOn(String date) {
    return 'Closed on $date';
  }

  @override
  String completionCollectiveMessage(int count) {
    return '$count people took part in this Khatma.';
  }

  @override
  String completionWithParticipants(String names) {
    return 'With $names';
  }

  @override
  String get completionStartNew => 'Start a new Khatma';

  @override
  String get completionShare => 'Share';

  @override
  String get completionBackToMyKhatmas => 'Back to my Khatmas';

  @override
  String completionShareMessage(String title) {
    return 'Alhamdulillah, our Khatma \"$title\" has been completed on Anis. May Allah accept everyone\'s efforts.';
  }

  @override
  String get completionViewClosure => 'View completion';

  @override
  String get completionFinishedBadge => 'Completed';

  @override
  String get completionSee => 'View';

  @override
  String completionProgressFraction(int completed, int total) {
    return '$completed/$total';
  }

  @override
  String get khatmaTitle => 'Khatma title';

  @override
  String get objectives => 'Objectives';

  @override
  String get inviteMembers => 'Invite members';

  @override
  String get memberEmail => 'Member email';

  @override
  String get nextDistribution => 'Next → Hizb distribution';

  @override
  String get hizbDistribution => 'Hizb distribution';

  @override
  String hizbAssigned(int count, int total) {
    return '$count/$total Hizb assigned';
  }

  @override
  String get autoDistribution => 'Auto';

  @override
  String get manualDistribution => 'Manual';

  @override
  String get confirmDistribution => 'Confirm distribution';

  @override
  String get sendReminder => 'Send reminder';

  @override
  String get listOf60Hizb => 'List of 60 Hizb';

  @override
  String get unassigned => 'Unassigned';

  @override
  String get assignedTo => 'Assigned to';

  @override
  String assignedToLabel(String name) {
    return 'Assigned to: $name';
  }

  @override
  String get khatmaCompleted => 'Khatma completed! ماشاء الله';

  @override
  String get account => 'Account';

  @override
  String get preferences => 'Preferences';

  @override
  String get legal => 'Legal';

  @override
  String get user => 'User';

  @override
  String get share => 'Share';

  @override
  String get shareAchievements => 'Share';

  @override
  String get shareAchievementsDesc =>
      'Share your progress on WhatsApp or other apps.';

  @override
  String get shareWhatsApp => 'Share (WhatsApp, etc.)';

  @override
  String get shareYourProgress => 'Share my achievements';

  @override
  String get language => 'Language';

  @override
  String get french => 'Français';

  @override
  String get english => 'English';

  @override
  String get arabic => 'العربية';

  @override
  String get system => 'System';

  @override
  String get send => 'Send';

  @override
  String get cancel => 'Cancel';

  @override
  String get featureComingSoon => 'Feature coming soon';

  @override
  String get urlNotAvailable => 'URL not available';

  @override
  String get resetEmailMessage => 'A reset email will be sent to you.';

  @override
  String get bookmarks => 'Bookmarks';

  @override
  String get completed => 'Completed';

  @override
  String get continueAction => 'Continue';

  @override
  String get groupKhatma => 'Group Khatma';

  @override
  String get guestBadge => 'Guest';

  @override
  String get homeCollectiveProgress => 'Collective progress';

  @override
  String get homeEmptyHint =>
      'Create a Khatma or join one to follow your progress.';

  @override
  String get homeEmptyTitle => 'Start your first Khatma';

  @override
  String get homeGoalToday => 'Today\'s goal';

  @override
  String homeHizbInProgress(String number) {
    return 'Hizb $number in progress';
  }

  @override
  String homeHizbReserved(String number) {
    return 'Hizb $number reserved';
  }

  @override
  String get homeLoadError => 'Couldn\'t load your Khatmas';

  @override
  String get homeLoadErrorHint => 'Check your connection, then try again.';

  @override
  String get homePersonalProgress => 'Your progress';

  @override
  String get inProgress => 'In progress';

  @override
  String get joinCollectiveKhatma => 'Join a collective Khatma';

  @override
  String get khatmaInProgress => 'Khatma in progress';

  @override
  String get lastActivity => 'Last activity';

  @override
  String get myTraining => 'My Training';

  @override
  String get nextPrayer => 'Next prayer';

  @override
  String get offlineNotice => 'Offline — your data will sync later';

  @override
  String get prayerTimes => 'Prayer times';

  @override
  String get readingGoal => 'Reading goal';

  @override
  String get readingGoalAchieved => 'Goal achieved!';

  @override
  String readingGoalProgress(int completed, int target) {
    return '$completed/$target Hizb';
  }

  @override
  String get resume => 'Resume';

  @override
  String get retry => 'Retry';

  @override
  String get seeAll => 'See all';

  @override
  String get statistics => 'Statistics';
}
