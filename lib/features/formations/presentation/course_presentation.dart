import 'package:flutter/widgets.dart';

import '../models/course.dart';
import '../../../l10n/gen_l10n/app_localizations.dart';

/// Presentation layer for Course localization.
/// 
/// Keeps the domain model (Course) free from Flutter dependencies.
class CoursePresentationLabels {
  const CoursePresentationLabels._();

  static String level(CourseLevel level, AppLocalizations l10n) {
    return switch (level) {
      CourseLevel.beginner => l10n.courseLevelBeginner,
      CourseLevel.intermediate => l10n.courseLevelIntermediate,
      CourseLevel.advanced => l10n.courseLevelAdvanced,
    };
  }

  static String category(CourseCategory category, AppLocalizations l10n) {
    return switch (category) {
      CourseCategory.tajweed => l10n.courseCategoryTajweed,
      CourseCategory.tafsir => l10n.courseCategoryTafsir,
      CourseCategory.fiqh => l10n.courseCategoryFiqh,
      CourseCategory.sira => l10n.courseCategorySira,
      CourseCategory.aqida => l10n.courseCategoryAqida,
      CourseCategory.arabic => l10n.courseCategoryArabic,
      CourseCategory.memorization => l10n.courseCategoryMemorization,
      CourseCategory.spirituality => l10n.courseCategorySpirituality,
      CourseCategory.other => l10n.courseCategoryOther,
    };
  }
}

/// Extension for convenient access in UI code.
extension CoursePresentationExtension on Course {
  String localizedLevel(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return CoursePresentationLabels.level(level, l10n);
  }

  String localizedCategory(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return CoursePresentationLabels.category(category, l10n);
  }
}
