import 'package:flutter_test/flutter_test.dart';

import 'package:anis_khatamat/core/services/khatma_link_service.dart';
import 'package:anis_khatamat/design_system/foundations/anis_responsive_layout.dart';

void main() {
  group('AnisResponsiveLayout breakpoints', () {
    test('COMPACT <= 599', () {
      expect(AnisResponsiveLayout.sizeOfWidth(390), AnisLayoutSize.compact);
      expect(AnisResponsiveLayout.sizeOfWidth(599), AnisLayoutSize.compact);
    });

    test('MEDIUM 600–1099', () {
      expect(AnisResponsiveLayout.sizeOfWidth(600), AnisLayoutSize.medium);
      expect(AnisResponsiveLayout.sizeOfWidth(768), AnisLayoutSize.medium);
      expect(AnisResponsiveLayout.sizeOfWidth(1099), AnisLayoutSize.medium);
    });

    test('EXPANDED >= 1100', () {
      expect(AnisResponsiveLayout.sizeOfWidth(1100), AnisLayoutSize.expanded);
      expect(AnisResponsiveLayout.sizeOfWidth(1440), AnisLayoutSize.expanded);
    });
  });

  group('Legacy join canonicalization', () {
    test('redirectPathForLegacyJoinUri — hash legacy', () {
      final uri = Uri.parse('https://example.com/#/join/abc123');
      expect(
        KhatmaLinkService.redirectPathForLegacyJoinUri(uri),
        '/join/abc123',
      );
    });

    test('redirectPathForLegacyJoinUri — PATH déjà canonique', () {
      final uri = Uri.parse('https://example.com/join/abc123');
      expect(KhatmaLinkService.redirectPathForLegacyJoinUri(uri), isNull);
    });

    test('redirectPathForLegacyJoinUri — hash malformé', () {
      final uri = Uri.parse('https://example.com/#/join/bad/id');
      expect(KhatmaLinkService.redirectPathForLegacyJoinUri(uri), isNull);
    });

    test('redirectPathForLegacyJoinUri — fragment sans join', () {
      final uri = Uri.parse('https://example.com/#/settings');
      expect(KhatmaLinkService.redirectPathForLegacyJoinUri(uri), isNull);
    });
  });
}
