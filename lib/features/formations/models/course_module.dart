import 'package:equatable/equatable.dart';

class ModuleTranslation {
  const ModuleTranslation({
    required this.title,
    this.description,
  });

  final String title;
  final String? description;

  factory ModuleTranslation.fromMap(Map<String, dynamic> d) =>
      ModuleTranslation(
        title: d['title'] as String? ?? '',
        description: d['description'] as String?,
      );

  Map<String, dynamic> toMap() => {
    'title': title,
    if (description != null) 'description': description,
  };
}

class CourseModule extends Equatable {
  final String id;
  final String courseId;
  final String title;
  final String? description;
  final int order;
  final List<String> lessonIds;
  final Map<String, ModuleTranslation>? translations;

  const CourseModule({
    required this.id,
    required this.courseId,
    required this.title,
    this.description,
    required this.order,
    this.lessonIds = const [],
    this.translations,
  });

  factory CourseModule.fromFirestore(String id, Map<String, dynamic> d) =>
      CourseModule(
        id: id,
        courseId: d['courseId'] as String,
        title: d['title'] as String,
        description: d['description'] as String?,
        order: (d['order'] as int?) ?? 0,
        lessonIds: List<String>.from(d['lessonIds'] as List? ?? []),
        translations: _parseTranslations(d['translations']),
      );

  static Map<String, ModuleTranslation>? _parseTranslations(dynamic raw) {
    if (raw is! Map) return null;
    final out = <String, ModuleTranslation>{};
    raw.forEach((key, value) {
      if (value is Map<String, dynamic>) {
        out[key.toString()] = ModuleTranslation.fromMap(value);
      } else if (value is Map) {
        out[key.toString()] = ModuleTranslation.fromMap(
          value.cast<String, dynamic>(),
        );
      }
    });
    return out.isEmpty ? null : out;
  }

  Map<String, dynamic> toFirestore() => {
    'courseId': courseId,
    'title': title,
    'description': description,
    'order': order,
    'lessonIds': lessonIds,
    if (translations != null)
      'translations': translations!.map((k, v) => MapEntry(k, v.toMap())),
  };

  @override
  List<Object?> get props => [id, courseId, title, order];
}
