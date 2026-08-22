import 'khatma_with_status.dart';

/// Réservation active de l'utilisateur sur une Khatma (v1 map ou v2 sous-collection).
class UserKhatmaReservationInfo {
  final String khatmaId;
  final int hizbNumber;
  final DateTime? reservedAt;
  final bool inProgress;

  const UserKhatmaReservationInfo({
    required this.khatmaId,
    required this.hizbNumber,
    this.reservedAt,
    this.inProgress = false,
  });
}

/// Résumé chiffré affichable sur le Home (données réelles uniquement).
class HomeDashboardSummary {
  final int activeCount;
  final int completedCount;
  final int userCompletedHizb;

  const HomeDashboardSummary({
    required this.activeCount,
    required this.completedCount,
    required this.userCompletedHizb,
  });

  static const empty = HomeDashboardSummary(
    activeCount: 0,
    completedCount: 0,
    userCompletedHizb: 0,
  );
}

/// Khatma principale à reprendre + métriques affichables.
class PrimaryKhatmaHighlight {
  final KhatmaWithStatus status;
  final int globalCompletedHizb;
  final int globalPercent;
  final int? userPersonalCompleted;
  final UserKhatmaReservationInfo? userReservation;
  final int participantCount;

  const PrimaryKhatmaHighlight({
    required this.status,
    required this.globalCompletedHizb,
    required this.globalPercent,
    this.userPersonalCompleted,
    this.userReservation,
    required this.participantCount,
  });
}

/// Dernière activité utilisateur (source locale/cloud selon disponibilité).
class HomeLastActivity {
  final String label;
  final DateTime at;

  const HomeLastActivity({required this.label, required this.at});
}

/// État agrégé du dashboard Home Khatamat.
class HomeDashboardState {
  final List<KhatmaWithStatus> activeKhatmas;
  final List<KhatmaWithStatus> completedKhatmas;
  final PrimaryKhatmaHighlight? primary;
  final List<KhatmaWithStatus> collectiveActive;
  final HomeDashboardSummary summary;
  final HomeLastActivity? lastActivity;

  const HomeDashboardState({
    required this.activeKhatmas,
    required this.completedKhatmas,
    this.primary,
    this.collectiveActive = const [],
    required this.summary,
    this.lastActivity,
  });

  bool get isEmpty => activeKhatmas.isEmpty && completedKhatmas.isEmpty;

  static const empty = HomeDashboardState(
    activeKhatmas: [],
    completedKhatmas: [],
    summary: HomeDashboardSummary.empty,
  );
}
