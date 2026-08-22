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
}
