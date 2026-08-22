import 'package:equatable/equatable.dart';

enum LessonType { video, audio, text, markdown }

class Lesson extends Equatable {
  final String id;
  final String moduleId;
  final String courseId;
  final String title;
  final String? description;
  final LessonType type;
  final String? contentUrl; // Firebase Storage URL (video/audio)
  final String? contentText; // Markdown or plain text
  final int durationMinutes;
  final int order;
  final List<QuizQuestion> quiz;

  const Lesson({
    required this.id,
    required this.moduleId,
    required this.courseId,
    required this.title,
    this.description,
    required this.type,
    this.contentUrl,
    this.contentText,
    this.durationMinutes = 0,
    required this.order,
    this.quiz = const [],
  });

  factory Lesson.fromFirestore(String id, Map<String, dynamic> d) => Lesson(
    id: id,
    moduleId: d['moduleId'] as String,
    courseId: d['courseId'] as String,
    title: d['title'] as String,
    description: d['description'] as String?,
    type: LessonType.values.firstWhere(
      (e) => e.name == (d['type'] as String? ?? 'text'),
      orElse: () => LessonType.text,
    ),
    contentUrl: d['contentUrl'] as String?,
    contentText: d['contentText'] as String?,
    durationMinutes: (d['durationMinutes'] as int?) ?? 0,
    order: (d['order'] as int?) ?? 0,
    quiz:
        (d['quiz'] as List<dynamic>? ?? [])
            .map((e) => QuizQuestion.fromMap(e as Map<String, dynamic>))
            .toList(),
  );

  Map<String, dynamic> toFirestore() => {
    'moduleId': moduleId,
    'courseId': courseId,
    'title': title,
    'description': description,
    'type': type.name,
    'contentUrl': contentUrl,
    'contentText': contentText,
    'durationMinutes': durationMinutes,
    'order': order,
    'quiz': quiz.map((q) => q.toMap()).toList(),
  };

  @override
  List<Object?> get props => [id, moduleId, courseId, title, type, order];
}

class QuizQuestion extends Equatable {
  final String question;
  final List<String> options;
  final int correctIndex;
  final String? explanation;

  const QuizQuestion({
    required this.question,
    required this.options,
    required this.correctIndex,
    this.explanation,
  });

  factory QuizQuestion.fromMap(Map<String, dynamic> d) => QuizQuestion(
    question: d['question'] as String,
    options: List<String>.from(d['options'] as List),
    correctIndex: (d['correctIndex'] as int?) ?? 0,
    explanation: d['explanation'] as String?,
  );

  Map<String, dynamic> toMap() => {
    'question': question,
    'options': options,
    'correctIndex': correctIndex,
    'explanation': explanation,
  };

  @override
  List<Object?> get props => [question, correctIndex];
}
