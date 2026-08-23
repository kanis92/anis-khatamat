import 'package:equatable/equatable.dart';

class CourseModule extends Equatable {
  final String id;
  final String courseId;
  final String title;
  final String? description;
  final int order;
  final List<String> lessonIds;

  const CourseModule({
    required this.id,
    required this.courseId,
    required this.title,
    this.description,
    required this.order,
    this.lessonIds = const [],
  });

  factory CourseModule.fromFirestore(String id, Map<String, dynamic> d) =>
      CourseModule(
        id: id,
        courseId: d['courseId'] as String,
        title: d['title'] as String,
        description: d['description'] as String?,
        order: (d['order'] as int?) ?? 0,
        lessonIds: List<String>.from(d['lessonIds'] as List? ?? []),
      );

  Map<String, dynamic> toFirestore() => {
    'courseId': courseId,
    'title': title,
    'description': description,
    'order': order,
    'lessonIds': lessonIds,
  };

  @override
  List<Object?> get props => [id, courseId, title, order];
}
