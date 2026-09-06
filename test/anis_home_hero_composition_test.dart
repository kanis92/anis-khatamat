import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:anis_khatamat/core/ui/anis_hero_focal.dart';
import 'package:anis_khatamat/core/ui/anis_home_hero.dart';
import 'package:anis_khatamat/design_system/tokens/anis_colors.dart';
import 'package:anis_khatamat/design_system/tokens/anis_typography.dart';
import 'package:anis_khatamat/l10n/gen_l10n/app_localizations.dart';

Future<void> _savePng(WidgetTester tester, String name) async {
  final boundary = tester.renderObject<RenderRepaintBoundary>(
    find.byKey(const Key('hero-qa')),
  );
  final image = await boundary.toImage(pixelRatio: 2);
  final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
  final dir = Directory('qa_hero');
  if (!dir.existsSync()) dir.createSync();
  File('qa_hero/$name.png').writeAsBytesSync(bytes!.buffer.asUint8List());
}

Widget _host({
  required Locale locale,
  required Size size,
}) {
  return ProviderScope(
    child: MediaQuery(
      data: MediaQueryData(size: Size(size.width, 812)),
      child: MaterialApp(
        theme: ThemeData(
          useMaterial3: true,
          extensions: [
            AnisColors.light(),
            AnisTypography.fromResolver(
              AnisTypography.systemFontResolver,
              AnisColors.light(),
            ),
          ],
        ),
        locale: locale,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: Center(
            child: SizedBox(
              width: size.width,
              height: 260,
              child: const RepaintBoundary(
                key: Key('hero-qa'),
                child: AnisHomeHero(
                  identity: null,
                  heroHeight: 260,
                  showChrome: false,
                ),
              ),
            ),
          ),
        ),
      ),
    ),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Arabic 375: logo left, salam right, no overflow', (tester) async {
    await tester.binding.setSurfaceSize(const Size(375, 812));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      _host(locale: const Locale('ar'), size: const Size(375, 260)),
    );
    await tester.runAsync(() async {
      final ctx = tester.element(find.byType(AnisHomeHero));
      await precacheImage(const AssetImage(kAnisHeroAsset), ctx);
    });
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    expect(tester.takeException(), isNull);
    expect(find.text('السلام عليكم'), findsOneWidget);
    expect(AnisHeroFocal.usesSplitComposition('ar'), isTrue);

    final salam = tester.getRect(find.text('السلام عليكم'));
    expect(salam.left, greaterThan(375 * 0.38));
    await tester.runAsync(() => _savePng(tester, 'hero_ar_375'));
  });

  testWidgets('Arabic iPhone-equivalent width: no overlap', (tester) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      _host(locale: const Locale('ar'), size: const Size(390, 260)),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));
    expect(tester.takeException(), isNull);
    expect(find.text('السلام عليكم'), findsOneWidget);
    final salam = tester.getRect(find.text('السلام عليكم'));
    expect(salam.left, greaterThan(390 * 0.38));
    await tester.runAsync(() => _savePng(tester, 'hero_ar_390'));
  });

  testWidgets('FR and EN keep cover composition', (tester) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      _host(locale: const Locale('fr'), size: const Size(390, 260)),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));
    expect(find.text('Assalamu alaykum'), findsOneWidget);
    await tester.runAsync(() => _savePng(tester, 'hero_fr_390'));

    await tester.pumpWidget(
      _host(locale: const Locale('en'), size: const Size(390, 260)),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));
    expect(find.text('Assalamu alaykum'), findsOneWidget);
    await tester.runAsync(() => _savePng(tester, 'hero_en_390'));
  });
}
