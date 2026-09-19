import '../../l10n/gen_l10n/app_localizations.dart';
import 'models/ayat_fadila_entry.dart';

extension AyatFadilaEntryL10n on AyatFadilaEntry {
  String title(AppLocalizations l10n) => switch (id) {
    'al_kursi' => l10n.ayatFadilaEntryAlKursiTitle,
    'al_ikhlas' => l10n.ayatFadilaEntryAlIkhlasTitle,
    'al_falaq_nas' => l10n.ayatFadilaEntryAlFalaqNasTitle,
    'baqarah_end' => l10n.ayatFadilaEntryBaqarahEndTitle,
    'rabbana' => l10n.ayatFadilaEntryRabbanaTitle,
    'mulk' => l10n.ayatFadilaEntryMulkTitle,
    'hashr' => l10n.ayatFadilaEntryHashrTitle,
    'salam' => l10n.ayatFadilaEntrySalamTitle,
    _ => id,
  };

  String virtue(AppLocalizations l10n) => switch (id) {
    'al_kursi' => l10n.ayatFadilaEntryAlKursiVirtue,
    'al_ikhlas' => l10n.ayatFadilaEntryAlIkhlasVirtue,
    'al_falaq_nas' => l10n.ayatFadilaEntryAlFalaqNasVirtue,
    'baqarah_end' => l10n.ayatFadilaEntryBaqarahEndVirtue,
    'rabbana' => l10n.ayatFadilaEntryRabbanaVirtue,
    'mulk' => l10n.ayatFadilaEntryMulkVirtue,
    'hashr' => l10n.ayatFadilaEntryHashrVirtue,
    'salam' => l10n.ayatFadilaEntrySalamVirtue,
    _ => '',
  };

  String referenceLabel(AppLocalizations l10n) => switch (id) {
    'al_kursi' => l10n.ayatFadilaEntryAlKursiRef,
    'al_ikhlas' => l10n.ayatFadilaEntryAlIkhlasRef,
    'al_falaq_nas' => l10n.ayatFadilaEntryAlFalaqNasRef,
    'baqarah_end' => l10n.ayatFadilaEntryBaqarahEndRef,
    'rabbana' => l10n.ayatFadilaEntryRabbanaRef,
    'mulk' => l10n.ayatFadilaEntryMulkRef,
    'hashr' => l10n.ayatFadilaEntryHashrRef,
    'salam' => l10n.ayatFadilaEntrySalamRef,
    _ => '',
  };
}

extension AyatFadilaCategoryL10n on AyatFadilaCategory {
  String label(AppLocalizations l10n) => switch (this) {
    AyatFadilaCategory.protection => l10n.ayatFadilaCategoryProtection,
    AyatFadilaCategory.daily => l10n.ayatFadilaCategoryDaily,
    AyatFadilaCategory.praise => l10n.ayatFadilaCategoryPraise,
  };
}
