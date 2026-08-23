import 'package:flutter_test/flutter_test.dart';

import 'package:anis_khatamat/core/services/khatma_link_service.dart';

void main() {
  group('F5 — /join/:id parsing', () {
    test('normalizeJoinKhatmaId accepte un identifiant valide', () {
      expect(KhatmaLinkService.normalizeJoinKhatmaId('ABC123'), 'ABC123');
      expect(KhatmaLinkService.normalizeJoinKhatmaId('  xyz  '), 'xyz');
    });

    test('joinPath et joinUrl PATH canoniques', () {
      expect(KhatmaLinkService.joinPath('abc123'), '/join/abc123');
      expect(
        KhatmaLinkService.joinUrl('abc123'),
        'https://anis-437c3.web.app/join/abc123',
      );
    });

    test('parseJoinKhatmaIdFromUri — PATH URL', () {
      final uri = Uri.parse('https://example.com/join/khatma-42');
      expect(KhatmaLinkService.parseJoinKhatmaIdFromUri(uri), 'khatma-42');
    });

    test('parseJoinKhatmaIdFromUri — legacy hash URL', () {
      final uri = Uri.parse('https://example.com/#/join/legacy-id');
      expect(KhatmaLinkService.parseJoinKhatmaIdFromUri(uri), 'legacy-id');
    });
  });

  group('F6 — join ID malformé rejeté', () {
    test('normalizeJoinKhatmaId rejette vide, slash et espaces', () {
      expect(KhatmaLinkService.normalizeJoinKhatmaId(''), isNull);
      expect(KhatmaLinkService.normalizeJoinKhatmaId('   '), isNull);
      expect(KhatmaLinkService.normalizeJoinKhatmaId('bad/id'), isNull);
      expect(KhatmaLinkService.normalizeJoinKhatmaId('has space'), isNull);
      expect(KhatmaLinkService.normalizeJoinKhatmaId(null), isNull);
    });
  });
}
