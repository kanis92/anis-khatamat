import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  const formationUiPaths = [
    'lib/screens/training_screen.dart',
    'lib/screens/course_detail_screen.dart',
    'lib/features/formations/presentation/formations_state_views.dart',
  ];

  test('Formation UI never reads AsyncError.value', () {
    for (final path in formationUiPaths) {
      final source = File(path).readAsStringSync();
      expect(
        source.contains('.value!'),
        isFalse,
        reason: '$path still has a bang on .value',
      );
    }
  });

  test('initializing Formation streams do not complete empty', () {
    final source = File(
      'lib/features/formations/providers/formations_access.dart',
    ).readAsStringSync();
    expect(source.contains('return const Stream.empty()'), isFalse);
    expect(source.contains('return Stream.empty()'), isFalse);
    expect(source.contains('_neverEmit'), isTrue);
  });
}
