import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('published catalogue query does not depend on createdAt or pillar indexes',
      () {
    final source = File(
      'lib/features/formations/repositories/formations_repository.dart',
    ).readAsStringSync();

    expect(
      source.contains(".where('isPublished', isEqualTo: true)"),
      isTrue,
    );
    expect(
      source.contains(".orderBy('createdAt'"),
      isFalse,
      reason: 'orderBy(createdAt) excludes docs without the field and needs a composite index',
    );
    expect(
      source.contains(".where('pillarId', isEqualTo: pillarId)"),
      isFalse,
      reason: 'pillar filtering must be local to avoid a composite index miss looking like empty content',
    );
  });
}
