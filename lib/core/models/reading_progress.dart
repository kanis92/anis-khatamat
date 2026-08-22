import 'package:equatable/equatable.dart';

/// Progression de lecture : Hizb complétés par Khatma
class ReadingProgress extends Equatable {
  final String khatmaId;
  final String userId;
  final Set<int> completedHizb; // 1-60
  final DateTime lastUpdated;
  /// UID Firebase pour invités (guestId) — requis pour les règles Firestore strictes
  final String? authUid;

  const ReadingProgress({
    required this.khatmaId,
    required this.userId,
    this.completedHizb = const {},
    required this.lastUpdated,
    this.authUid,
  });

  int get completedCount => completedHizb.length;

  ReadingProgress copyWith({
    String? khatmaId,
    String? userId,
    Set<int>? completedHizb,
    DateTime? lastUpdated,
    String? authUid,
  }) {
    return ReadingProgress(
      khatmaId: khatmaId ?? this.khatmaId,
      userId: userId ?? this.userId,
      completedHizb: completedHizb ?? this.completedHizb,
      lastUpdated: lastUpdated ?? this.lastUpdated,
      authUid: authUid ?? this.authUid,
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
      authUid: map['authUid'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    final m = <String, dynamic>{
      'khatmaId': khatmaId,
      'userId': userId,
      'completedHizb': completedHizb.toList(),
      'lastUpdated': lastUpdated.toIso8601String(),
    };
    if (authUid != null) m['authUid'] = authUid;
    return m;
  }

  @override
  List<Object?> get props => [khatmaId, userId, completedHizb, lastUpdated, authUid];
}
