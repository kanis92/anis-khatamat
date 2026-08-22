import 'package:equatable/equatable.dart';

/// Signet : référence à un verset ou une page du Coran (pour pause/reprise)
class Bookmark extends Equatable {
  final String id;
  final int surahNumber;
  final int verseNumber;
  final int? pageNumber; // Page Mushaf (1-604) pour navigation directe
  final String? note;
  final DateTime createdAt;

  const Bookmark({
    required this.id,
    required this.surahNumber,
    required this.verseNumber,
    this.pageNumber,
    this.note,
    required this.createdAt,
  });

  factory Bookmark.fromMap(Map<String, dynamic> map) => Bookmark(
        id: map['id'] as String? ?? '',
        surahNumber: map['surahNumber'] as int? ?? 1,
        verseNumber: map['verseNumber'] as int? ?? 1,
        pageNumber: map['pageNumber'] as int?,
        note: map['note'] as String?,
        createdAt: map['createdAt'] != null
            ? DateTime.parse(map['createdAt'].toString())
            : DateTime.now(),
      );

  Map<String, dynamic> toMap() => {
        'id': id,
        'surahNumber': surahNumber,
        'verseNumber': verseNumber,
        if (pageNumber != null) 'pageNumber': pageNumber,
        'note': note,
        'createdAt': createdAt.toIso8601String(),
      };

  @override
  List<Object?> get props => [id, surahNumber, verseNumber];
}
