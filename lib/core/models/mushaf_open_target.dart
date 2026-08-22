import 'package:flutter/foundation.dart';

/// Cible d'ouverture d'un lecteur Mushaf, quel que soit le point d'entrée
/// (route `extra`, query string d'un deep link, notification).
///
/// Elle transporte le numéro de Hizb tel quel : la conversion vers une page
/// reste la responsabilité exclusive de `HizbNavigationService`.
@immutable
class MushafOpenTarget {
  final int? surah;
  final int? verse;
  final int? page;

  /// Hizb à ouvrir (1–60). Prioritaire sur [page] et [surah].
  final int? hizb;
  /// Référentiel obligatoire lorsque l'ouverture provient d'une Khatma.
  final String? hizbDefinitionId;

  /// Position enregistrée pour « Continuer ». N'a de sens qu'avec [hizb] :
  /// elle n'est suivie que si elle appartient bien à ce Hizb.
  final int? resumePage;

  const MushafOpenTarget({
    this.surah,
    this.verse,
    this.page,
    this.hizb,
    this.hizbDefinitionId,
    this.resumePage,
  });

  /// Construit la cible depuis `state.extra` et l'URI de la route.
  /// `extra` a priorité ; la query string permet les deep links
  /// (`/mushaf/hafs?hizb=44`).
  factory MushafOpenTarget.fromRoute(Object? extra, Uri uri) {
    final map = extra is Map<String, dynamic> ? extra : const <String, dynamic>{};
    final q = uri.queryParameters;

    int? read(String key) => _asInt(map[key]) ?? _asInt(q[key]);

    final hizb = read('hizb');
    return MushafOpenTarget(
      surah: read('surah'),
      verse: read('verse'),
      page: read('page'),
      hizb: (hizb != null && hizb >= 1 && hizb <= 60) ? hizb : null,
      hizbDefinitionId:
          (map['hizbDefinitionId'] ?? q['hizbDefinitionId']) as String?,
      resumePage: read('resumePage'),
    );
  }

  static int? _asInt(Object? v) {
    if (v is int) return v;
    if (v is String) return int.tryParse(v);
    return null;
  }
}
