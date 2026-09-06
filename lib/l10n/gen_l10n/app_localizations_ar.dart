// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Arabic (`ar`).
class AppLocalizationsAr extends AppLocalizations {
  AppLocalizationsAr([String locale = 'ar']) : super(locale);

  @override
  String get appTitle => 'أنيس ختمات';

  @override
  String get login => 'تسجيل الدخول';

  @override
  String get register => 'إنشاء حساب';

  @override
  String get email => 'البريد الإلكتروني';

  @override
  String get password => 'كلمة المرور';

  @override
  String get settings => 'الإعدادات';

  @override
  String get home => 'الرئيسية';

  @override
  String get khatma => 'الختمة';

  @override
  String get notifications => 'الإشعارات';

  @override
  String get training => 'التدريب';

  @override
  String get wird => 'ورد';

  @override
  String get formations => 'التدريب';

  @override
  String get achievements => 'الإنجازات';

  @override
  String get createKhatma => 'إنشاء ختمة';

  @override
  String get createAccount => 'إنشاء حساب';

  @override
  String get changePassword => 'تغيير كلمة المرور';

  @override
  String get manageNotifications => 'إدارة الإشعارات';

  @override
  String get changeLanguage => 'تغيير اللغة';

  @override
  String get privacyPolicy => 'سياسة الخصوصية';

  @override
  String get darkMode => 'الوضع الداكن';

  @override
  String get logout => 'تسجيل الخروج';

  @override
  String get welcomeGreeting => 'السلام عليكم';

  @override
  String get welcomeSubtitle => 'مرحباً بك في مساحة القراءة';

  @override
  String get quickActions => 'الإجراءات السريعة';

  @override
  String get progression => 'التقدم';

  @override
  String get hizbCompleted => 'الأحزاب المكتملة';

  @override
  String get upcomingReadings => 'قراءات قادمة';

  @override
  String get noReadingsScheduled => 'لا توجد قراءات مجدولة';

  @override
  String get createKhatmaToStart => 'أنشئ ختمة لبدء تتبع تقدمك.';

  @override
  String khatmatInProgress(int count) {
    return '$count ختمة(ات) قيد التنفيذ';
  }

  @override
  String get continueReading => 'استمر في القراءة للتقدم في ختماتك.';

  @override
  String get mushaf => 'المصحف';

  @override
  String get demoMode => 'وضع التجربة (بدون تسجيل)';

  @override
  String get loginButton => 'تسجيل الدخول';

  @override
  String get individual => 'فردية';

  @override
  String get group => 'جماعية';

  @override
  String get chooseKhatmaType => 'اختر نوع الختمة';

  @override
  String get createNewKhatma => 'إنشاء ختمة جديدة';

  @override
  String get myKhatmat => 'ختماتك قيد التنفيذ';

  @override
  String get noKhatma => 'لا توجد ختمة قيد التنفيذ';

  @override
  String get readingOptions => 'خيارات القراءة';

  @override
  String get mushafHafs => 'مصحف حفص';

  @override
  String get mushafHafsDesc => 'النسخة الأكثر انتشاراً';

  @override
  String get mushafWarsh => 'مصحف ورش';

  @override
  String get mushafWarshDesc => 'نسخة شمال أفريقيا';

  @override
  String get chooseMushafType => 'اختر نوع المصحف';

  @override
  String get mushafWomen => 'مصحف النساء';

  @override
  String get mushafWomenDesc => 'مصحف حفص — تصميم وردي أنيق';

  @override
  String get openMushaf => 'فتح المصحف';

  @override
  String get mushafHizb => 'الحزب';

  @override
  String get mushafPage => 'صفحة';

  @override
  String mushafHizbNumber(String number) {
    return 'الحزب $number';
  }

  @override
  String mushafPageNumber(String number) {
    return 'صفحة $number';
  }

  @override
  String mushafKhatmaHizbContext(String number) {
    return 'الحزب $number من ختمتك';
  }

  @override
  String mushafKhatmaHizbLeft(String number) {
    return 'لقد غادرت الحزب $number — العودة';
  }

  @override
  String get mushafBookmarkHere => 'وضع علامة هنا';

  @override
  String get mushafBookmarkHereDesc => 'علامة للاستمرار لاحقاً';

  @override
  String get mushafUnbookmark => 'إزالة العلامة';

  @override
  String get completionAlhamdulillah => 'الحمد لله';

  @override
  String get completionAccomplished => 'هذه الختمة مكتملة.';

  @override
  String get completionDua => 'تقبل الله هذا الختم وجهد كل مشارك.';

  @override
  String get completionHeaderSubtitle => 'ختمتكم مكتملة.';

  @override
  String completionHizbAccomplished(int count) {
    return '$count حزباً مكتملاً';
  }

  @override
  String completionParticipantsCount(int count) {
    return '$count مشاركين';
  }

  @override
  String completionDurationDays(int days) {
    return 'اكتملت في $days أيام';
  }

  @override
  String get completionDurationOneDay => 'اكتملت في يوم واحد';

  @override
  String completionClosedOn(String date) {
    return 'أُغلقت في $date';
  }

  @override
  String completionCollectiveMessage(int count) {
    return 'شارك $count أشخاص في هذه الختمة.';
  }

  @override
  String completionWithParticipants(String names) {
    return 'مع $names';
  }

  @override
  String get completionStartNew => 'بدء ختمة جديدة';

  @override
  String get completionShare => 'مشاركة';

  @override
  String get completionBackToMyKhatmas => 'العودة إلى ختماتي';

  @override
  String completionShareMessage(String title) {
    return 'الحمد لله، اكتملت ختمتنا «$title» على أنيس. تقبل الله جهود الجميع.';
  }

  @override
  String get completionViewClosure => 'عرض الإنجاز';

  @override
  String get completionFinishedBadge => 'مكتملة';

  @override
  String get completionSee => 'عرض';

  @override
  String completionProgressFraction(int completed, int total) {
    return '$completed/$total';
  }

  @override
  String get khatmaTitle => 'عنوان الختمة';

  @override
  String get objectives => 'الأهداف';

  @override
  String get inviteMembers => 'دعوة الأعضاء';

  @override
  String get memberEmail => 'بريد العضو';

  @override
  String get nextDistribution => 'التالي → توزيع الأحزاب';

  @override
  String get hizbDistribution => 'توزيع الأحزاب';

  @override
  String hizbAssigned(int count, int total) {
    return '$count/$total حزب معين';
  }

  @override
  String get autoDistribution => 'تلقائي';

  @override
  String get manualDistribution => 'يدوي';

  @override
  String get confirmDistribution => 'تأكيد التوزيع';

  @override
  String get sendReminder => 'إرسال تذكير';

  @override
  String get listOf60Hizb => 'قائمة الأربعين حزباً';

  @override
  String get unassigned => 'غير معين';

  @override
  String get assignedTo => 'معين لـ';

  @override
  String assignedToLabel(String name) {
    return 'معين لـ: $name';
  }

  @override
  String get khatmaCompleted => 'الختمة مكتملة! ماشاء الله';

  @override
  String get account => 'الحساب';

  @override
  String get preferences => 'التفضيلات';

  @override
  String get legal => 'قانوني';

  @override
  String get user => 'المستخدم';

  @override
  String get share => 'مشاركة';

  @override
  String get shareAchievements => 'مشاركة';

  @override
  String get shareAchievementsDesc => 'شارك تقدمك على واتساب أو تطبيقات أخرى.';

  @override
  String get shareWhatsApp => 'مشاركة (واتساب، إلخ)';

  @override
  String get shareYourProgress => 'مشاركة إنجازاتي';

  @override
  String get language => 'اللغة';

  @override
  String get french => 'Français';

  @override
  String get english => 'English';

  @override
  String get arabic => 'العربية';

  @override
  String get system => 'النظام';

  @override
  String get send => 'إرسال';

  @override
  String get cancel => 'إلغاء';

  @override
  String get featureComingSoon => 'الميزة قادمة قريباً';

  @override
  String get urlNotAvailable => 'الرابط غير متوفر';

  @override
  String get resetEmailMessage => 'سيتم إرسال بريد إلكتروني لإعادة التعيين.';

  @override
  String get bookmarks => 'المفضلة';

  @override
  String get completed => 'مكتملة';

  @override
  String get continueAction => 'متابعة';

  @override
  String get groupKhatma => 'ختمة جماعية';

  @override
  String get guestBadge => 'زائر';

  @override
  String get homeCollectiveProgress => 'التقدّم الجماعي';

  @override
  String get homeEmptyHint => 'أنشئ ختمة أو انضم إلى ختمة لمتابعة تقدّمك.';

  @override
  String get homeEmptyTitle => 'ابدأ ختمتك الأولى';

  @override
  String get homeGoalToday => 'هدف اليوم';

  @override
  String homeHizbInProgress(String number) {
    return 'الحزب $number قيد القراءة';
  }

  @override
  String homeHizbReserved(String number) {
    return 'الحزب $number محجوز';
  }

  @override
  String get homeLoadError => 'تعذّر تحميل ختماتك';

  @override
  String get homeLoadErrorHint => 'تحقّق من الاتصال ثم أعد المحاولة.';

  @override
  String get homePersonalProgress => 'تقدّمك';

  @override
  String get inProgress => 'قيد التنفيذ';

  @override
  String get joinCollectiveKhatma => 'الانضمام إلى ختمة جماعية';

  @override
  String get khatmaInProgress => 'ختمة جارية';

  @override
  String get lastActivity => 'آخر نشاط';

  @override
  String get myTraining => 'تدريبي';

  @override
  String get nextPrayer => 'الصلاة القادمة';

  @override
  String get offlineNotice => 'غير متصل — ستُزامَن بياناتك لاحقًا';

  @override
  String get prayerTimes => 'أوقات الصلاة';

  @override
  String get readingGoal => 'هدف القراءة';

  @override
  String get readingGoalAchieved => 'تم تحقيق الهدف!';

  @override
  String readingGoalProgress(int completed, int target) {
    return '$completed/$target حزب';
  }

  @override
  String get resume => 'استئناف';

  @override
  String get retry => 'إعادة المحاولة';

  @override
  String get seeAll => 'عرض الكل';

  @override
  String get statistics => 'الإحصائيات';

  @override
  String get khatmaRouteNotFoundTitle => 'الختمة غير موجودة';

  @override
  String get khatmaRouteNotFoundMessage =>
      'هذه الختمة لم تعد موجودة أو الرابط غير صالح.';

  @override
  String get khatmaRouteDemoUnavailableTitle =>
      'الختمة غير متاحة في وضع التجربة';

  @override
  String get khatmaRouteDemoUnavailableMessage =>
      'هذه الختمة غير متاحة في وضع التجربة. ارجع إلى القائمة أو أنشئ ختمة محلية.';

  @override
  String get khatmaRouteAccessDeniedTitle => 'تم رفض الوصول';

  @override
  String get khatmaRouteAccessDeniedMessage =>
      'ليس لديك حق الوصول إلى هذه الختمة.';

  @override
  String get khatmaRouteNetworkErrorTitle => 'خطأ في الشبكة';

  @override
  String get khatmaRouteNetworkErrorMessage =>
      'تعذّر تحميل هذه الختمة. تحقّق من اتصالك.';

  @override
  String get khatmaRouteLoadErrorTitle => 'تعذّر تحميل هذه الختمة';

  @override
  String get khatmaRouteLoadErrorMessage => 'حدث خطأ. أعد المحاولة.';

  @override
  String get khatmaRouteLoading => 'جارٍ تحميل الختمة...';

  @override
  String get myKhatmas => 'ختماتي';

  @override
  String get joinWithCode => 'الانضمام برمز';

  @override
  String get back => 'رجوع';

  @override
  String get wirdCompleteFinalPage => 'إتمام القرآن';

  @override
  String get wirdFinalPageCompleted => 'الحمد لله! لقد أتممت القرآن الكريم.';

  @override
  String get wirdMyWird => 'وردي';

  @override
  String get wirdPlanTooltip => 'الخطة';

  @override
  String get wirdConfigureTooltip => 'إعدادات';

  @override
  String get wirdDailySectionTitle => 'قراءة اليوم';

  @override
  String wirdObjectiveLabel(String target) {
    return 'الهدف: $target';
  }

  @override
  String wirdDailyCompleted(String target) {
    return '$target • تم إنجاز ورد اليوم';
  }

  @override
  String get wirdRemainingOneRub => 'يتبقى لك ربع واحد';

  @override
  String wirdRemainingManyRubs(int count) {
    return 'يتبقى لك $count ربع';
  }

  @override
  String get wirdContinueSectionTitle => 'مواصلة القراءة';

  @override
  String get wirdContinueSubtitle => 'استأنف من حيث توقفت';

  @override
  String wirdHizbNumber(int number) {
    return 'الحزب $number';
  }

  @override
  String wirdSurahAyah(int surah, int ayah) {
    return 'سورة $surah • آية $ayah';
  }

  @override
  String wirdPageNumber(int page) {
    return 'صفحة $page';
  }

  @override
  String wirdReadingMushaf(String mushaf) {
    return 'القراءة: $mushaf';
  }

  @override
  String get wirdNoReadingInProgress => 'لا توجد قراءة جارية';

  @override
  String get wirdResumeReading => 'استئناف القراءة';

  @override
  String get wirdStartReading => 'بدء القراءة';

  @override
  String get wirdDailyGoalTitle => 'الهدف اليومي';

  @override
  String get wirdDailyGoalSubtitle => 'اختر هدفك للقراءة اليومية';

  @override
  String get wirdLoadError => 'تعذر تحميل الورد';

  @override
  String get personalKhatmaTitle => 'ختمتي الشخصية';

  @override
  String get personalKhatmaProgressionLabel => 'التقدم';

  @override
  String get personalKhatmaDaysRemainingLabel => 'الأيام المتبقية';

  @override
  String personalKhatmaDaysRemainingValue(int days, String daysLabel) {
    return '$days $daysLabel';
  }

  @override
  String get personalKhatmaDaysUnit => 'أيام';

  @override
  String get personalKhatmaDayUnit => 'يوم';

  @override
  String get personalKhatmaScheduled => 'مُجدولة';

  @override
  String get personalKhatmaCompleted => 'الختمة مكتملة — الحمد لله';

  @override
  String get personalKhatmaCreateNew => 'إنشاء خطة جديدة';

  @override
  String personalKhatmaRemainingToRead(String remaining) {
    return 'يتبقى $remaining للقراءة';
  }

  @override
  String get personalKhatmaContinueWithoutDeadline =>
      'يمكنك مواصلة القراءة دون موعد نهائي';

  @override
  String get personalKhatmaManagePlan => 'إدارة خطتي';

  @override
  String get readingPlanTitle => 'خطة القراءة';

  @override
  String get readingPlanFreeGoalTitle => 'هدف يومي حر';

  @override
  String get readingPlanFreeGoalSubtitle => 'قراءة يومية دون موعد نهائي';

  @override
  String get readingPlanHijriMonthTitle => 'ختمة واحدة / شهر هجري';

  @override
  String get readingPlanHijriMonthSubtitle => 'إتمام القرآن في شهر قمري واحد';

  @override
  String get readingPlanGregorianMonthTitle => 'ختمة واحدة / شهر ميلادي';

  @override
  String get readingPlanGregorianMonthSubtitle => 'إتمام القرآن في شهر واحد';

  @override
  String get readingPlanStartingLabel => 'البداية';

  @override
  String get readingPlanStartNowLabel => 'ابدأ الآن';

  @override
  String get readingPlanStartNextLabel => 'ابدأ الشهر القادم';

  @override
  String readingPlanStartNowHijriDescription(String month) {
    return 'ما تبقى من شهر $month';
  }

  @override
  String readingPlanStartNowGregorianDescription(int days) {
    return 'ما تبقى من الشهر ($days أيام)';
  }

  @override
  String get readingPlanActivateFreeGoal => 'تفعيل الهدف الحر';

  @override
  String get readingPlanCreatePlan => 'إنشاء الخطة';

  @override
  String get readingPlanPreviewTitle => 'معاينة';

  @override
  String get readingPlanPreviewPeriod => 'الفترة';

  @override
  String get readingPlanPreviewReadingDays => 'أيام القراءة';

  @override
  String readingPlanPreviewReadingDaysValue(int days) {
    return '$days أيام';
  }

  @override
  String get readingPlanPreviewPace => 'الإيقاع الموصى به';

  @override
  String readingPlanError(String error) {
    return 'خطأ: $error';
  }

  @override
  String get hijriMonthMuharram => 'محرم';

  @override
  String get hijriMonthSafar => 'صفر';

  @override
  String get hijriMonthRabiAlAwwal => 'ربيع الأول';

  @override
  String get hijriMonthRabiAlThani => 'ربيع الثاني';

  @override
  String get hijriMonthJumadaAlAwwal => 'جمادى الأولى';

  @override
  String get hijriMonthJumadaAlThani => 'جمادى الآخرة';

  @override
  String get hijriMonthRajab => 'رجب';

  @override
  String get hijriMonthShaban => 'شعبان';

  @override
  String get hijriMonthRamadan => 'رمضان';

  @override
  String get hijriMonthShawwal => 'شوال';

  @override
  String get hijriMonthDhuAlQidah => 'ذو القعدة';

  @override
  String get hijriMonthDhuAlHijjah => 'ذو الحجة';

  @override
  String get gregorianMonthJanuary => 'يناير';

  @override
  String get gregorianMonthFebruary => 'فبراير';

  @override
  String get gregorianMonthMarch => 'مارس';

  @override
  String get gregorianMonthApril => 'أبريل';

  @override
  String get gregorianMonthMay => 'مايو';

  @override
  String get gregorianMonthJune => 'يونيو';

  @override
  String get gregorianMonthJuly => 'يوليو';

  @override
  String get gregorianMonthAugust => 'أغسطس';

  @override
  String get gregorianMonthSeptember => 'سبتمبر';

  @override
  String get gregorianMonthOctober => 'أكتوبر';

  @override
  String get gregorianMonthNovember => 'نوفمبر';

  @override
  String get gregorianMonthDecember => 'ديسمبر';

  @override
  String monthOfHijri(String month) {
    return 'شهر $month';
  }

  @override
  String monthOfGregorian(String month) {
    return 'شهر $month';
  }

  @override
  String homePrayerPill(String prayerName, String timeRemaining) {
    return '$prayerName · $timeRemaining';
  }

  @override
  String homeNextPrayerSemantic(String prayerName, String timeRemaining) {
    return 'الصلاة التالية: $prayerName بعد $timeRemaining';
  }

  @override
  String get prayerFajr => 'الفجر';

  @override
  String get prayerDhuhr => 'الظهر';

  @override
  String get prayerAsr => 'العصر';

  @override
  String get prayerMaghrib => 'المغرب';

  @override
  String get prayerIsha => 'العشاء';

  @override
  String timeIn(String duration) {
    return 'بعد $duration';
  }

  @override
  String get courseLevelBeginner => 'مبتدئ';

  @override
  String get courseLevelIntermediate => 'متوسط';

  @override
  String get courseLevelAdvanced => 'متقدم';

  @override
  String get courseCategoryTajweed => 'تجويد';

  @override
  String get courseCategoryTafsir => 'تفسير';

  @override
  String get courseCategoryFiqh => 'فقه';

  @override
  String get courseCategorySira => 'سيرة';

  @override
  String get courseCategoryAqida => 'عقيدة';

  @override
  String get courseCategoryArabic => 'عربية';

  @override
  String get courseCategoryMemorization => 'حفظ';

  @override
  String get courseCategorySpirituality => 'روحانية';

  @override
  String get courseCategoryOther => 'أخرى';

  @override
  String homeRamadanPillFr(int day) {
    return 'رمضان · يوم $day من 30';
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
  String get notificationsTitle => 'الإشعارات';

  @override
  String get notificationsEmptyTitle => 'لا توجد إشعارات';

  @override
  String get notificationsEmptySubtitle => 'أنت على اطلاع';

  @override
  String get notificationsSettingsTitle => 'إعدادات الإشعارات';

  @override
  String get notificationsEnableReadingReminders => 'تفعيل تذكيرات القراءة';

  @override
  String get notificationsReceiveHizbReminders => 'تلقي تذكيرات لحزبك اليومي';

  @override
  String get notificationsGroupNotifications => 'إشعارات المجموعة';

  @override
  String get notificationsWorkshopReminders => 'تذكيرات الورش';

  @override
  String get notificationsMarkAsRead => 'تحديد كمقروء';

  @override
  String get notificationsDelete => 'حذف';

  @override
  String get notificationsDemoReadingTime => 'حان وقت القراءة';

  @override
  String get notificationsDemoReadingTimeBody => 'لا تنسَ إكمال حزبك اليومي';

  @override
  String get notificationsDemoKhatmaReminder => 'تذكير الختمة';

  @override
  String get notificationsDemoKhatmaBody => 'ختمة مجموعتك في انتظارك';

  @override
  String get notificationsDemoWorkshop => 'ورشة تدريبية';

  @override
  String get notificationsDemoWorkshopBody => 'جلسة جديدة متاحة الأسبوع القادم';

  @override
  String notificationsTimeHoursAgo(int hours) {
    return 'منذ $hours ساعات';
  }

  @override
  String get notificationsTimeYesterday => 'أمس';

  @override
  String notificationsTimeDaysAgo(int days) {
    return 'منذ $days أيام';
  }

  @override
  String get wirdTodayObjective => 'هدف اليوم';

  @override
  String wirdPlusQuarterNext(int quarters) {
    return 'ثم $quarters ربع من الحزب التالي';
  }

  @override
  String wirdPlusQuartersNext(int quarters) {
    return 'ثم $quarters أرباع من الحزب التالي';
  }

  @override
  String get wirdMonthlyProgress => 'التقدم';

  @override
  String wirdHizbCompleted(int count) {
    return '$count حزب مكتمل';
  }

  @override
  String get wirdInProgressFirstHizb => 'جاري الحزب الأول';

  @override
  String wirdDaysRemaining(int days) {
    return '$days يوم متبقي';
  }

  @override
  String get wirdPersonalKhatma => 'ختمتي الشخصية';

  @override
  String get wirdHizbUnit => 'حزب';

  @override
  String wirdHizbOver(int current, int total) {
    return '$current / $total';
  }

  @override
  String get wirdHizbCompleted_one => 'حزب واحد مكتمل';

  @override
  String wirdHizbCompleted_other(int count) {
    return '$count أحزاب مكتملة';
  }

  @override
  String get wirdNextHizbInProgress => 'الحزب التالي قيد التقدم';

  @override
  String get wirdKhatmaInProgress => 'الختمة جارية';

  @override
  String wirdPercentOfKhatma(int percent) {
    return '$percent٪ من ختمتي';
  }

  @override
  String wirdHizbCompletedOutOf(int completed, int total) {
    return '$completed حزب مكتمل من $total';
  }

  @override
  String wirdHizbCompletedOutOf_other(int completed, int total) {
    return '$completed أحزاب مكتملة من $total';
  }

  @override
  String get wirdOfMyKhatma => 'من ختمتي';

  @override
  String get inviteFamilyFriends => 'ادع عائلتك وأصدقاءك';

  @override
  String get createCollaborativeKhatma => 'إنشاء ختمة جماعية';

  @override
  String get khatmaExampleTitle => 'مثال: ختمة رمضان ٢٠٢٥';

  @override
  String get describeObjectives => 'صف أهدافك...';

  @override
  String get myKhatma => 'ختمتي';

  @override
  String get khatmaEmptyMessage =>
      'أنشئ ختمة جماعية، وادع أحباءك ووزع الأحزاب.';

  @override
  String get quickActionMushafSubtitle => 'استئناف القراءة';

  @override
  String get quickActionKhatmaSubtitle => 'ختماتي';

  @override
  String get quickActionFormationsTitle => 'التدريب';

  @override
  String get quickActionFormationsSubtitle => 'دوراتي';

  @override
  String get quickActionNotificationsSubtitle => 'إدارة التنبيهات';

  @override
  String get loginWelcome => 'مرحباً';

  @override
  String get loginSubtitle => 'سجل الدخول لمتابعة ختمتك';

  @override
  String get loginContinueOtherwise => 'المتابعة بطريقة أخرى';

  @override
  String get loginDiscoverDemo => 'استكشاف الوضع التجريبي';

  @override
  String get loginFirebaseUnavailable =>
      'Firebase غير متاح. استخدم الوضع التجريبي أو أعد تشغيل التطبيق.';

  @override
  String get loginEmailRequired => 'البريد الإلكتروني مطلوب';

  @override
  String get loginEmailInvalid => 'بريد إلكتروني غير صالح';

  @override
  String get loginPasswordRequired => 'كلمة المرور مطلوبة';

  @override
  String get loginUserNotFound => 'لا يوجد حساب مرتبط بهذا البريد الإلكتروني.';

  @override
  String get loginWrongPassword => 'كلمة مرور غير صحيحة.';

  @override
  String get loginInvalidEmail => 'بريد إلكتروني غير صالح.';

  @override
  String loginErrorGeneric(String error) {
    return 'خطأ: $error';
  }

  @override
  String get khatmaCreationAuthRequired => 'تسجيل الدخول مطلوب لإنشاء ختمة';

  @override
  String get khatmaCreationPermissionDenied => 'تم رفض الإذن. تحقق من اتصالك.';

  @override
  String get khatmaCreationNetworkError =>
      'خطأ في الشبكة. تحقق من اتصال الإنترنت.';

  @override
  String get khatmaCreationInitFailed => 'فشل التهيئة. يرجى المحاولة مرة أخرى.';

  @override
  String get khatmaCreationUnknown =>
      'خطأ غير متوقع. اتصل بالدعم إذا استمرت المشكلة.';

  @override
  String get khatmaCreationRetry => 'إعادة المحاولة';

  @override
  String get khatmaCreated => 'تم إنشاء الختمة بنجاح';

  @override
  String get khatmaCreationFailed => 'فشل إنشاء الختمة';

  @override
  String get khatmaCreationSubmitting => 'جاري الإنشاء…';

  @override
  String get khatmaCreationInitializing => 'تهيئة الـ 60 حزب…';

  @override
  String get reserveThisHizb => 'احجز هذا الحزب';

  @override
  String get reserveForMe => 'لي';

  @override
  String get reserveForSomeoneElse => 'لشخص آخر';

  @override
  String get reserveForSomeoneElseHint => 'شخص خارج التطبيق (الاسم فقط)';

  @override
  String get personShortName => 'الاسم';

  @override
  String reservedForPerson(String name) {
    return 'محجوز لـ $name';
  }

  @override
  String reservedByPerson(String name) {
    return 'بواسطة $name';
  }

  @override
  String get takeNextAvailableHizb => 'أخذ الحزب المتاح التالي';

  @override
  String collectiveHizbSummary(int completed, int reserved, int available) {
    return '$completed مكتمل · $reserved محجوز · $available متاح';
  }

  @override
  String get noHizbAvailable => 'لا يوجد حزب متاح';
}
