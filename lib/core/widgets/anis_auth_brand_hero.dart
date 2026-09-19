import 'package:flutter/material.dart';

const kAnisAuthHeroAsset = 'assets/branding/anis_login_hero.png';

/// Ratio [anis_login_hero.png] — 1269×413 px.
const kAnisAuthHeroAspectRatio = 1269 / 413;

/// Fond émeraude profond (#030E11) — bord source anis_header.
const kAnisAuthHeroEmeraldFill = Color(0xFF030E11);

/// Hero émeraude partagé (écran auth + login email).
class AnisAuthBrandHero extends StatelessWidget {
  const AnisAuthBrandHero({
    super.key,
    required this.height,
    this.compact = false,
  });

  final double height;
  final bool compact;

  static const double artworkBottomClearance = 34;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      child: ClipRect(
        child: ColoredBox(
          color: kAnisAuthHeroEmeraldFill,
          child: LayoutBuilder(
            builder: (context, constraints) {
              return Align(
                alignment: Alignment.bottomRight,
                child: Padding(
                  padding: EdgeInsetsDirectional.only(
                    end: compact ? 4 : 0,
                    bottom: artworkBottomClearance,
                  ),
                  child: SizedBox(
                    width: constraints.maxWidth,
                    child: AspectRatio(
                      aspectRatio: kAnisAuthHeroAspectRatio,
                      child: Image.asset(
                        kAnisAuthHeroAsset,
                        fit: BoxFit.contain,
                        alignment: Alignment.bottomRight,
                        filterQuality: FilterQuality.high,
                        semanticLabel: 'ANIS Khatamat',
                      ),
                    ),
                  ),
                ),
              );
            },
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
