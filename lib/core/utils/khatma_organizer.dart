import '../models/khatma.dart';

/// Créateur / organisateur de la Khatma (aligné sur l’API `isOrganizer`).
bool isKhatmaOrganizer(
  Khatma khatma,
  String participantId, {
  String? authUid,
}) {
  if (khatma.createdBy.isEmpty || participantId.isEmpty) return false;
  if (participantId == 'demo') return false;
  final creator = khatma.createdBy;
  if (creator == participantId ||
      creator.toLowerCase() == participantId.toLowerCase()) {
    return true;
  }
  final uid = authUid?.trim();
  if (uid != null && uid.isNotEmpty && creator == uid) {
    return true;
  }
  return false;
}
