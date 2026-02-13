import 'package:flutter/material.dart';

import '../../l10n/gen_l10n/app_localizations.dart';

/// Extension pour accéder facilement aux traductions
extension L10nExtension on BuildContext {
  AppLocalizations get l10n => AppLocalizations.of(this)!;
}
