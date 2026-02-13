import 'package:equatable/equatable.dart';

/// Représente un Hizb du Coran (1/60)
class Hizb extends Equatable {
  final int number;
  final String surahRange;
  final String? assignedTo; // Pour Khatma de groupe : email ou nom du membre

  const Hizb({
    required this.number,
    required this.surahRange,
    this.assignedTo,
  });

  Hizb copyWith({int? number, String? surahRange, String? assignedTo}) {
    return Hizb(
      number: number ?? this.number,
      surahRange: surahRange ?? this.surahRange,
      assignedTo: assignedTo ?? this.assignedTo,
    );
  }

  @override
  List<Object?> get props => [number, surahRange, assignedTo];
}
