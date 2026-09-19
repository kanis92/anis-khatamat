import 'package:flutter/material.dart';

const kAnisAuthHeroAsset = 'assets/branding/anis_login_hero.png';

/// Fond émeraude profond (#030E11) — bord source anis_header.
const kAnisAuthHeroEmeraldFill = Color(0xFF030E11);

/// Cadrage [anis_login_hero.png] (sujet ~62 % largeur, ancré bas) — plein cadre.
const kAnisAuthHeroCoverAlignment = Alignment(0.22, 1.0);

const kAnisAuthHeroCoverAlignmentCompact = Alignment(0.18, 1.0);

/// Hero émeraude partagé (écran auth + login email).
class AnisAuthBrandHero extends StatelessWidget {
  const AnisAuthBrandHero({
    super.key,
    required this.height,
    this.compact = false,
  });

  final double height;
  final bool compact;

  /// Dégage le Coran du chevauchement ivoire ([kAnisAuthSheetOverlap]).
  static const double artworkBottomClearance = 34;

  @override
  Widget build(BuildContext context) {
    final alignment =
        compact ? kAnisAuthHeroCoverAlignmentCompact : kAnisAuthHeroCoverAlignment;

    return SizedBox(
      height: height,
      width: double.infinity,
      child: ClipRect(
        child: ColoredBox(
          color: kAnisAuthHeroEmeraldFill,
          child: Padding(
            padding: const EdgeInsets.only(bottom: artworkBottomClearance),
            child: Image.asset(
              kAnisAuthHeroAsset,
              fit: BoxFit.cover,
              width: double.infinity,
              height: double.infinity,
              alignment: alignment,
              filterQuality: FilterQuality.high,
              semanticLabel: 'ANIS Khatamat',
            ),
          ),
        ),
      ),
    );
  }
}

/// Chevauchement standard feuille ivoire / hero.
const kAnisAuthSheetOverlap = 28.0;

/// Calcule la hauteur hero auth/login selon la taille écran.
double anisAuthHeroHeight(double screenHeight, {required bool compact}) {
  return (screenHeight * (compact ? 0.29 : 0.31)).clamp(
    compact ? 196.0 : 210.0,
    compact ? 248.0 : 278.0,
  );
}
