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
  String get wird => 'Wird';

  @override
  String get formations => 'Training';

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
  String get viewMyKhatmat => 'View my Khatmat';

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
  String get participantSingular => '1 participant';

  @override
  String participantPlural(int count) {
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

  @override
  String get khatmaRouteNotFoundTitle => 'Khatma not found';

  @override
  String get khatmaRouteNotFoundMessage =>
      'This Khatma no longer exists or the link is invalid.';

  @override
  String get khatmaRouteDemoUnavailableTitle => 'Khatma unavailable in demo';

  @override
  String get khatmaRouteDemoUnavailableMessage =>
      'This Khatma isn\'t available in demo mode. Go back to the list or create a local Khatma.';

  @override
  String get khatmaRouteAccessDeniedTitle => 'Access denied';

  @override
  String get khatmaRouteAccessDeniedMessage =>
      'You don\'t have access to this Khatma.';

  @override
  String get khatmaRouteNetworkErrorTitle => 'Network error';

  @override
  String get khatmaRouteNetworkErrorMessage =>
      'Couldn\'t load this Khatma. Check your connection.';

  @override
  String get khatmaRouteLoadErrorTitle => 'Couldn\'t load this Khatma';

  @override
  String get khatmaRouteLoadErrorMessage =>
      'Something went wrong. Please try again.';

  @override
  String get khatmaRouteLoading => 'Loading Khatma...';

  @override
  String get myKhatmas => 'My Khatmas';

  @override
  String get joinWithCode => 'Join with a code';

  @override
  String get back => 'Back';

  @override
  String get wirdCompleteFinalPage => 'Complete the Quran';

  @override
  String get wirdFinalPageCompleted =>
      'Alhamdulillah! You have completed the Quran.';

  @override
  String get wirdMyWird => 'My Wird';

  @override
  String get wirdPlanTooltip => 'Plan';

  @override
  String get wirdConfigureTooltip => 'Configure';

  @override
  String get wirdDailySectionTitle => 'Today\'s reading';

  @override
  String wirdObjectiveLabel(String target) {
    return 'Goal: $target';
  }

  @override
  String wirdDailyCompleted(String target) {
    return '$target • Today\'s Wird completed';
  }

  @override
  String get wirdRemainingOneRub => 'You have 1 Rub\' left';

  @override
  String wirdRemainingManyRubs(int count) {
    return 'You have $count Rub\' left';
  }

  @override
  String get wirdContinueSectionTitle => 'Continue reading';

  @override
  String get wirdContinueSubtitle => 'Pick up where you left off';

  @override
  String wirdHizbNumber(int number) {
    return 'Hizb $number';
  }

  @override
  String wirdSurahAyah(int surah, int ayah) {
    return 'Surah $surah • Ayah $ayah';
  }

  @override
  String wirdPageNumber(int page) {
    return 'Page $page';
  }

  @override
  String wirdReadingMushaf(String mushaf) {
    return 'Reading: $mushaf';
  }

  @override
  String get wirdNoReadingInProgress => 'No reading in progress';

  @override
  String get wirdResumeReading => 'Resume reading';

  @override
  String get wirdStartReading => 'Start reading';

  @override
  String get wirdDailyGoalTitle => 'Daily goal';

  @override
  String get wirdDailyGoalSubtitle => 'Choose your daily reading goal';

  @override
  String get wirdLoadError => 'Couldn\'t load your Wird';

  @override
  String get personalKhatmaTitle => 'MY PERSONAL KHATMA';

  @override
  String get personalKhatmaProgressionLabel => 'Progress';

  @override
  String get personalKhatmaDaysRemainingLabel => 'Days remaining';

  @override
  String personalKhatmaDaysRemainingValue(int days, String daysLabel) {
    return '$days $daysLabel';
  }

  @override
  String get personalKhatmaDaysUnit => 'days';

  @override
  String get personalKhatmaDayUnit => 'day';

  @override
  String get personalKhatmaScheduled => 'Scheduled';

  @override
  String get personalKhatmaCompleted => 'Khatma completed — Al-hamdu lillāh';

  @override
  String get personalKhatmaCreateNew => 'Create a new plan';

  @override
  String personalKhatmaRemainingToRead(String remaining) {
    return '$remaining remaining to read';
  }

  @override
  String get personalKhatmaContinueWithoutDeadline =>
      'You can continue reading without a deadline';

  @override
  String get personalKhatmaManagePlan => 'Manage my plan';

  @override
  String get readingPlanTitle => 'Reading plan';

  @override
  String get readingPlanFreeGoalTitle => 'Free daily goal';

  @override
  String get readingPlanFreeGoalSubtitle => 'Daily reading without deadline';

  @override
  String get readingPlanHijriMonthTitle => '1 Khatma / Hijri month';

  @override
  String get readingPlanHijriMonthSubtitle =>
      'Finish the Quran in 1 lunar month';

  @override
  String get readingPlanGregorianMonthTitle => '1 Khatma / Gregorian month';

  @override
  String get readingPlanGregorianMonthSubtitle => 'Finish the Quran in 1 month';

  @override
  String get readingPlanStartingLabel => 'Starting';

  @override
  String get readingPlanStartNowLabel => 'Start now';

  @override
  String get readingPlanStartNextLabel => 'Start next month';

  @override
  String readingPlanStartNowHijriDescription(String month) {
    return 'Rest of $month';
  }

  @override
  String readingPlanStartNowGregorianDescription(int days) {
    return 'Rest of month ($days days)';
  }

  @override
  String get readingPlanActivateFreeGoal => 'Activate free goal';

  @override
  String get readingPlanCreatePlan => 'Create plan';

  @override
  String get readingPlanPreviewTitle => 'Preview';

  @override
  String get readingPlanPreviewPeriod => 'Period';

  @override
  String get readingPlanPreviewReadingDays => 'Reading days';

  @override
  String readingPlanPreviewReadingDaysValue(int days) {
    return '$days days';
  }

  @override
  String get readingPlanPreviewPace => 'Recommended pace';

  @override
  String readingPlanError(String error) {
    return 'Error: $error';
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
  String get gregorianMonthJanuary => 'January';

  @override
  String get gregorianMonthFebruary => 'February';

  @override
  String get gregorianMonthMarch => 'March';

  @override
  String get gregorianMonthApril => 'April';

  @override
  String get gregorianMonthMay => 'May';

  @override
  String get gregorianMonthJune => 'June';

  @override
  String get gregorianMonthJuly => 'July';

  @override
  String get gregorianMonthAugust => 'August';

  @override
  String get gregorianMonthSeptember => 'September';

  @override
  String get gregorianMonthOctober => 'October';

  @override
  String get gregorianMonthNovember => 'November';

  @override
  String get gregorianMonthDecember => 'December';

  @override
  String monthOfHijri(String month) {
    return 'Month of $month';
  }

  @override
  String monthOfGregorian(String month) {
    return 'Month of $month';
  }

  @override
  String homePrayerPill(String prayerName, String timeRemaining) {
    return '$prayerName · $timeRemaining';
  }

  @override
  String homeNextPrayerSemantic(String prayerName, String timeRemaining) {
    return 'Next prayer: $prayerName in $timeRemaining';
  }

  @override
  String get prayerFajr => 'Fajr';

  @override
  String get prayerDhuhr => 'Dhuhr';

  @override
  String get prayerAsr => 'Asr';

  @override
  String get prayerMaghrib => 'Maghrib';

  @override
  String get prayerIsha => 'Isha';

  @override
  String timeIn(String duration) {
    return 'in $duration';
  }

  @override
  String get courseLevelBeginner => 'Beginner';

  @override
  String get courseLevelIntermediate => 'Intermediate';

  @override
  String get courseLevelAdvanced => 'Advanced';

  @override
  String get courseCategoryTajweed => 'Tajweed';

  @override
  String get courseCategoryTafsir => 'Tafsir';

  @override
  String get courseCategoryFiqh => 'Fiqh';

  @override
  String get courseCategorySira => 'Sira';

  @override
  String get courseCategoryAqida => 'Aqida';

  @override
  String get courseCategoryArabic => 'Arabic';

  @override
  String get courseCategoryMemorization => 'Memorization';

  @override
  String get courseCategorySpirituality => 'Spirituality';

  @override
  String get courseCategoryOther => 'Other';

  @override
  String get continueLearning => 'Continue Learning';

  @override
  String get all => 'All';

  @override
  String get noFormationsAvailable => 'No courses available at the moment';

  @override
  String get errorLoadingFormations => 'Error loading courses';

  @override
  String homeRamadanPillFr(int day) {
    return 'Ramadan · Day $day of 30';
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
  String get notificationsEmptyTitle => 'No notifications';

  @override
  String get notificationsEmptySubtitle => 'You\'re all caught up';

  @override
  String get notificationsSettingsTitle => 'Notification settings';

  @override
  String get notificationsEnableReadingReminders => 'Enable reading reminders';

  @override
  String get notificationsReceiveHizbReminders =>
      'Receive reminders for your Hizb';

  @override
  String get notificationsGroupNotifications => 'Group notifications';

  @override
  String get notificationsWorkshopReminders => 'Workshop reminders';

  @override
  String get notificationsMarkAsRead => 'Mark as read';

  @override
  String get notificationsDelete => 'Delete';

  @override
  String get notificationsDemoReadingTime => 'Time to read';

  @override
  String get notificationsDemoReadingTimeBody =>
      'Don\'t forget to complete your daily Hizb';

  @override
  String get notificationsDemoKhatmaReminder => 'Khatma Reminder';

  @override
  String get notificationsDemoKhatmaBody =>
      'Your group Khatma is waiting for you';

  @override
  String get notificationsDemoWorkshop => 'Training workshop';

  @override
  String get notificationsDemoWorkshopBody => 'New session available next week';

  @override
  String notificationsTimeHoursAgo(int hours) {
    return '$hours hours ago';
  }

  @override
  String get notificationsTimeYesterday => 'Yesterday';

  @override
  String notificationsTimeDaysAgo(int days) {
    return '$days days ago';
  }

  @override
  String get wirdTodayObjective => 'Today\'s objective';

  @override
  String wirdPlusQuarterNext(int quarters) {
    return 'Plus $quarters quarter of the next Hizb';
  }

  @override
  String wirdPlusQuartersNext(int quarters) {
    return 'Plus $quarters quarters of the next Hizb';
  }

  @override
  String get wirdMonthlyProgress => 'Progress';

  @override
  String wirdHizbCompleted(int count) {
    return '$count Hizb completed';
  }

  @override
  String get wirdInProgressFirstHizb => 'In progress: 1st Hizb';

  @override
  String wirdDaysRemaining(int days) {
    return '$days days remaining';
  }

  @override
  String get wirdPersonalKhatma => 'My Personal Khatma';

  @override
  String get wirdHizbUnit => 'Hizb';

  @override
  String wirdHizbOver(int current, int total) {
    return '$current / $total';
  }

  @override
  String get wirdHizbCompleted_one => '1 Hizb completed';

  @override
  String wirdHizbCompleted_other(int count) {
    return '$count Hizb completed';
  }

  @override
  String get wirdNextHizbInProgress => 'Next Hizb in progress';

  @override
  String get wirdKhatmaInProgress => 'Khatma in progress';

  @override
  String wirdPercentOfKhatma(int percent) {
    return '$percent% of my Khatma';
  }

  @override
  String wirdHizbCompletedOutOf(int completed, int total) {
    return '$completed Hizb completed out of $total';
  }

  @override
  String wirdHizbCompletedOutOf_other(int completed, int total) {
    return '$completed Hizb completed out of $total';
  }

  @override
  String get wirdOfMyKhatma => 'of my Khatma';

  @override
  String get inviteFamilyFriends => 'Invite your family and friends';

  @override
  String get createCollaborativeKhatma => 'Create a collaborative Khatma';

  @override
  String get khatmaExampleTitle => 'Ex: Ramadan Khatma 2025';

  @override
  String get describeObjectives => 'Describe your objectives...';

  @override
  String get myKhatma => 'My Khatma';

  @override
  String get khatmaEmptyMessage =>
      'Create a group Khatma, invite your loved ones and distribute the Hizb.';

  @override
  String get quickActionMushafSubtitle => 'Resume reading';

  @override
  String get quickActionKhatmaSubtitle => 'My Khatmat';

  @override
  String get quickActionFormationsTitle => 'Training';

  @override
  String get quickActionFormationsSubtitle => 'My courses';

  @override
  String get quickActionNotificationsSubtitle => 'Manage alerts';

  @override
  String get loginWelcome => 'Welcome';

  @override
  String get loginSubtitle => 'Sign in to continue your Khatma';

  @override
  String get loginContinueOtherwise => 'Continue otherwise';

  @override
  String get loginDiscoverDemo => 'Explore demo mode';

  @override
  String get loginFirebaseUnavailable =>
      'Service unavailable. Restart the app.';

  @override
  String get loginEmailRequired => 'Email required';

  @override
  String get loginEmailInvalid => 'Invalid email';

  @override
  String get loginPasswordRequired => 'Password required';

  @override
  String get loginUserNotFound => 'No account associated with this email.';

  @override
  String get loginWrongPassword => 'Incorrect password.';

  @override
  String get loginInvalidEmail => 'Invalid email.';

  @override
  String loginErrorGeneric(String error) {
    return 'Error: $error';
  }

  @override
  String get khatmaCreationAuthRequired => 'Login required to create a Khatma';

  @override
  String get khatmaCreationPermissionDenied =>
      'Permission denied. Check your connection.';

  @override
  String get khatmaCreationNetworkError =>
      'Network error. Check your internet connection.';

  @override
  String get khatmaCreationInitFailed =>
      'Initialization failed. Please try again.';

  @override
  String get khatmaCreationUnknown =>
      'Unexpected error. Contact support if the problem persists.';

  @override
  String get khatmaCreationRetry => 'Retry';

  @override
  String get khatmaCreated => 'Khatma created successfully';

  @override
  String get khatmaCreationFailed => 'Failed to create Khatma';

  @override
  String get khatmaCreationSubmitting => 'Creating…';

  @override
  String get khatmaCreationInitializing => 'Initializing 60 Hizb…';

  @override
  String get reserveThisHizb => 'Reserve this Hizb';

  @override
  String get reserveForMe => 'For me';

  @override
  String get reserveForSomeoneElse => 'For someone else';

  @override
  String get reserveForSomeoneElseHint =>
      'Someone outside the app (first name only)';

  @override
  String get personShortName => 'First name';

  @override
  String reservedForPerson(String name) {
    return 'Reserved for $name';
  }

  @override
  String reservedByPerson(String name) {
    return 'by $name';
  }

  @override
  String get takeNextAvailableHizb => 'Take the next available Hizb';

  @override
  String collectiveHizbSummary(int completed, int reserved, int available) {
    return '$completed completed · $reserved reserved · $available available';
  }

  @override
  String get noHizbAvailable => 'No Hizb available';

  @override
  String get createdBy => 'Created by';

  @override
  String get createdOn => 'Created on';

  @override
  String get pillarFoundationsPractice => 'Foundations & Practice';

  @override
  String get pillarQuranReading => 'Quran & Recitation';

  @override
  String get pillarProphetSeerahSunnah => 'Prophet ﷺ: Life & Teachings';

  @override
  String get pillarDailyLifeFrance => 'Daily Life in France';

  @override
  String get pillarCharacterEthics => 'Character & Ethics';

  @override
  String get pillarSpiritualityHeart => 'Spirituality & Heart';

  @override
  String get deliveryModeSelfPaced => 'Self-paced';

  @override
  String get deliveryModeCohort => 'Guided cohort';

  @override
  String get startLearningPath => 'Start';

  @override
  String get continueLearningPath => 'Continue';

  @override
  String get completedLearningPath => 'Completed';

  @override
  String get lessonSummary => 'Summary';

  @override
  String get lessonAction => 'Action to apply';

  @override
  String get lessonQuran => 'Quranic connection';

  @override
  String get markAsCompleted => 'Mark as completed';

  @override
  String get previousLesson => 'Previous';

  @override
  String get nextLesson => 'Next';

  @override
  String get programme => 'Curriculum';

  @override
  String lessonCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count lessons',
      one: '1 lesson',
      zero: 'No lessons',
    );
    return '$_temp0';
  }

  @override
  String moduleCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count modules',
      one: '1 module',
      zero: 'No modules',
    );
    return '$_temp0';
  }

  @override
  String progressPercent(int percent) {
    return '$percent% completed';
  }

  @override
  String get formationsSubtitle => 'Progress step by step in your learning';

  @override
  String get formationsHeroTagline => 'Learn. Understand. Practice.';

  @override
  String get formationsHeroSecondary =>
      'Structured learning paths to progress at your own pace.';

  @override
  String get resumeYourLearning => 'Resume your learning';

  @override
  String get myLearning => 'My learning';

  @override
  String get myLearningResumeSubtitle => 'Pick up where you left off';

  @override
  String get myLearningEmptyTitle => 'Start your first learning path';

  @override
  String get myLearningEmptyBody =>
      'Choose a course and track your progress here.';

  @override
  String get discoverFormations => 'Discover courses';

  @override
  String get myLearningAllCompletedTitle =>
      'Well done, you\'ve completed your paths';

  @override
  String get myLearningAllCompletedBody =>
      'Explore more courses to keep learning.';

  @override
  String get savedForLater => 'Saved for later';

  @override
  String get savedForLaterEmptyTitle => 'You haven\'t saved anything';

  @override
  String get savedForLaterEmptyBody =>
      'Save courses or lessons to find them easily.';

  @override
  String get saveForLater => 'Save for later';

  @override
  String get saved => 'Saved';

  @override
  String get unsave => 'Remove';

  @override
  String get searchFormations => 'Search for a course or lesson';

  @override
  String searchNoResults(String query) {
    return 'No results for \"$query\"';
  }

  @override
  String get searchResultTypeCourse => 'COURSE';

  @override
  String get searchResultTypeModule => 'MODULE';

  @override
  String get searchResultTypeLesson => 'LESSON';

  @override
  String get exploreByTheme => 'Explore by theme';

  @override
  String get formationsSignInRequiredTitle => 'Sign-in required';

  @override
  String get formationsSignInRequiredBody => 'Sign in to access the courses.';

  @override
  String get formationsErrorPermissionDenied =>
      'Access to course content was denied.';

  @override
  String get formationsErrorUnavailable =>
      'Service temporarily unavailable. Please try again shortly.';

  @override
  String formationsCourseModulesEmpty(String courseTitle) {
    return 'No published module for \"$courseTitle\" yet.';
  }

  @override
  String get featuredPaths => 'Featured paths';

  @override
  String get liveSection => 'LIVE';

  @override
  String get liveSessionsCardTitle => 'ANIS Live';

  @override
  String get liveSessionsDescription => 'Live meetings with verified speakers.';

  @override
  String get liveSessionsSecondary =>
      'Share, ask your questions and deepen your knowledge.';

  @override
  String get questionsSection => 'Questions & exchanges';

  @override
  String get allFormations => 'All formations';

  @override
  String get formationsAvailable => 'Available Formations';

  @override
  String get liveSessionsTitle => 'Live Sessions';

  @override
  String get questionsTitle => 'Private & Public Questions';

  @override
  String get questionsDescription =>
      'Ask a question in complete confidentiality or consult published answers.';

  @override
  String get privateQuestion => 'Private question';

  @override
  String get publicAnswers => 'Public answers';

  @override
  String get comingSoon => 'Coming Soon';

  @override
  String get moduleContentComingSoon => 'Content coming soon';

  @override
  String get upcoming => 'Upcoming';

  @override
  String get authWelcomeTitle => 'Welcome to ANIS';

  @override
  String get authWelcomeSubtitle =>
      'Deepen your practice and knowledge of Islam';

  @override
  String get authContinueWithGoogle => 'Continue with Google';

  @override
  String get authContinueWithApple => 'Continue with Apple';

  @override
  String get authContinueWithEmail => 'Continue with Email';

  @override
  String get authOr => 'or';

  @override
  String authErrorAccountCollision(String email) {
    return 'This account $email already exists with another sign-in method. Please sign in with that method.';
  }

  @override
  String get authErrorNetwork =>
      'Connection error. Please check your internet connection.';

  @override
  String get authErrorProvider => 'Authentication failed. Please try again.';

  @override
  String get authErrorConfiguration => 'Authentication service unavailable.';
}
