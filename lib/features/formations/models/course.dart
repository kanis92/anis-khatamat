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
  );

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
  };

  String get levelLabel {
    switch (level) {
      case CourseLevel.beginner:
        return 'Débutant';
      case CourseLevel.intermediate:
        return 'Intermédiaire';
      case CourseLevel.advanced:
        return 'Avancé';
    }
  }

  String get categoryLabel {
    switch (category) {
      case CourseCategory.tajweed:
        return 'Tajweed';
      case CourseCategory.tafsir:
        return 'Tafsir';
      case CourseCategory.fiqh:
        return 'Fiqh';
      case CourseCategory.sira:
        return 'Sîra';
      case CourseCategory.aqida:
        return 'Aqida';
      case CourseCategory.arabic:
        return 'Arabe';
      case CourseCategory.memorization:
        return 'Mémorisation';
      case CourseCategory.spirituality:
        return 'Spiritualité';
      case CourseCategory.other:
        return 'Autre';
    }
  }

  @override
  List<Object?> get props => [id, title, level, category, isPublished];
}
