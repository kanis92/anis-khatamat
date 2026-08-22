import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_quran/src/app_bloc.dart';
import 'package:flutter_quran/src/utils/preferences/preferences_utils.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    PreferencesUtils().preferences = await SharedPreferences.getInstance();
    await AppBloc.resetForTesting();
  });

  tearDown(() => AppBloc.resetForTesting());

  testWidgets('BlocProvider.value ne ferme pas les Cubits au dispose écran',
      (tester) async {
    final quran = AppBloc.ensureQuranCubit();
    final bookmarks = AppBloc.ensureBookmarksCubit();

    await tester.pumpWidget(
      MaterialApp(
        home: MultiBlocProvider(
          providers: AppBloc.providers,
          child: const Scaffold(body: Text('Mushaf')),
        ),
      ),
    );
    await tester.pumpWidget(const MaterialApp(home: SizedBox.shrink()));
    await tester.pump();

    expect(identical(AppBloc.ensureQuranCubit(), quran), isTrue);
    expect(identical(AppBloc.ensureBookmarksCubit(), bookmarks), isTrue);
    expect(quran.isClosed, isFalse);
    expect(bookmarks.isClosed, isFalse);
  });
}
