import 'package:equatable/equatable.dart';

/// Objectif de lecture — ex. 1 Juz/jour, 2 Hizb/semaine
enum ReadingGoalPeriod { daily, weekly }

class ReadingGoal extends Equatable {
  /// Nombre de Hizb à atteindre (1 Juz = 2 Hizb)
  final int targetHizb;
  final ReadingGoalPeriod period;

  const ReadingGoal({
    required this.targetHizb,
    this.period = ReadingGoalPeriod.daily,
  });

  bool get isEmpty => targetHizb <= 0;

  /// Libellé court : "2 Hizb/jour" ou "4 Hizb/semaine"
  String toShortLabel() {
    if (targetHizb <= 0) return '';
    return period == ReadingGoalPeriod.daily
        ? '$targetHizb Hizb/jour'
        : '$targetHizb Hizb/semaine';
  }

  Map<String, dynamic> toMap() => {
    'targetHizb': targetHizb,
    'period': period.name,
  };

  factory ReadingGoal.fromMap(Map<String, dynamic> m) => ReadingGoal(
    targetHizb: m['targetHizb'] as int? ?? 0,
    period:
        m['period'] == 'weekly'
            ? ReadingGoalPeriod.weekly
            : ReadingGoalPeriod.daily,
  );

  @override
  List<Object?> get props => [targetHizb, period];
}
