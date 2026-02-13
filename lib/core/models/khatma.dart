import 'package:equatable/equatable.dart';

/// Représente une Khatma (individuelle ou groupe)
class Khatma extends Equatable {
  final String id;
  final String title;
  final String? objectives;
  final bool isGroup;
  final List<String> members;
  final Map<int, String> hizbAssignments; // hizbNumber -> memberEmail
  final String createdBy;
  final DateTime createdAt;

  const Khatma({
    required this.id,
    required this.title,
    this.objectives,
    required this.isGroup,
    this.members = const [],
    this.hizbAssignments = const {},
    required this.createdBy,
    required this.createdAt,
  });

  factory Khatma.fromMap(Map<String, dynamic> map) {
    final assignments = map['hizbAssignments'] as Map<String, dynamic>? ?? {};
    return Khatma(
      id: map['id'] as String? ?? '',
      title: map['title'] as String? ?? '',
      objectives: map['objectives'] as String?,
      isGroup: map['isGroup'] as bool? ?? false,
      members: List<String>.from(map['members'] as List? ?? []),
      hizbAssignments: assignments.map((k, v) => MapEntry(int.parse(k.toString()), v.toString())),
      createdBy: map['createdBy'] as String? ?? '',
      createdAt: map['createdAt'] != null
          ? DateTime.parse(map['createdAt'].toString())
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'objectives': objectives,
      'isGroup': isGroup,
      'members': members,
      'hizbAssignments': hizbAssignments.map((k, v) => MapEntry(k.toString(), v)),
      'createdBy': createdBy,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  @override
  List<Object?> get props => [id, title, createdAt];
}
