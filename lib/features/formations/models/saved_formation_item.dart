import 'package:equatable/equatable.dart';

enum SavedItemType {
  course,
  lesson;

  String toJson() => name;
  static SavedItemType fromJson(String json) => SavedItemType.values.byName(json);
}

class SavedFormationItem extends Equatable {
  final String id;
  final SavedItemType type;
  final String targetId;
  final String? courseId; // Required for lessons, null for courses
  final DateTime savedAt;

  const SavedFormationItem({
    required this.id,
    required this.type,
    required this.targetId,
    required this.courseId,
    required this.savedAt,
  });

  factory SavedFormationItem.fromJson(Map<String, dynamic> json) {
    return SavedFormationItem(
      id: json['id'] as String,
      type: SavedItemType.fromJson(json['type'] as String),
      targetId: json['targetId'] as String,
      courseId: json['courseId'] as String?,
      savedAt: DateTime.parse(json['savedAt'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type.toJson(),
      'targetId': targetId,
      'courseId': courseId,
      'savedAt': savedAt.toIso8601String(),
    };
  }

  @override
  List<Object?> get props => [id, type, targetId, courseId, savedAt];
}
