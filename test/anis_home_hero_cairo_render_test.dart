import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/rendering.dart';

import 'package:anis_khatamat/core/ui/anis_home_hero.dart';
import 'package:anis_khatamat/design_system/tokens/anis_colors.dart';
import 'package:anis_khatamat/design_system/tokens/anis_typography.dart';
import 'package:anis_khatamat/l10n/gen_l10n/app_localizations.dart';

const _cairoPath = '/Users/jaouad/Library/Fonts/Cairo-Regular.ttf';

Future<void> _loadCairo() async {
  final file = File(_cairoPath);
  if (!file.existsSync()) {
    return;
  }
  final bytes = await file.readAsBytes();
  final loader = FontLoader('Cairo');
  loader.addFont(Future.value(ByteData.view(bytes.buffer)));
  await loader.load();
}

TextStyle _cairoResolver({
  required double fontSize,
  required FontWeight fontWeight,
  required Color color,
  required double height,
}) =>
    TextStyle(
      fontFamily: 'Cairo',
      fontSize: fontSize,
      fontWeight: fontWeight,
      color: color,
      height: height,
    );

Future<void> _savePng(WidgetTester tester, String name) async {
  final boundary = tester.renderObject<RenderRepaintBoundary>(
    find.byKey(const Key('hero-cairo')),
  );
  final image = await boundary.toImage(pixelRatio: 2);
  final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
  final dir = Directory('qa_hero');
  if (!dir.existsSync()) dir.createSync();
  File('qa_hero/$name.png').writeAsBytesSync(bytes!.buffer.asUint8List());
}

Widget _host({required Locale locale, required double width}) {
  return ProviderScope(
    child: MediaQuery(
      data: MediaQueryData(size: Size(width, 844)),
      child: MaterialApp(
        theme: ThemeData(
          useMaterial3: true,
          extensions: [
            AnisColors.light(),
            AnisTypography.fromResolver(_cairoResolver, AnisColors.light()),
          ],
        ),
        locale: locale,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: SizedBox(
            width: width,
            height: 260,
            child: const RepaintBoundary(
              key: Key('hero-cairo'),
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
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final hasCairo = File(_cairoPath).existsSync();

  setUpAll(() async {
    if (hasCairo) {
      await _loadCairo();
    }
  });

  testWidgets('Cairo AR 390 split hero', (tester) async {
    if (!hasCairo) {
      return;
    }
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(_host(locale: const Locale('ar'), width: 390));
    await tester.runAsync(() async {
      final ctx = tester.element(find.byType(AnisHomeHero));
      await precacheImage(const AssetImage(kAnisHeroAsset), ctx);
    });
    await tester.pump();
    expect(find.text('السلام عليكم'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.runAsync(() => _savePng(tester, 'hero_ar_390_cairo'));
  });

  testWidgets('Cairo FR/EN 390 cover hero', (tester) async {
    if (!hasCairo) {
      return;
    }
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(_host(locale: const Locale('fr'), width: 390));
    await tester.pump();
    expect(find.text('Assalamu alaykum'), findsOneWidget);
    await tester.runAsync(() => _savePng(tester, 'hero_fr_390_cairo'));

    await tester.pumpWidget(_host(locale: const Locale('en'), width: 390));
    await tester.pump();
    expect(find.text('Assalamu alaykum'), findsOneWidget);
    await tester.runAsync(() => _savePng(tester, 'hero_en_390_cairo'));
  });
}
