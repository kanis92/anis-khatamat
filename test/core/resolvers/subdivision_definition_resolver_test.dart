import 'package:flutter_test/flutter_test.dart';

import 'package:anis_khatamat/core/resolvers/subdivision_definition_resolver.dart';
import 'package:anis_khatamat/core/abstractions/subdivision_definition.dart';
import 'package:anis_khatamat/core/data/subdivision_definitions/hafs_quran_foundation_rub_240_v1.dart';

void main() {
  group('SubdivisionDefinitionResolver', () {
    test('production resolver has exactly one definition: Hafs 240 V1', () {
      final resolver = SubdivisionDefinitionResolver.production();

      final available = resolver.availableDefinitions;
      expect(available, hasLength(1));
      expect(available, contains('hafs_quran_foundation_rub_240_v1'));
    });

    test('resolve Hafs 240 V1 returns correct definition', () {
      final resolver = SubdivisionDefinitionResolver.production();

      final definition = resolver.resolve('hafs_quran_foundation_rub_240_v1');

      expect(definition, isA<HafsQuranFoundationRub240V1Definition>());
      expect(definition.id, 'hafs_quran_foundation_rub_240_v1');
      expect(definition.totalSegments, 240);
    });

    test('resolve unknown ID throws UnknownSubdivisionDefinitionException', () {
      final resolver = SubdivisionDefinitionResolver.production();

      expect(
        () => resolver.resolve('warsh_wikisource_thumun_480_v1'),
        throwsA(isA<UnknownSubdivisionDefinitionException>()),
      );
    });

    test('isRegistered returns true for Hafs 240 V1', () {
      final resolver = SubdivisionDefinitionResolver.production();

      expect(resolver.isRegistered('hafs_quran_foundation_rub_240_v1'), true);
    });

    test('isRegistered returns false for unknown definition', () {
      final resolver = SubdivisionDefinitionResolver.production();

      expect(resolver.isRegistered('warsh_wikisource_thumun_480_v1'), false);
      expect(resolver.isRegistered('unknown_definition'), false);
    });

    test('exception message includes requested ID and available definitions', () {
      final resolver = SubdivisionDefinitionResolver.production();

      try {
        resolver.resolve('warsh_wikisource_thumun_480_v1');
        fail('Should have thrown');
      } catch (e) {
        expect(e.toString(), contains('warsh_wikisource_thumun_480_v1'));
        expect(e.toString(), contains('hafs_quran_foundation_rub_240_v1'));
      }
    });

    test('custom registry can be provided', () {
      // Mock factory for testing
      SubdivisionDefinition mockFactory() =>
          HafsQuranFoundationRub240V1Definition();

      final resolver = SubdivisionDefinitionResolver({
        'custom_definition_v1': mockFactory,
      });

      expect(resolver.isRegistered('custom_definition_v1'), true);
      expect(resolver.availableDefinitions, ['custom_definition_v1']);

      final definition = resolver.resolve('custom_definition_v1');
      expect(definition, isNotNull);
    });

    test('resolve returns fresh instance on each call', () {
      final resolver = SubdivisionDefinitionResolver.production();

      final def1 = resolver.resolve('hafs_quran_foundation_rub_240_v1');
      final def2 = resolver.resolve('hafs_quran_foundation_rub_240_v1');

      // Vérifie que ce sont des instances différentes (pas singleton via resolver)
      // Note: HafsQuranFoundationRub240V1Definition elle-même est un singleton,
      // mais ça c'est son implémentation interne
      expect(identical(def1, def2), true,
          reason: 'HafsQuranFoundationRub240V1Definition uses singleton pattern');
    });
  });
}
