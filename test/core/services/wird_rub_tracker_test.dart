import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:anis_khatamat/core/services/wird_rub_tracker.dart';
import 'package:anis_khatamat/core/data/quran_subdivision_data.dart';

void main() {
  late WirdRubTracker tracker;
  const testUser = 'test@anis.ma';

  setUp(() {
    tracker = WirdRubTracker();
    SharedPreferences.setMockInitialValues({});
  });

  group('WirdRubTracker — Tracking canonique Rub\'', () {
    test('Resume à une page tardive ne donne aucun Rub\' historique', () async {
      // Ouvrir directement page 300 (sans séquence) ne marque aucun Rub'
      await tracker.savePositionOnly(testUser, 'hafs', 300);
      final count = await tracker.getUniqueRubsCompletedToday(testUser);
      expect(count, 0, reason: 'La reprise seule ne marque aucun Rub\'');
    });

    test('Tour de page séquentiel normal complète un Rub\'', () async {
      // Page 1 → Page 2 séquentiel
      // Dernier verset page 2 : Al-Baqarah 2:25 (selon quran_hafs.json)
      // Rub' 0 commence à 1:1, Rub' 1 commence à 2:26
      // Donc dernier verset 2:25 a franchi Rub' 0
      final completed = await tracker.recordSequentialPageTurn(
        testUser,
        'hafs',
        1,
        2,
        2, // surah
        27, // ayah
      );
      expect(completed, true);
      final count = await tracker.getUniqueRubsCompletedToday(testUser);
      expect(count, 1, reason: 'Tour séquentiel page 1→2 complète Rub\' 0');
    });

    test('Frontière Rub\' sur même page gérée au tour de page suivant', () async {
      // Si un Rub' commence au milieu d'une page, il n'est franchi
      // qu'au moment du tour de page qui emmène au-delà
      // 
      // Hizb 1 marqueurs réels :
      // - Marqueur 0 : 1:1 (début, 0 Rub' complété)
      // - Marqueur 1 : 2:26 (franchir = 1 Rub' complété)
      // - Marqueur 2 : 2:44 (franchir = 2 Rub' complétés)
      // - Marqueur 3 : 2:60 (franchir = 3 Rub' complétés)
      //
      // Tour 1→2 : dernier verset = 2:25, AVANT marqueur 1
      // On est après marqueur 0 mais pas encore après marqueur 1
      await tracker.recordSequentialPageTurn(testUser, 'hafs', 1, 2, 2, 25);
      expect(await tracker.getUniqueRubsCompletedToday(testUser), 0,
          reason: 'Marqueur 0 (1:1) est le début, pas une complétion');

      // Tour 2→3 : dernier verset = 2:43, APRÈS marqueur 1, AVANT marqueur 2
      await tracker.recordSequentialPageTurn(testUser, 'hafs', 2, 3, 2, 43);
      expect(await tracker.getUniqueRubsCompletedToday(testUser), 1,
          reason: 'Franchir marqueur 1 (2:26) = 1 Rub\' complété');
    });

    test('Navigation arrière / revisit ne donne aucun duplicate', () async {
      // Compléter 1 Rub' en franchissant le marqueur 1 (2:26)
      await tracker.recordSequentialPageTurn(testUser, 'hafs', 1, 2, 2, 27);
      expect(await tracker.getUniqueRubsCompletedToday(testUser), 1);

      // Retour arrière : page 2→1 (oldPage > newPage)
      // recordSequentialPageTurn refuse car toPage <= fromPage
      final backward = await tracker.recordSequentialPageTurn(
        testUser,
        'hafs',
        2,
        1,
        1,
        7,
      );
      expect(backward, false, reason: 'Navigation arrière refuse complétion');
      expect(await tracker.getUniqueRubsCompletedToday(testUser), 1);

      // Revisiter page 2 : sauter de 1 à 2 (non-séquentiel depuis position actuelle 1)
      // Doit utiliser savePositionOnly au lieu de recordSequentialPageTurn
      await tracker.savePositionOnly(testUser, 'hafs', 2);
      expect(await tracker.getUniqueRubsCompletedToday(testUser), 1);
    });

    test('Saut > 1 page ne donne aucune complétion', () async {
      // Sauter de page 1 à page 10 (non-séquentiel)
      final jump = await tracker.recordSequentialPageTurn(
        testUser,
        'hafs',
        1,
        10,
        2,
        189,
      );
      expect(jump, false, reason: 'Saut > 1 page refuse complétion');
      expect(await tracker.getUniqueRubsCompletedToday(testUser), 0);
    });

    test('Nisf = 2 Rub\', Hizb = 4 Rub\' (équivalence structurelle)', () async {
      // Lire séquentiellement jusqu'à compléter exactement 1 Nisf (2 Rub')
      // 
      // Hizb 1 marqueurs réels :
      // - Marqueur 0 : 1:1 (début)
      // - Marqueur 1 : 2:26 (franchir = 1 Rub' complété)
      // - Marqueur 2 : 2:44 (franchir = 2 Rub' complétés = 1 Nisf)
      // - Marqueur 3 : 2:60 (franchir = 3 Rub' complétés)
      
      // Tour 1→2 avec 2:27 : franchit marqueur 1 → 1 Rub' complété
      await tracker.recordSequentialPageTurn(testUser, 'hafs', 1, 2, 2, 27);
      expect(await tracker.getUniqueRubsCompletedToday(testUser), 1);

      // Tour 2→3 avec 2:45 : franchit marqueur 2 → 2 Rub' complétés = 1 Nisf
      await tracker.recordSequentialPageTurn(testUser, 'hafs', 2, 3, 2, 45);
      expect(await tracker.getUniqueRubsCompletedToday(testUser), 2,
          reason: '2 Rub\' = 1 Nisf (marqueur 2 de type nisf)');
    });

    test('Continuité multi-jours : même page peut compter jour suivant', () async {
      // Jour 1 : franchir marqueur 1 (2:26)
      await tracker.recordSequentialPageTurn(testUser, 'hafs', 1, 2, 2, 27);
      
      // Même tour le jour suivant devrait pouvoir recompter le même Rub'
      // (dans ce test, SharedPreferences est isolé donc on simule jour 1 uniquement)
      final rubsToday = await tracker.getUniqueRubsCompletedToday(testUser);
      expect(rubsToday, greaterThanOrEqualTo(1));
    });

    test('Activité 7 derniers jours compte jours uniques', () async {
      // Aujourd'hui : franchir marqueur 1 (2:26) = 1 Rub' complété
      await tracker.recordSequentialPageTurn(testUser, 'hafs', 1, 2, 2, 27);
      
      final activeDays = await tracker.getActiveDaysCount(testUser, 7);
      expect(activeDays, 1, reason: 'Un seul jour actif aujourd\'hui');
    });

    test('Position de reprise est sauvegardée avec surah/ayah', () async {
      await tracker.savePositionOnly(
        testUser,
        'hafs',
        42,
        surah: 3,
        ayah: 92,
      );
      
      final position = await tracker.getLastPosition(testUser);
      expect(position, isNotNull);
      expect(position?.type, 'hafs');
      expect(position?.page, 42);
      expect(position?.lastReadAt, isNotNull);
    });

    test('Dernière page séquentielle est trackée pour détecter sauts', () async {
      await tracker.recordSequentialPageTurn(testUser, 'hafs', 5, 6, 2, 106);
      
      final lastSeq = await tracker.getLastSequentialPage(testUser);
      expect(lastSeq, 6, reason: 'Dernière page séquentielle = 6');
      
      // Saut vers page 20 : savePositionOnly ne met PAS à jour lastSequentialPage
      await tracker.savePositionOnly(testUser, 'hafs', 20);
      final stillSeq = await tracker.getLastSequentialPage(testUser);
      expect(stillSeq, 6, reason: 'savePositionOnly ne modifie pas lastSequentialPage');
    });
  });

  group('WirdRubTracker — Utilitaires canoniques Rub\'', () {
    test('240 Rub\' canoniques disponibles', () {
      final markers = QuranSubdivisionData.getAllQuarters();
      expect(markers.length, 240, reason: '60 Hizb × 4 Rub\' = 240');
    });

    test('Rub\' 0 commence à Al-Fatiha 1:1', () {
      final markers = QuranSubdivisionData.getAllQuarters();
      final rub0 = markers[0];
      expect(rub0.surah, 1);
      expect(rub0.ayah, 1);
    });

    test('Rub\' 239 termine le Coran', () {
      final markers = QuranSubdivisionData.getAllQuarters();
      final rub239 = markers[239];
      expect(rub239.hizbNumber, 60, reason: 'Dernier Hizb');
    });

    test('Hizb 1 contient exactement 4 Rub\'', () {
      final markers = QuranSubdivisionData.getQuartersForHizb(1);
      expect(markers.length, 4);
    });
  });

  group('WirdRubTracker — Invariants critiques', () {
    late WirdRubTracker tracker;
    const testUser = 'test@anis.ma';

    setUp(() {
      tracker = WirdRubTracker();
      SharedPreferences.setMockInitialValues({});
    });

    test('INVARIANT 1: entrer sur page avec frontière mid-page ne crédite PAS immédiatement', () async {
      // Page 2 → Page 3
      // Page 2 dernier ayat: 2:74 (avant marqueur 3 qui est 2:106)
      // Page 3 contient marqueur 4 (2:106) au début
      // 
      // Tour de page 2→3 utilise le dernier ayat de page 2 (2:74)
      // donc NE DOIT PAS créditer le marqueur 4 (2:106) de page 3
      
      await tracker.recordSequentialPageTurn(testUser, 'hafs', 2, 3, 2, 74);
      
      final count = await tracker.getUniqueRubsCompletedToday(testUser);
      // 2:74 franchit marqueurs 1,2,3 → 3 Rub' complétés
      // NE franchit PAS marqueur 4 (2:106) qui est sur page 3
      expect(count, 3, reason: 'Page turn 2→3 credits page 2 completion only');
    });


    test('INVARIANT 3: 240ème Rub\' NE DOIT PAS être complété automatiquement sur page 604', () async {
      // Tour séquentiel 603→604 crédite SEULEMENT page 603, PAS page 604
      // Il NE DOIT PAS compléter automatiquement le 240ème Rub'
      
      await tracker.recordSequentialPageTurn(testUser, 'hafs', 603, 604, 114, 3);
      
      final count = await tracker.getUniqueRubsCompletedToday(testUser);
      // 114:3 (dernier ayat page 603) franchit tous les marqueurs jusqu'à ~239
      // mais NE franchit PAS 114:6, donc le 240ème Rub' n'est PAS complété
      expect(count, lessThan(240), 
          reason: 'Sequential turn 603→604 proves page 603 completed, NOT page 604');
    });

    test('INVARIANT 4: maximum possible = exactement 240 Rub\'', () async {
      // Lire tout le Quran séquentiellement devrait donner exactement 240 Rub'
      // On simule en appelant explicitement recordFinalPageCompletion()
      
      await tracker.recordFinalPageCompletion(testUser, 'hafs');
      
      final count = await tracker.getUniqueRubsCompletedToday(testUser);
      expect(count, lessThanOrEqualTo(240), 
          reason: 'Cannot exceed 240 Rub\' (60 Hizb × 4 Rub\')');
      expect(count, 240, 
          reason: 'Explicit final page completion completes exactly 240 Rub\'');
    });

    test('REGRESSION 1: Sequential 603→604 does NOT complete Rub\' #240', () async {
      // Tour séquentiel 603→604 ne doit PAS compléter automatiquement Rub' #240
      await tracker.recordSequentialPageTurn(testUser, 'hafs', 603, 604, 114, 3);
      
      final count = await tracker.getUniqueRubsCompletedToday(testUser);
      expect(count, lessThan(240), 
          reason: 'Arriving on page 604 does NOT prove 114:6 was read');
    });

    test('REGRESSION 2: Jump/resume to page 604 does NOT complete Rub\' #240', () async {
      // Sauter directement sur page 604 (non-séquentiel)
      await tracker.savePositionOnly(testUser, 'hafs', 604);
      
      final count = await tracker.getUniqueRubsCompletedToday(testUser);
      expect(count, 0, 
          reason: 'Jump to page 604 does not complete any Rub\'');
    });

    test('REGRESSION 3: Explicit final-page completion completes Rub\' #240', () async {
      // Seul l'appel explicite à recordFinalPageCompletion() doit compléter #240
      await tracker.recordFinalPageCompletion(testUser, 'hafs');
      
      final count = await tracker.getUniqueRubsCompletedToday(testUser);
      expect(count, 240, 
          reason: 'Explicit completion completes all 240 Rub\'');
    });

    test('REGRESSION 4: Duplicate final-page completion is prevented', () async {
      // Premier appel
      await tracker.recordFinalPageCompletion(testUser, 'hafs');
      final count1 = await tracker.getUniqueRubsCompletedToday(testUser);
      expect(count1, 240);
      
      // Deuxième appel (duplicate)
      await tracker.recordFinalPageCompletion(testUser, 'hafs');
      final count2 = await tracker.getUniqueRubsCompletedToday(testUser);
      expect(count2, 240, 
          reason: 'Duplicate completion does not increase count beyond 240');
    });

    test('REGRESSION 5: Maximum completion remains exactly 240', () async {
      // Même avec plusieurs appels, le maximum reste 240
      await tracker.recordFinalPageCompletion(testUser, 'hafs');
      await tracker.recordFinalPageCompletion(testUser, 'hafs');
      await tracker.recordFinalPageCompletion(testUser, 'hafs');
      
      final count = await tracker.getUniqueRubsCompletedToday(testUser);
      expect(count, 240, 
          reason: 'Maximum remains exactly 240 Rub\'');
    });

    test('RUNTIME SCENARIO: arrivée séquentielle sur page 604 + bouton explicite', () async {
      // Simuler le scénario runtime réel : l'utilisateur lit séquentiellement
      // et arrive sur la dernière page (604).
      // 
      // Dans le code réel :
      // 1. onPageChanged(604) avec oldPage=603
      // 2. Crédite page 603 normalement (NE crédite PAS page 604)
      // 3. L'utilisateur voit le bouton "Terminer le Coran" sur page 604
      // 4. L'utilisateur clique → appelle recordFinalPageCompletion()
      
      // Étape 1 : Tour 603→604 crédite page 603 SEULEMENT
      await tracker.recordSequentialPageTurn(testUser, 'hafs', 603, 604, 114, 3);
      final count1 = await tracker.getUniqueRubsCompletedToday(testUser);
      expect(count1, lessThan(240), reason: 'Page 603 ne contient pas la fin');
      
      // Étape 2 : L'utilisateur clique sur "Terminer le Coran"
      await tracker.recordFinalPageCompletion(testUser, 'hafs');
      final count2 = await tracker.getUniqueRubsCompletedToday(testUser);
      expect(count2, 240, reason: 'Explicit final page completion triggers 240th Rub\'');
    });
  });
}
