import 'package:flutter/widgets.dart';

import '../models/course.dart';
import '../models/pedagogical_pillar.dart';
import '../../../l10n/gen_l10n/app_localizations.dart';
import 'course_content_resolver.dart';

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

  /// V1: Pedagogical pillar labels
  static String pillar(PedagogicalPillar pillar, AppLocalizations l10n) {
    return switch (pillar) {
      PedagogicalPillar.foundationsPractice => l10n.pillarFoundationsPractice,
      PedagogicalPillar.quranReading => l10n.pillarQuranReading,
      PedagogicalPillar.prophetSeerahSunnah => l10n.pillarProphetSeerahSunnah,
      PedagogicalPillar.dailyLifeFrance => l10n.pillarDailyLifeFrance,
      PedagogicalPillar.characterEthics => l10n.pillarCharacterEthics,
      PedagogicalPillar.spiritualityHeart => l10n.pillarSpiritualityHeart,
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

  /// V1: Prioritize pillar, fallback to category
  String localizedPillarOrCategory(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    // Try to resolve pillar first
    if (pillarId != null) {
      final pillar = PedagogicalPillar.fromId(pillarId!);
      if (pillar != null) {
        return CoursePresentationLabels.pillar(pillar, l10n);
      }
    }

    // Fallback to legacy category
    return CoursePresentationLabels.category(category, l10n);
  }

  ResolvedCourseContent resolvedContent(BuildContext context) {
    return CourseContentResolver.resolve(
      this,
      Localizations.localeOf(context),
    );
  }

  String localizedTitle(BuildContext context) => resolvedContent(context).title;

  String localizedDescription(BuildContext context) =>
      resolvedContent(context).description;
}
