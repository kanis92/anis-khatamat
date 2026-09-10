import 'package:equatable/equatable.dart';

enum FormationSearchResultType {
  course,
  module,
  lesson;
}

/// Search result referencing canonical Formation content
class FormationSearchResult extends Equatable {
  final FormationSearchResultType type;
  final String targetId;
  final String title;
  final String? courseId; // Required for modules and lessons
  final String? courseTitle; // Parent context
  final String? moduleTitle; // For lessons only
  final double score; // Ranking score (higher = better match)

  const FormationSearchResult({
    required this.type,
    required this.targetId,
    required this.title,
    this.courseId,
    this.courseTitle,
    this.moduleTitle,
    required this.score,
  });

  @override
  List<Object?> get props => [
        type,
        targetId,
        title,
        courseId,
        courseTitle,
        moduleTitle,
        score,
      ];
}
