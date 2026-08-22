import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:anis_khatamat/core/models/home_dashboard_state.dart';
import 'package:anis_khatamat/core/providers/auth_provider.dart';
import 'package:anis_khatamat/core/providers/home_dashboard_provider.dart';

void main() {
  group('homeDashboardProvider demo contract', () {
    test(
      'demo session resolves empty home without remote dependency',
      () async {
        final container = ProviderContainer(
          overrides: [demoModeProvider.overrideWith((ref) => true)],
        );
        addTearDown(container.dispose);

        final state = await container.read(homeDashboardProvider.future);

        expect(state, HomeDashboardState.empty);
        expect(state.isEmpty, isTrue);
      },
    );

    test('non-demo empty identity still resolves locally', () async {
      final container = ProviderContainer(
        overrides: [demoModeProvider.overrideWith((ref) => false)],
      );
      addTearDown(container.dispose);

      final state = await container.read(homeDashboardProvider.future);

      expect(state, HomeDashboardState.empty);
    });
  });
}
