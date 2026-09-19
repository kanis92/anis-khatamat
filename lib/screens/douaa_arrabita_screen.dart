import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../core/extensions/l10n_extensions.dart';
import '../core/widgets/anis_icon.dart';
import '../design_system/anis_design_system.dart';

/// Douaa Arrabita — invocations (contenu à enrichir).
class DouaaArrabitaScreen extends StatelessWidget {
  const DouaaArrabitaScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colors = context.anisColors;

    return Scaffold(
      backgroundColor: colors.surfaceBase,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AnisPageHeader(
            title: l10n.douaaArrabitaTitle,
            eyebrow: l10n.douaaArrabitaEyebrow,
            showSignature: true,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_rounded),
              onPressed: () {
                if (context.canPop()) {
                  context.pop();
                } else {
                  context.go('/');
                }
              },
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsetsDirectional.all(AnisSpacing.page),
              child: AnisEmptyState(
                title: l10n.douaaArrabitaTitle,
                message: l10n.douaaArrabitaIntro,
                glyph: AnisGlyph.anis(
                  AnisIconType.mihrab,
                  size: AnisIconSize.xl,
                  color: colors.actionPrimary,
                ),
                showSignature: false,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
