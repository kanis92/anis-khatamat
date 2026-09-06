import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

enum CourseLevel { beginner, intermediate, advanced }

enum CourseCategory {
  tajweed,
  tafsir,
  fiqh,
  sira,
  aqida,
  arabic,
  memorization,
  spirituality,
  other,
}

/// Lien contextuel vers une feature de l'app
class LinkedFeature {
  final String label;
  final String route; // ex: /khatma/plan, /khatma/join, /quran/today

  const LinkedFeature({required this.label, required this.route});

  factory LinkedFeature.fromMap(Map<String, dynamic> d) =>
      LinkedFeature(label: d['label'] as String, route: d['route'] as String);

  Map<String, dynamic> toMap() => {'label': label, 'route': route};
}

class CourseTranslation {
  const CourseTranslation({
    required this.title,
    required this.description,
    this.linkedFeatures = const [],
  });

  final String title;
  final String description;
  final List<LinkedFeature> linkedFeatures;

  factory CourseTranslation.fromMap(Map<String, dynamic> d) =>
      CourseTranslation(
        title: d['title'] as String? ?? '',
        description: d['description'] as String? ?? '',
        linkedFeatures:
            (d['linkedFeatures'] as List<dynamic>? ?? [])
                .map((e) => LinkedFeature.fromMap(e as Map<String, dynamic>))
                .toList(),
      );

  Map<String, dynamic> toMap() => {
    'title': title,
    'description': description,
    if (linkedFeatures.isNotEmpty)
      'linkedFeatures': linkedFeatures.map((f) => f.toMap()).toList(),
  };
}

class Course extends Equatable {
  final String id;
  final String title;
  final String description;
  final String? thumbnailUrl;
  final CourseLevel level;
  final CourseCategory category;
  final String instructor;
  final int totalLessons;
  final int totalDurationMinutes;
  final List<String> tags;
  final List<LinkedFeature> linkedFeatures;
  final DateTime createdAt;
  final bool isPublished;
  final Map<String, CourseTranslation>? translations;

  const Course({
    required this.id,
    required this.title,
    required this.description,
    this.thumbnailUrl,
    this.level = CourseLevel.beginner,
    this.category = CourseCategory.other,
    required this.instructor,
    this.totalLessons = 0,
    this.totalDurationMinutes = 0,
    this.tags = const [],
    this.linkedFeatures = const [],
    required this.createdAt,
    this.isPublished = true,
    this.translations,
  });

  factory Course.fromFirestore(String id, Map<String, dynamic> d) => Course(
    id: id,
    title: d['title'] as String,
    description: d['description'] as String,
    thumbnailUrl: d['thumbnailUrl'] as String?,
    level: CourseLevel.values.firstWhere(
      (e) => e.name == (d['level'] as String? ?? 'beginner'),
      orElse: () => CourseLevel.beginner,
    ),
    category: CourseCategory.values.firstWhere(
      (e) => e.name == (d['category'] as String? ?? 'other'),
      orElse: () => CourseCategory.other,
    ),
    instructor: d['instructor'] as String? ?? '',
    totalLessons: (d['totalLessons'] as int?) ?? 0,
    totalDurationMinutes: (d['totalDurationMinutes'] as int?) ?? 0,
    tags: List<String>.from(d['tags'] as List? ?? []),
    linkedFeatures:
        (d['linkedFeatures'] as List<dynamic>? ?? [])
            .map((e) => LinkedFeature.fromMap(e as Map<String, dynamic>))
            .toList(),
    createdAt: (d['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    isPublished: (d['isPublished'] as bool?) ?? true,
    translations: _parseTranslations(d['translations']),
  );

  static Map<String, CourseTranslation>? _parseTranslations(dynamic raw) {
    if (raw is! Map) return null;
    final out = <String, CourseTranslation>{};
    raw.forEach((key, value) {
      if (value is Map<String, dynamic>) {
        out[key.toString()] = CourseTranslation.fromMap(value);
      } else if (value is Map) {
        out[key.toString()] = CourseTranslation.fromMap(
          value.cast<String, dynamic>(),
        );
      }
    });
    return out.isEmpty ? null : out;
  }

  Map<String, dynamic> toFirestore() => {
    'title': title,
    'description': description,
    'thumbnailUrl': thumbnailUrl,
    'level': level.name,
    'category': category.name,
    'instructor': instructor,
    'totalLessons': totalLessons,
    'totalDurationMinutes': totalDurationMinutes,
    'tags': tags,
    'linkedFeatures': linkedFeatures.map((f) => f.toMap()).toList(),
    'createdAt': Timestamp.fromDate(createdAt),
    'isPublished': isPublished,
    if (translations != null)
      'translations': translations!.map((k, v) => MapEntry(k, v.toMap())),
  };


  @override
  List<Object?> get props => [id, title, level, category, isPublished];
}
