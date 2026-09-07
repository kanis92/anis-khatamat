import 'package:equatable/equatable.dart';

enum LessonType { video, audio, text, markdown }

class QuranReference {
  final int surah;
  final int? startAyah;
  final int? endAyah;

  const QuranReference({
    required this.surah,
    this.startAyah,
    this.endAyah,
  });

  factory QuranReference.fromMap(Map<String, dynamic> d) => QuranReference(
    surah: d['surah'] as int,
    startAyah: d['startAyah'] as int?,
    endAyah: d['endAyah'] as int?,
  );

  Map<String, dynamic> toMap() => {
    'surah': surah,
    if (startAyah != null) 'startAyah': startAyah,
    if (endAyah != null) 'endAyah': endAyah,
  };
}

class LessonTranslation {
  const LessonTranslation({
    required this.title,
    this.description,
    this.contentText,
    this.summary = const [],
    this.actionToApply,
  });

  final String title;
  final String? description;
  final String? contentText;
  final List<String> summary;
  final String? actionToApply;

  factory LessonTranslation.fromMap(Map<String, dynamic> d) =>
      LessonTranslation(
        title: d['title'] as String? ?? '',
        description: d['description'] as String?,
        contentText: d['contentText'] as String?,
        summary: List<String>.from(d['summary'] as List? ?? []),
        actionToApply: d['actionToApply'] as String?,
      );

  Map<String, dynamic> toMap() => {
    'title': title,
    if (description != null) 'description': description,
    if (contentText != null) 'contentText': contentText,
    if (summary.isNotEmpty) 'summary': summary,
    if (actionToApply != null) 'actionToApply': actionToApply,
  };
}

class Lesson extends Equatable {
  final String id;
  final String moduleId;
  final String courseId;
  final String title;
  final String? description;
  final LessonType type;
  final String? contentUrl; // Firebase Storage URL (video/audio)
  final String? contentText; // Markdown or plain text
  final List<String> summary; // Editorial summary points (3-5)
  final String? actionToApply; // Practical small mission
  final QuranReference? quranRef; // Optional Quran connection
  final int durationMinutes;
  final int order;
  final List<QuizQuestion> quiz;
  final Map<String, LessonTranslation>? translations;

  const Lesson({
    required this.id,
    required this.moduleId,
    required this.courseId,
    required this.title,
    this.description,
    required this.type,
    this.contentUrl,
    this.contentText,
    this.summary = const [],
    this.actionToApply,
    this.quranRef,
    this.durationMinutes = 0,
    required this.order,
    this.quiz = const [],
    this.translations,
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
    summary: List<String>.from(d['summary'] as List? ?? []),
    actionToApply: d['actionToApply'] as String?,
    quranRef: d['quranRef'] != null 
        ? QuranReference.fromMap(d['quranRef'] as Map<String, dynamic>)
        : null,
    durationMinutes: (d['durationMinutes'] as int?) ?? 0,
    order: (d['order'] as int?) ?? 0,
    quiz:
        (d['quiz'] as List<dynamic>? ?? [])
            .map((e) => QuizQuestion.fromMap(e as Map<String, dynamic>))
            .toList(),
    translations: _parseTranslations(d['translations']),
  );

  static Map<String, LessonTranslation>? _parseTranslations(dynamic raw) {
    if (raw is! Map) return null;
    final out = <String, LessonTranslation>{};
    raw.forEach((key, value) {
      if (value is Map<String, dynamic>) {
        out[key.toString()] = LessonTranslation.fromMap(value);
      } else if (value is Map) {
        out[key.toString()] = LessonTranslation.fromMap(
          value.cast<String, dynamic>(),
        );
      }
    });
    return out.isEmpty ? null : out;
  }

  Map<String, dynamic> toFirestore() => {
    'moduleId': moduleId,
    'courseId': courseId,
    'title': title,
    'description': description,
    'type': type.name,
    'contentUrl': contentUrl,
    'contentText': contentText,
    if (summary.isNotEmpty) 'summary': summary,
    'actionToApply': actionToApply,
    if (quranRef != null) 'quranRef': quranRef!.toMap(),
    'durationMinutes': durationMinutes,
    'order': order,
    'quiz': quiz.map((q) => q.toMap()).toList(),
    if (translations != null)
      'translations': translations!.map((k, v) => MapEntry(k, v.toMap())),
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
