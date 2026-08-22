import 'khatma.dart';

/// Khatma avec son statut (terminée ou en cours) et dernière activité
class KhatmaWithStatus {
  final Khatma khatma;
  final bool isCompleted;
  final DateTime? lastActivity;

  const KhatmaWithStatus({
    required this.khatma,
    required this.isCompleted,
    this.lastActivity,
  });
}
