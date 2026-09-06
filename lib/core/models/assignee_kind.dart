/// Destinataire sémantique d'une réservation Hizb.
enum AssigneeKind {
  self,
  offline,
  participant;

  /// Get the string value of this enum (same as name)
  String get value => name;

  static AssigneeKind? fromString(String? value) {
    if (value == null || value.isEmpty) return null;
    for (final kind in values) {
      if (kind.name == value) return kind;
    }
    return null;
  }
}
