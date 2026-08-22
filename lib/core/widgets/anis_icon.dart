import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../theme/app_theme.dart';

/// Icônes personnalisées ANIS — système unifié
/// Style : stroke 1.6, round caps, currentColor (teintable)
enum AnisIconType {
  mihrab,
  bookOpen,
  starDiamond,
  geometric,
  home,
  khatma,
  calendar,
  chart,
  training,
  bell,
  bookmark,
  user,
}

/// Widget affichant une icône ANIS (SVG) avec teinte couleur
class AnisIcon extends StatelessWidget {
  final AnisIconType type;
  final double size;
  final Color? color;

  const AnisIcon({
    super.key,
    required this.type,
    this.size = 32,
    this.color,
  });

  String get _assetPath {
    switch (type) {
      case AnisIconType.mihrab:
        return 'assets/icons/icon_horaire.svg';
      case AnisIconType.bookOpen:
        return 'assets/icons/icon_book_open.svg';
      case AnisIconType.starDiamond:
        return 'assets/icons/icon_star_diamond.svg';
      case AnisIconType.geometric:
        return 'assets/icons/icon_geometric.svg';
      case AnisIconType.home:
        return 'assets/icons/icon_home.svg';
      case AnisIconType.khatma:
        return 'assets/icons/icon_khatma.svg';
      case AnisIconType.calendar:
        return 'assets/icons/icon_calendar.svg';
      case AnisIconType.chart:
        return 'assets/icons/icon_chart.svg';
      case AnisIconType.training:
        return 'assets/icons/icon_training.svg';
      case AnisIconType.bell:
        return 'assets/icons/icon_bell.svg';
      case AnisIconType.bookmark:
        return 'assets/icons/icon_bookmark_filled.svg';
      case AnisIconType.user:
        return 'assets/icons/icon_user_filled.svg';
    }
  }

  @override
  Widget build(BuildContext context) {
    if (type == AnisIconType.mihrab) {
      return SvgPicture.asset(
        'assets/icons/icon_horaire.svg',
        width: size,
        height: size,
        fit: BoxFit.cover,
      );
    }
    final c = color ?? AppTheme.accentGold;
    return SvgPicture.asset(
      _assetPath,
      width: size,
      height: size,
      colorFilter: ColorFilter.mode(c, BlendMode.srcIn),
    );
  }
}
