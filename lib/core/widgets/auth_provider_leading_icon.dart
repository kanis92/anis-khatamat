import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

enum AuthProviderLeadingKind { google, apple }

/// Icône Google / Apple pour les boutons de connexion sociale.
class AuthProviderLeadingIcon extends StatelessWidget {
  const AuthProviderLeadingIcon({
    super.key,
    required this.kind,
    this.monochromeLight = false,
  });

  final AuthProviderLeadingKind kind;
  final bool monochromeLight;

  @override
  Widget build(BuildContext context) {
    return switch (kind) {
      AuthProviderLeadingKind.google => SvgPicture.asset(
          'assets/icons/google_logo.svg',
          width: 20,
          height: 20,
        ),
      AuthProviderLeadingKind.apple => SvgPicture.asset(
          'assets/icons/apple_logo.svg',
          width: 18,
          height: 20,
          colorFilter: monochromeLight
              ? const ColorFilter.mode(Colors.white, BlendMode.srcIn)
              : const ColorFilter.mode(Colors.black, BlendMode.srcIn),
        ),
    };
  }
}
