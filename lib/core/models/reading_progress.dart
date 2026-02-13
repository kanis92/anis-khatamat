import 'package:equatable/equatable.dart';

/// Progression de lecture : Hizb complétés par Khatma
class ReadingProgress extends Equatable {
  final String khatmaId;
  final String userId;
  final Set<int> completedHizb; // 1-60
  final DateTime lastUpdated;

  const ReadingProgress({
    required this.khatmaId,
    required this.userId,
    this.completedHizb = const {},
    required this.lastUpdated,
  });

  int get completedCount => completedHizb.length;

  ReadingProgress copyWith({
    String? khatmaId,
    String? userId,
    Set<int>? completedHizb,
    DateTime? lastUpdated,
  }) {
    return ReadingProgress(
      khatmaId: khatmaId ?? this.khatmaId,
      userId: userId ?? this.userId,
      completedHizb: completedHizb ?? this.completedHizb,
      lastUpdated: lastUpdated ?? this.lastUpdated,
    );
  }

  factory ReadingProgress.fromMap(Map<String, dynamic> map) {
    final list = map['completedHizb'] as List? ?? [];
    return ReadingProgress(
      khatmaId: map['khatmaId'] as String? ?? '',
      userId: map['userId'] as String? ?? '',
      completedHizb: list.map((e) => (e as num).toInt()).toSet(),
      lastUpdated: map['lastUpdated'] != null
          ? DateTime.parse(map['lastUpdated'].toString())
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'khatmaId': khatmaId,
      'userId': userId,
      'completedHizb': completedHizb.toList(),
      'lastUpdated': lastUpdated.toIso8601String(),
    };
  }

  @override
  List<Object?> get props => [khatmaId, userId, completedHizb, lastUpdated];
}
