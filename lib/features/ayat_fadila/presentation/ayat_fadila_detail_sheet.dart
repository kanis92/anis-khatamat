import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../design_system/anis_design_system.dart';
import '../../../l10n/gen_l10n/app_localizations.dart';
import '../ayat_fadila_l10n.dart';
import '../models/ayat_fadila_entry.dart';

Future<void> showAyatFadilaDetailSheet(
  BuildContext context, {
  required AyatFadilaEntry entry,
  required AppLocalizations l10n,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: context.anisColors.surfaceElevated,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (context) {
      final colors = context.anisColors;
      final text = context.anisText;

      return Padding(
        padding: EdgeInsetsDirectional.fromSTEB(
          AnisSpacing.page,
          AnisSpacing.lg,
          AnisSpacing.page,
          MediaQuery.viewInsetsOf(context).bottom + AnisSpacing.xl,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: colors.borderStrong,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: AnisSpacing.lg),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    entry.title(l10n),
                    style: text.title.copyWith(color: colors.textPrimary),
                  ),
                ),
                AnisBadge(
                  label: entry.referenceLabel(l10n),
                  tone: AnisBadgeTone.active,
                ),
              ],
            ),
            const SizedBox(height: AnisSpacing.md),
            Text(
              l10n.ayatFadilaDetailVirtueLabel,
              style: text.caption.copyWith(
                fontWeight: FontWeight.w600,
                color: colors.accentGoldText,
              ),
            ),
            const SizedBox(height: AnisSpacing.xxs),
            Text(
              entry.virtue(l10n),
              style: text.bodySecondary.copyWith(height: 1.45),
            ),
            const SizedBox(height: AnisSpacing.lg),
            Text(
              l10n.ayatFadilaReaderSoon,
              style: text.caption.copyWith(color: colors.textSecondary),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AnisSpacing.lg),
            AnisPrimaryButton(
              label: l10n.ayatFadilaOpenInMushaf,
              onPressed: () {
                Navigator.of(context).pop();
                context.push(
                  '/mushaf/hafs',
                  extra: {
                    'surah': entry.openSurah,
                    'verse': entry.openVerse,
                  },
                );
              },
            ),
          ],
        ),
      );
    },
  );
}
