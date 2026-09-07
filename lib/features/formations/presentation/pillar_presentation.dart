import 'package:flutter/widgets.dart';

import '../../../l10n/gen_l10n/app_localizations.dart';
import '../models/pedagogical_pillar.dart';

extension PedagogicalPillarL10n on PedagogicalPillar {
  String label(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    switch (this) {
      case PedagogicalPillar.foundationsPractice:
        return l10n.pillarFoundationsPractice;
      case PedagogicalPillar.quranReading:
        return l10n.pillarQuranReading;
      case PedagogicalPillar.prophetSeerahSunnah:
        return l10n.pillarProphetSeerahSunnah;
      case PedagogicalPillar.dailyLifeFrance:
        return l10n.pillarDailyLifeFrance;
      case PedagogicalPillar.characterEthics:
        return l10n.pillarCharacterEthics;
      case PedagogicalPillar.spiritualityHeart:
        return l10n.pillarSpiritualityHeart;
    }
  }
}
