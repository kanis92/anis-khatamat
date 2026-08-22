/// Identifiants immuables des référentiels Hizb compris par cette version.
///
/// Ajouter une nouvelle table exige un nouvel identifiant : le contenu associé
/// à un identifiant publié ne doit jamais être modifié silencieusement.
class HizbDefinitions {
  HizbDefinitions._();

  static const String quranFoundationHafsV1 = 'quran_foundation_hafs_v1';
  static const Set<String> supported = {quranFoundationHafsV1};

  static bool isSupported(String? definitionId) =>
      definitionId != null && supported.contains(definitionId);

  static void requireSupported(String? definitionId) {
    if (!isSupported(definitionId)) {
      throw UnsupportedHizbDefinitionException(definitionId);
    }
  }
}

class UnsupportedHizbDefinitionException implements Exception {
  const UnsupportedHizbDefinitionException(this.definitionId);

  final String? definitionId;

  @override
  String toString() => definitionId == null || definitionId!.isEmpty
      ? 'Khatma sans hizbDefinitionId explicite'
      : 'Référentiel Hizb non pris en charge: $definitionId';
}
