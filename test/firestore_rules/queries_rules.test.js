/**
 * Tests Firestore Rules — opérations `list` et `collectionGroup`.
 *
 * La suite khatmat_rules.test.js ne couvre que des accès document par document
 * (get/set/update). Or le runtime échouait sur des REQUÊTES, dont les règles
 * suivent une sémantique différente : Firestore refuse une query dès qu'elle
 * pourrait retourner un document non autorisé, et une collectionGroup exige un
 * match de chemin dédié.
 *
 * Ce fichier reproduit exactement les requêtes émises par :
 *   - ReadingService.getMyKhatmat
 *   - ReadingService.fetchUserActiveReservationsFromSubcollection
 *   - ReadingService.getPublicKhatmat
 *
 * Lancer : cd test/firestore_rules && npm run test:queries
 */
const fs = require('fs');
const path = require('path');
const {
  initializeTestEnvironment,
  assertFails,
  assertSucceeds,
} = require('@firebase/rules-unit-testing');

const PROJECT_ID = 'anis-khatamat-queries';
const rulesPath = path.resolve(__dirname, '../../firestore.rules');

const KHATMAT_LIMIT = 100; // ReadingService._khatmatLimit
const SUBCOLLECTION = 'hizb_reservations'; // ReservationSchema.subcollectionName

const CANONICAL_DEFINITION = 'quran_foundation_hafs_v1';

const baseKhatma = (overrides = {}) => ({
  title: 'Khatma test',
  createdBy: 'creator@test.com',
  createdAt: new Date().toISOString(),
  isGroup: true,
  reservationMode: true,
  isPublic: false,
  members: [],
  guestParticipants: {},
  participantIds: [],
  hizbAssignments: {},
  hizbReservations: {},
  reservationSchemaVersion: 2,
  completedHizbCount: 0,
  hizbDefinitionId: CANONICAL_DEFINITION,
  ...overrides,
});

function canonicalSnapshot(n) {
  return {
    hizbDefinitionId: CANONICAL_DEFINITION,
    startVerseKey: `${((n - 1) % 114) + 1}:1`,
    endVerseKey: `${((n - 1) % 114) + 1}:10`,
    startPageHafs: Math.min(1 + (n - 1) * 10, 594),
    endPageHafs: Math.min(10 + (n - 1) * 10, 604),
  };
}

function availableDoc(n) {
  return { hizbNumber: n, status: 'available', ...canonicalSnapshot(n) };
}

function reservedDoc(n, reservedBy) {
  return {
    hizbNumber: n,
    status: 'reserved',
    reservedBy,
    ...canonicalSnapshot(n),
  };
}

function authedDb(testEnv, uid, email) {
  return testEnv.authenticatedContext(uid, email ? { email } : {}).firestore();
}

async function runTest(name, fn) {
  process.stdout.write(`  ${name} ... `);
  try {
    await fn();
    console.log('PASS');
    return true;
  } catch (e) {
    console.log('FAIL');
    console.error(`    ${e.message || e}`);
    return false;
  }
}

// Les 4 requêtes réellement émises par getMyKhatmat.
const qCreatedBy = (db, email) =>
  db.collection('khatmat')
    .where('createdBy', '==', email)
    .orderBy('createdAt', 'desc')
    .limit(KHATMAT_LIMIT)
    .get();

const qMembers = (db, email) =>
  db.collection('khatmat')
    .where('members', 'array-contains', email)
    .orderBy('createdAt', 'desc')
    .limit(KHATMAT_LIMIT)
    .get();

const qParticipantIds = (db, id) =>
  db.collection('khatmat')
    .where('participantIds', 'array-contains', id)
    .orderBy('createdAt', 'desc')
    .limit(KHATMAT_LIMIT)
    .get();

const qReservationsOf = (db, participantId) =>
  db.collectionGroup(SUBCOLLECTION)
    .where('reservedBy', '==', participantId)
    .limit(40)
    .get();

async function main() {
  const testEnv = await initializeTestEnvironment({
    projectId: PROJECT_ID,
    firestore: { rules: fs.readFileSync(rulesPath, 'utf8') },
  });

  let passed = 0;
  let failed = 0;

  const test = async (name, fn) => {
    await testEnv.clearFirestore();
    const ok = await runTest(name, fn);
    if (ok) passed++;
    else failed++;
  };

  // Écrit en contournant les rules : on teste la LECTURE, pas l'écriture.
  const seed = (fn) => testEnv.withSecurityRulesDisabled((ctx) => fn(ctx.firestore()));

  // ─── getMyKhatmat : les 4 requêtes ─────────────────────────────────────

  await test('Q1. createdBy == email (créateur)', async () => {
    await seed(async (db) => {
      await db.collection('khatmat').doc('k1').set(baseKhatma());
    });
    const creator = authedDb(testEnv, 'c', 'creator@test.com');
    const snap = await assertSucceeds(qCreatedBy(creator, 'creator@test.com'));
    if (snap.size !== 1) throw new Error(`attendu 1 doc, reçu ${snap.size}`);
  });

  await test('Q2. members array-contains email (membre)', async () => {
    await seed(async (db) => {
      await db.collection('khatmat').doc('k1').set(
        baseKhatma({ members: ['member@test.com'] }),
      );
    });
    const member = authedDb(testEnv, 'm', 'member@test.com');
    const snap = await assertSucceeds(qMembers(member, 'member@test.com'));
    if (snap.size !== 1) throw new Error(`attendu 1 doc, reçu ${snap.size}`);
  });

  await test('Q3. participantIds array-contains email', async () => {
    await seed(async (db) => {
      await db.collection('khatmat').doc('k1').set(
        baseKhatma({ participantIds: ['member@test.com'] }),
      );
    });
    const member = authedDb(testEnv, 'm', 'member@test.com');
    const snap = await assertSucceeds(qParticipantIds(member, 'member@test.com'));
    if (snap.size !== 1) throw new Error(`attendu 1 doc, reçu ${snap.size}`);
  });

  await test('Q4. participantIds array-contains authUid (invité anonyme)', async () => {
    await seed(async (db) => {
      await db.collection('khatmat').doc('k1').set(
        baseKhatma({
          participantIds: ['anon_uid_1'],
          guestParticipants: { anon_uid_1: 'Invité' },
        }),
      );
    });
    const guest = authedDb(testEnv, 'anon_uid_1');
    const snap = await assertSucceeds(qParticipantIds(guest, 'anon_uid_1'));
    if (snap.size !== 1) throw new Error(`attendu 1 doc, reçu ${snap.size}`);
  });

  await test('Q5. participantIds array-contains authUid pour un compte EMAIL', async () => {
    // Piège « query trop large » : getMyKhatmat émet aussi la requête sur
    // l'authUid d'un utilisateur email. Si les rules ne reconnaissent que son
    // email, ce document lui est refusé et Firestore rejette TOUTE la requête,
    // donc l'intégralité de « Mes Khatmas ».
    await seed(async (db) => {
      await db.collection('khatmat').doc('k1').set(
        baseKhatma({
          createdBy: 'other@test.com',
          participantIds: ['uid_email_user'],
        }),
      );
    });
    const user = authedDb(testEnv, 'uid_email_user', 'member@test.com');
    await assertSucceeds(qParticipantIds(user, 'uid_email_user'));
  });

  await test('Q6. les 4 requêtes en parallèle (Future.wait réel)', async () => {
    await seed(async (db) => {
      await db.collection('khatmat').doc('k1').set(baseKhatma());
      await db.collection('khatmat').doc('k2').set(
        baseKhatma({ createdBy: 'x@test.com', members: ['creator@test.com'] }),
      );
    });
    const user = authedDb(testEnv, 'uid_c', 'creator@test.com');
    await assertSucceeds(
      Promise.all([
        qCreatedBy(user, 'creator@test.com'),
        qMembers(user, 'creator@test.com'),
        qParticipantIds(user, 'creator@test.com'),
        qParticipantIds(user, 'uid_c'),
      ]),
    );
  });

  await test('Q7. requête large sans contrainte → doit ÉCHOUER', async () => {
    await seed(async (db) => {
      await db.collection('khatmat').doc('k1').set(baseKhatma());
    });
    const outsider = authedDb(testEnv, 'o', 'outsider@test.com');
    await assertFails(outsider.collection('khatmat').limit(100).get());
  });

  await test('Q8. outsider ne lit pas une Khatma privée par requête', async () => {
    await seed(async (db) => {
      await db.collection('khatmat').doc('k1').set(
        baseKhatma({ members: ['member@test.com'] }),
      );
    });
    const outsider = authedDb(testEnv, 'o', 'outsider@test.com');
    const snap = await assertSucceeds(qMembers(outsider, 'outsider@test.com'));
    if (snap.size !== 0) throw new Error(`fuite : ${snap.size} doc(s)`);
  });

  // ─── getPublicKhatmat ──────────────────────────────────────────────────

  await test('Q9. isPublic == true (Khatmas publiques)', async () => {
    await seed(async (db) => {
      await db.collection('khatmat').doc('kpub').set(baseKhatma({ isPublic: true }));
      await db.collection('khatmat').doc('kpriv').set(baseKhatma());
    });
    const anyone = authedDb(testEnv, 'o', 'outsider@test.com');
    const snap = await assertSucceeds(
      anyone.collection('khatmat')
        .where('isPublic', '==', true)
        .limit(50)
        .get(),
    );
    if (snap.size !== 1) throw new Error(`attendu 1 doc public, reçu ${snap.size}`);
  });

  // ─── fetchUserActiveReservationsFromSubcollection ──────────────────────

  await test('Q10. collectionGroup hizb_reservations (membre)', async () => {
    await seed(async (db) => {
      await db.collection('khatmat').doc('k1').set(
        baseKhatma({ members: ['member@test.com'] }),
      );
      await db.collection('khatmat').doc('k1').collection(SUBCOLLECTION).doc('44').set({
        hizbNumber: 44,
        status: 'reserved',
        reservedBy: 'member@test.com',
      });
    });
    const member = authedDb(testEnv, 'm', 'member@test.com');
    const snap = await assertSucceeds(qReservationsOf(member, 'member@test.com'));
    if (snap.size !== 1) throw new Error(`attendu 1 réservation, reçu ${snap.size}`);
  });

  await test('Q11. collectionGroup hizb_reservations (invité anonyme)', async () => {
    await seed(async (db) => {
      await db.collection('khatmat').doc('k1').set(
        baseKhatma({
          guestParticipants: { anon_uid_1: 'Invité' },
          participantIds: ['anon_uid_1'],
        }),
      );
      await db.collection('khatmat').doc('k1').collection(SUBCOLLECTION).doc('44').set({
        hizbNumber: 44,
        status: 'reserved',
        reservedBy: 'anon_uid_1',
      });
    });
    const guest = authedDb(testEnv, 'anon_uid_1');
    const snap = await assertSucceeds(qReservationsOf(guest, 'anon_uid_1'));
    if (snap.size !== 1) throw new Error(`attendu 1 réservation, reçu ${snap.size}`);
  });

  await test('Q12. collectionGroup ne fuit pas les réservations d\'autrui', async () => {
    await seed(async (db) => {
      await db.collection('khatmat').doc('k1').set(
        baseKhatma({ members: ['member@test.com'] }),
      );
      await db.collection('khatmat').doc('k1').collection(SUBCOLLECTION).doc('44').set({
        hizbNumber: 44,
        status: 'reserved',
        reservedBy: 'member@test.com',
      });
    });
    const outsider = authedDb(testEnv, 'o', 'outsider@test.com');
    const snap = await assertSucceeds(qReservationsOf(outsider, 'outsider@test.com'));
    if (snap.size !== 0) throw new Error(`fuite : ${snap.size} doc(s)`);
  });

  await test('Q13. collectionGroup sans filtre reservedBy → doit ÉCHOUER', async () => {
    await seed(async (db) => {
      await db.collection('khatmat').doc('k1').set(
        baseKhatma({ members: ['member@test.com'] }),
      );
      await db.collection('khatmat').doc('k1').collection(SUBCOLLECTION).doc('44').set({
        hizbNumber: 44,
        status: 'reserved',
        reservedBy: 'member@test.com',
      });
    });
    const outsider = authedDb(testEnv, 'o', 'outsider@test.com');
    await assertFails(outsider.collectionGroup(SUBCOLLECTION).limit(40).get());
  });

  // ─── Lecture de la grille de réservation d'une Khatma ──────────────────

  await test('Q14. membre liste les 60 Hizb de sa Khatma', async () => {
    await seed(async (db) => {
      await db.collection('khatmat').doc('k1').set(
        baseKhatma({ members: ['member@test.com'] }),
      );
      const col = db.collection('khatmat').doc('k1').collection(SUBCOLLECTION);
      for (let n = 1; n <= 60; n++) {
        await col.doc(String(n)).set({ hizbNumber: n, status: 'available' });
      }
    });
    const member = authedDb(testEnv, 'm', 'member@test.com');
    const snap = await assertSucceeds(
      member.collection('khatmat').doc('k1').collection(SUBCOLLECTION).get(),
    );
    if (snap.size !== 60) throw new Error(`attendu 60 docs, reçu ${snap.size}`);
  });

  await test('Q15. outsider ne liste pas la grille d\'une Khatma privée', async () => {
    await seed(async (db) => {
      await db.collection('khatmat').doc('k1').set(
        baseKhatma({ members: ['member@test.com'] }),
      );
      await db.collection('khatmat').doc('k1').collection(SUBCOLLECTION).doc('1').set({
        hizbNumber: 1,
        status: 'available',
      });
    });
    const outsider = authedDb(testEnv, 'o', 'outsider@test.com');
    await assertFails(
      outsider.collection('khatmat').doc('k1').collection(SUBCOLLECTION).get(),
    );
  });

  // ─── Repro permission-denied getMyKhatmat ──────────────────────────────

  await test('Q16. sans auth, les queries getMyKhatmat sont refusées', async () => {
    await seed(async (db) => {
      await db.collection('khatmat').doc('k1').set(baseKhatma());
    });
    const unauth = testEnv.unauthenticatedContext().firestore();
    await assertFails(qCreatedBy(unauth, 'creator@test.com'));
    await assertFails(qMembers(unauth, 'creator@test.com'));
    await assertFails(qParticipantIds(unauth, 'creator@test.com'));
    await assertFails(qReservationsOf(unauth, 'creator@test.com'));
  });

  await test('Q17. query trop large : anonymous + createdBy demo@test.com', async () => {
    // Cause runtime observée : mode démo / identité synthétique alors qu'un
    // token (ou l'absence de token) ne peut pas prouver createdBy == demo@test.com.
    await seed(async (db) => {
      await db.collection('khatmat').doc('kdemo').set(
        baseKhatma({ createdBy: 'demo@test.com', participantIds: ['demo@test.com'] }),
      );
    });
    const anon = authedDb(testEnv, 'anon_leftover');
    await assertFails(qCreatedBy(anon, 'demo@test.com'));
  });

  await test('Q18. creator get + list ses Khatmas', async () => {
    await seed(async (db) => {
      await db.collection('khatmat').doc('k1').set(baseKhatma());
    });
    const creator = authedDb(testEnv, 'c', 'creator@test.com');
    await assertSucceeds(creator.collection('khatmat').doc('k1').get());
    const snap = await assertSucceeds(qCreatedBy(creator, 'creator@test.com'));
    if (snap.size !== 1) throw new Error(`attendu 1, reçu ${snap.size}`);
  });

  await test('Q19. member voit sa Khatma, pas une privée étrangère', async () => {
    await seed(async (db) => {
      await db.collection('khatmat').doc('mine').set(
        baseKhatma({ members: ['member@test.com'], participantIds: ['member@test.com'] }),
      );
      await db.collection('khatmat').doc('other').set(
        baseKhatma({ createdBy: 'other@test.com', members: ['other@test.com'] }),
      );
    });
    const member = authedDb(testEnv, 'm', 'member@test.com');
    await assertSucceeds(member.collection('khatmat').doc('mine').get());
    await assertFails(member.collection('khatmat').doc('other').get());
    const snap = await assertSucceeds(qMembers(member, 'member@test.com'));
    if (snap.size !== 1) throw new Error(`fuite ou manque : ${snap.size}`);
  });

  await test('Q20. guest rejoint (guestParticipants+participantIds) puis lit', async () => {
    await seed(async (db) => {
      await db.collection('khatmat').doc('k1').set(baseKhatma({ isPublic: true }));
    });
    const guest = authedDb(testEnv, 'anon_uid_1');
    await assertSucceeds(
      guest.collection('khatmat').doc('k1').update({
        guestParticipants: { anon_uid_1: 'Invité' },
        participantIds: ['anon_uid_1'],
      }),
    );
    await assertSucceeds(guest.collection('khatmat').doc('k1').get());
    const snap = await assertSucceeds(qParticipantIds(guest, 'anon_uid_1'));
    if (snap.size !== 1) throw new Error(`attendu 1, reçu ${snap.size}`);
  });

  await test('Q21. outsider ne lit pas une Khatma privée', async () => {
    await seed(async (db) => {
      await db.collection('khatmat').doc('k1').set(baseKhatma());
    });
    const outsider = authedDb(testEnv, 'o', 'outsider@test.com');
    await assertFails(outsider.collection('khatmat').doc('k1').get());
  });

  await test('Q22. public : lecture conforme isPublic', async () => {
    await seed(async (db) => {
      await db.collection('khatmat').doc('kpub').set(baseKhatma({ isPublic: true }));
    });
    const anyone = authedDb(testEnv, 'o', 'outsider@test.com');
    await assertSucceeds(anyone.collection('khatmat').doc('kpub').get());
  });

  await testEnv.cleanup();
  console.log(`\n${passed} passed, ${failed} failed`);
  process.exit(failed > 0 ? 1 : 0);
}

main().catch((e) => {
  console.error(e);
  process.exit(1);
});
