import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../extensions/l10n_extensions.dart';
import '../providers/home_dashboard_provider.dart';
import '../providers/prayer_times_provider.dart';
import '../utils/auth_diag.dart';
import '../utils/duration_formatter.dart';
import '../widgets/anis_icon.dart';
import '../../design_system/anis_design_system.dart';
import 'anis_hero_focal.dart';

const kAnisHeroAsset = 'assets/images/anis_header.png';

/// Hero d'accueil.
///
/// FR/EN : composition plein cadre validée (sujet centré).
/// AR : composition à deux régions physiques — logo à GAUCHE, salut à DROITE.
/// Les régions sont des panes séparés : elles ne peuvent pas se chevaucher.
class AnisHomeHero extends StatelessWidget {
  const AnisHomeHero({
    super.key,
    required this.identity,
    this.heroHeight,
    this.showChrome = true,
  });

  final ParticipantIdentity? identity;
  final double? heroHeight;
  final bool showChrome;

  @override
  Widget build(BuildContext context) {
    final locale = Localizations.localeOf(context);
    final height = heroHeight ??
        (MediaQuery.sizeOf(context).height * 0.34).clamp(228.0, 320.0);
    final isArabic = locale.languageCode == 'ar';

    return SizedBox(
      height: height,
      width: double.infinity,
      child: isArabic
          ? _ArabicSplitHero(identity: identity, showChrome: showChrome)
          : _LtrCoverHero(identity: identity, showChrome: showChrome),
    );
  }
}

/// AR : Row LTR physique. Gauche = marque ANIS. Droite = salut / date / prière.
class _ArabicSplitHero extends StatelessWidget {
  const _ArabicSplitHero({
    required this.identity,
    required this.showChrome,
  });

  final ParticipantIdentity? identity;
  final bool showChrome;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: const Color(0xFF0B2A24),
      child: Stack(
        fit: StackFit.expand,
        children: [
          Row(
            textDirection: ui.TextDirection.ltr,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Expanded(
                flex: AnisHeroFocal.arabicLogoFlex,
                child: ClipRect(
                  child: ColoredBox(
                    color: Color(0xFF0B2A24),
                    child: Image(
                      image: AssetImage(kAnisHeroAsset),
                      fit: BoxFit.cover,
                      alignment: Alignment.center,
                      semanticLabel: 'ANIS',
                    ),
                  ),
                ),
              ),
              Expanded(
                flex: AnisHeroFocal.arabicCopyFlex,
                child: DecoratedBox(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                      colors: [
                        Color(0xCC0B2A24),
                        Color(0xF20B2A24),
                      ],
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(12, 56, 16, 20),
                    child: _HeroCopy(
                      textAlign: TextAlign.right,
                      crossAxisAlignment: CrossAxisAlignment.end,
                    ),
                  ),
                ),
              ),
            ],
          ),
          if (showChrome)
            SafeArea(
              bottom: false,
              child: Align(
                alignment: Alignment.topRight,
                child: _HeroChrome(identity: identity),
              ),
            ),
        ],
      ),
    );
  }
}

class _LtrCoverHero extends StatelessWidget {
  const _LtrCoverHero({
    required this.identity,
    required this.showChrome,
  });

  final ParticipantIdentity? identity;
  final bool showChrome;

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        const Image(
          image: AssetImage(kAnisHeroAsset),
          fit: BoxFit.cover,
          alignment: AnisHeroFocal.ltr,
          semanticLabel: 'ANIS',
        ),
        const DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Color(0x2E000000),
                Color(0x14000000),
                Color(0x85000000),
              ],
              stops: [0.0, 0.45, 1.0],
            ),
          ),
        ),
        SafeArea(
          bottom: false,
          child: Padding(
            padding: const EdgeInsetsDirectional.fromSTEB(
              AnisSpacing.page,
              AnisSpacing.sm,
              AnisSpacing.page,
              AnisSpacing.lg,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (showChrome) _HeroChrome(identity: identity),
                const Spacer(),
                const _HeroCopy(
                  textAlign: TextAlign.start,
                  crossAxisAlignment: CrossAxisAlignment.start,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _HeroChrome extends StatelessWidget {
  const _HeroChrome({required this.identity});

  final ParticipantIdentity? identity;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final name = identity?.displayLabel ?? l10n.guestBadge;
    final initial = identity?.displayInitial ?? '?';

    return Row(
      children: [
        const Spacer(),
        IconButton(
          tooltip: l10n.notifications,
          onPressed: () => context.go('/notifications'),
          icon: AnisIcon(
            type: AnisIconType.bell,
            size: AnisIconSize.lg,
            color: Colors.white,
          ),
        ),
        const SizedBox(width: AnisSpacing.sm),
        Semantics(
          label: name,
          button: true,
          child: InkWell(
            onTap: () => context.go('/settings'),
            customBorder: const CircleBorder(),
            child: AnisAvatar(
              initial: initial,
              semanticLabel: name,
            ),
          ),
        ),
      ],
    );
  }
}

class _HeroCopy extends StatelessWidget {
  const _HeroCopy({
    required this.textAlign,
    required this.crossAxisAlignment,
  });

  final TextAlign textAlign;
  final CrossAxisAlignment crossAxisAlignment;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final text = context.anisText;
    final hijri = formatHijriDate();
    final time = DateFormat.Hm().format(DateTime.now());

    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      crossAxisAlignment: crossAxisAlignment,
      children: [
        Text(
          l10n.welcomeGreeting,
          textAlign: textAlign,
          style: text.titleLarge.copyWith(
            color: Colors.white,
            shadows: const [
              Shadow(
                color: Color(0x66000000),
                blurRadius: 8,
                offset: Offset(0, 2),
              ),
            ],
          ),
        ),
        const SizedBox(height: AnisSpacing.xs),
        Text(
          '$hijri  •  $time',
          textAlign: textAlign,
          style: text.bodySecondary.copyWith(
            color: Colors.white.withValues(alpha: 0.92),
            shadows: const [
              Shadow(color: Color(0x55000000), blurRadius: 6),
            ],
          ),
        ),
        const _HeroPrayerChip(),
      ],
    );
  }
}

class _HeroPrayerChip extends ConsumerWidget {
  const _HeroPrayerChip();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final prayer = ref.watch(nextPrayerProvider);
    if (prayer == null) return const SizedBox.shrink();

    final l10n = context.l10n;
    final prayerName = switch (prayer.prayerKey) {
      'fajr' => l10n.prayerFajr,
      'dhuhr' => l10n.prayerDhuhr,
      'asr' => l10n.prayerAsr,
      'maghrib' => l10n.prayerMaghrib,
      'isha' => l10n.prayerIsha,
      _ => prayer.prayerKey,
    };
    final durationFormatted = DurationFormatter.format(prayer.duration, context);
    final timeRemaining = l10n.timeIn(durationFormatted);

    return Padding(
      padding: const EdgeInsetsDirectional.only(top: AnisSpacing.sm),
      child: AnisBadge(
        label: l10n.homePrayerPill(prayerName, timeRemaining),
        tone: AnisBadgeTone.active,
        anisIcon: AnisIconType.mihrab,
        semanticLabel: l10n.homeNextPrayerSemantic(prayerName, timeRemaining),
      ),
    );
  }
}
