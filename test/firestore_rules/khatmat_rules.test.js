/**
 * Tests Firestore Rules — sous-collection hizb_reservations (12 scénarios sécurité + migration)
 *
 * Lancer : cd test/firestore_rules && npm test
 */
const fs = require('fs');
const path = require('path');
const {
  initializeTestEnvironment,
  assertFails,
  assertSucceeds,
} = require('@firebase/rules-unit-testing');

const PROJECT_ID = 'anis-khatamat-rules-v2';
const rulesPath = path.resolve(__dirname, '../../firestore.rules');

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
  hizbAssignments: {},
  hizbReservations: {},
  reservationSchemaVersion: 2,
  completedHizbCount: 0,
  hizbDefinitionId: CANONICAL_DEFINITION,
  ...overrides,
});

/** Snapshot minimal valide pour les tests v2 (structure rules, pas certification contenu). */
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
  return {
    hizbNumber: n,
    status: 'available',
    ...canonicalSnapshot(n),
  };
}

function reservedDoc(n, reservedBy, now) {
  return {
    hizbNumber: n,
    status: 'reserved',
    reservedBy,
    reservedAt: now,
    expiresAt: now,
    ...canonicalSnapshot(n),
  };
}

/** Khatma v1 sans hizbDefinitionId (migration legacy volontaire). */
function legacyV1Khatma(overrides = {}) {
  const k = baseKhatma({ reservationSchemaVersion: 1, ...overrides });
  delete k.hizbDefinitionId;
  return k;
}

function authedDb(testEnv, uid, email) {
  return testEnv.authenticatedContext(uid, email ? { email } : {}).firestore();
}

function hizbCol(db, khatmaId) {
  return db.collection('khatmat').doc(khatmaId).collection('hizb_reservations');
}

async function initAvailable(db, khatmaId, n) {
  await hizbCol(db, khatmaId).doc(String(n)).set(availableDoc(n));
}

async function runTest(name, fn) {
  process.stdout.write(`  ${name} ... `);
  try {
    await fn();
    console.log('PASS');
    return true;
  } catch (e) {
    console.log('FAIL');
    console.error(e);
    return false;
  }
}

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

  const setupKhatma = async (khatmaId, memberEmail, guestUid, extraMembers = []) => {
    const creator = authedDb(testEnv, 'creator_uid', 'creator@test.com');
    const data = baseKhatma();
    const members = new Set(extraMembers);
    if (memberEmail) members.add(memberEmail);
    if (members.size > 0) data.members = [...members];
    if (guestUid) data.guestParticipants = { [guestUid]: 'Guest' };
    await creator.collection('khatmat').doc(khatmaId).set(data);
  };

  const seedAvailable = async (db, khatmaId, n) => {
    await hizbCol(db, khatmaId).doc(String(n)).set(availableDoc(n));
  };

  await test('1. membre A réserve Hizb 10', async () => {
    await setupKhatma('k1', 'memberA@test.com');
    const memberA = authedDb(testEnv, 'ma', 'memberA@test.com');
    const now = new Date().toISOString();
    await assertSucceeds(
      hizbCol(memberA, 'k1').doc('10').set(reservedDoc(10, 'memberA@test.com', now)),
    );
  });

  await test('2. membre B réserve Hizb 10 déjà pris → FAIL', async () => {
    await setupKhatma('k2', 'memberA@test.com', null, ['memberB@test.com']);
    const memberA = authedDb(testEnv, 'ma', 'memberA@test.com');
    const memberB = authedDb(testEnv, 'mb', 'memberB@test.com');
    const now = new Date().toISOString();
    await hizbCol(memberA, 'k2').doc('10').set(reservedDoc(10, 'memberA@test.com', now));
    await assertFails(
      hizbCol(memberB, 'k2').doc('10').set(reservedDoc(10, 'memberB@test.com', now)),
    );
  });

  await test('3. membre B modifie réservation de A → FAIL', async () => {
    await setupKhatma('k3', 'memberA@test.com', null, ['memberB@test.com']);
    const memberA = authedDb(testEnv, 'ma', 'memberA@test.com');
    const memberB = authedDb(testEnv, 'mb', 'memberB@test.com');
    const now = new Date().toISOString();
    await hizbCol(memberA, 'k3').doc('10').set(reservedDoc(10, 'memberA@test.com', now));
    await assertFails(
      hizbCol(memberB, 'k3').doc('10').update({ status: 'inProgress' }),
    );
  });

  await test('4. membre A démarre sa réservation', async () => {
    await setupKhatma('k4', 'memberA@test.com');
    const memberA = authedDb(testEnv, 'ma', 'memberA@test.com');
    const now = new Date().toISOString();
    await hizbCol(memberA, 'k4').doc('10').set(reservedDoc(10, 'memberA@test.com', now));
    await assertSucceeds(
      hizbCol(memberA, 'k4').doc('10').update({ status: 'inProgress' }),
    );
  });

  await test('5. membre A termine', async () => {
    await setupKhatma('k5', 'memberA@test.com');
    const memberA = authedDb(testEnv, 'ma', 'memberA@test.com');
    const now = new Date().toISOString();
    await hizbCol(memberA, 'k5').doc('10').set(reservedDoc(10, 'memberA@test.com', now));
    await hizbCol(memberA, 'k5').doc('10').update({ status: 'inProgress' });
    await assertSucceeds(
      hizbCol(memberA, 'k5').doc('10').update({
        status: 'completed',
        completedAt: now,
      }),
    );
  });

  await test('6. membre A libère sa réservation', async () => {
    await setupKhatma('k6', 'memberA@test.com');
    const memberA = authedDb(testEnv, 'ma', 'memberA@test.com');
    const now = new Date().toISOString();
    await hizbCol(memberA, 'k6').doc('10').set(reservedDoc(10, 'memberA@test.com', now));
    await assertSucceeds(
      hizbCol(memberA, 'k6').doc('10').set(availableDoc(10)),
    );
  });

  await test('7. guest anon rejoint puis réserve', async () => {
    await setupKhatma('k7', null, 'guest_uid_1');
    const guest = authedDb(testEnv, 'guest_uid_1');
    const now = new Date().toISOString();
    await assertSucceeds(
      hizbCol(guest, 'k7').doc('15').set(reservedDoc(15, 'guest_uid_1', now)),
    );
  });

  await test('8. guest B touche réservation guest A → FAIL', async () => {
    const creator = authedDb(testEnv, 'c', 'creator@test.com');
    await setupKhatma('k8', null, 'guest_a');
    await creator.collection('khatmat').doc('k8').update({
      guestParticipants: { guest_a: 'A', guest_b: 'B' },
    });
    const guestA = authedDb(testEnv, 'guest_a');
    const guestB = authedDb(testEnv, 'guest_b');
    const now = new Date().toISOString();
    await hizbCol(guestA, 'k8').doc('12').set(reservedDoc(12, 'guest_a', now));
    await assertFails(
      hizbCol(guestB, 'k8').doc('12').update({ status: 'inProgress' }),
    );
  });

  await test('9. outsider modifie → FAIL', async () => {
    await setupKhatma('k9', 'member@test.com');
    const outsider = authedDb(testEnv, 'out', 'out@test.com');
    const now = new Date().toISOString();
    await assertFails(
      hizbCol(outsider, 'k9').doc('10').set(reservedDoc(10, 'out@test.com', now)),
    );
  });

  await test('10. creator adminForceRelease', async () => {
    await setupKhatma('k10', 'memberX@test.com');
    const creator = authedDb(testEnv, 'c', 'creator@test.com');
    const memberX = authedDb(testEnv, 'mx', 'memberX@test.com');
    const now = new Date().toISOString();
    await hizbCol(memberX, 'k10').doc('20').set(reservedDoc(20, 'memberX@test.com', now));
    await assertSucceeds(
      hizbCol(creator, 'k10').doc('20').set(availableDoc(20)),
    );
  });

  await test('11. changement reservedBy frauduleux → FAIL', async () => {
    await setupKhatma('k11', 'memberA@test.com');
    const memberA = authedDb(testEnv, 'ma', 'memberA@test.com');
    const now = new Date().toISOString();
    await hizbCol(memberA, 'k11').doc('10').set(reservedDoc(10, 'memberA@test.com', now));
    await assertFails(
      hizbCol(memberA, 'k11').doc('10').update({ reservedBy: 'hacker@test.com' }),
    );
  });

  await test('12. changement hizbNumber frauduleux → FAIL', async () => {
    await setupKhatma('k12', 'memberA@test.com');
    const memberA = authedDb(testEnv, 'ma', 'memberA@test.com');
    const now = new Date().toISOString();
    await hizbCol(memberA, 'k12').doc('10').set(reservedDoc(10, 'memberA@test.com', now));
    await assertFails(
      hizbCol(memberA, 'k12').doc('10').update({ hizbNumber: 99 }),
    );
  });

  await test('P0.2 join ajoute participantIds (membre)', async () => {
    await setupKhatma('kp2', null);
    const member = authedDb(testEnv, 'm', 'member@test.com');
    await assertSucceeds(
      member.collection('khatmat').doc('kp2').update({
        members: ['member@test.com'],
        participantIds: ['member@test.com'],
      }),
    );
    await assertSucceeds(
      member.collection('khatmat').doc('kp2').get(),
    );
  });

  await test('P0.2 join ajoute participantIds (guest)', async () => {
    await setupKhatma('kg2', null);
    const guest = authedDb(testEnv, 'guest_uid_p2');
    await assertSucceeds(
      guest.collection('khatmat').doc('kg2').update({
        guestParticipants: { guest_uid_p2: 'Invité' },
        participantIds: ['guest_uid_p2'],
      }),
    );
  });

  await test('P0.604 compteur +1 valide (59→60)', async () => {
    await setupKhatma('k604', 'member@test.com');
    const creator = authedDb(testEnv, 'c', 'creator@test.com');
    const member = authedDb(testEnv, 'm', 'member@test.com');
    await creator.collection('khatmat').doc('k604').update({ completedHizbCount: 59 });
    await assertSucceeds(
      member.collection('khatmat').doc('k604').update({ completedHizbCount: 60 }),
    );
  });

  await test('P0.605 compteur saut direct 61 → FAIL', async () => {
    await setupKhatma('k605', 'member@test.com');
    const creator = authedDb(testEnv, 'c', 'creator@test.com');
    const member = authedDb(testEnv, 'm', 'member@test.com');
    await creator.collection('khatmat').doc('k605').update({ completedHizbCount: 59 });
    await assertFails(
      member.collection('khatmat').doc('k605').update({ completedHizbCount: 61 }),
    );
  });

  await test('P0.606 créateur peut recalculer compteur (admin release)', async () => {
    await setupKhatma('k606', 'member@test.com');
    const creator = authedDb(testEnv, 'c', 'creator@test.com');
    await creator.collection('khatmat').doc('k606').update({ completedHizbCount: 60 });
    await assertSucceeds(
      creator.collection('khatmat').doc('k606').update({ completedHizbCount: 59 }),
    );
  });

  await test('WOW01 completedAt à 60/60 (59→60 + timestamp)', async () => {
    await setupKhatma('kw1', 'member@test.com');
    const creator = authedDb(testEnv, 'c', 'creator@test.com');
    const member = authedDb(testEnv, 'm', 'member@test.com');
    // Le saut 0→59 n'est autorisé qu'au créateur : un membre ne peut
    // qu'incrémenter de 1. Le test doit donc préparer l'état via le créateur.
    await creator.collection('khatmat').doc('kw1').update({ completedHizbCount: 59 });
    await assertSucceeds(
      member.collection('khatmat').doc('kw1').update({
        completedHizbCount: 60,
        completedAt: new Date(),
      }),
    );
    const snap = await member.collection('khatmat').doc('kw1').get();
    if (!snap.data().completedAt) throw new Error('completedAt missing');
  });

  await test('WOW01 completedAt non écrasé si déjà présent', async () => {
    await setupKhatma('kw2', 'member@test.com');
    const creator = authedDb(testEnv, 'c', 'creator@test.com');
    const member = authedDb(testEnv, 'm', 'member@test.com');
    const first = new Date('2026-01-01T12:00:00Z');
    await creator.collection('khatmat').doc('kw2').update({
      completedHizbCount: 60,
      completedAt: first,
    });
    await assertFails(
      member.collection('khatmat').doc('kw2').update({
        completedHizbCount: 60,
        completedAt: new Date('2026-02-01T12:00:00Z'),
      }),
    );
  });

  await test('M1. migration v1 map → v2 idempotente', async () => {
    const creator = authedDb(testEnv, 'c', 'creator@test.com');
    const member = authedDb(testEnv, 'm', 'member@test.com');
    await creator.collection('khatmat').doc('legacy1').set({
      ...legacyV1Khatma(),
      hizbReservations: {
        '7': {
          status: 'reserved',
          reservedBy: 'guest_legacy',
          reservedForName: 'Legacy Guest',
        },
        '8': { status: 'completed', reservedBy: 'guest_legacy', completedAt: new Date().toISOString() },
      },
      members: ['member@test.com'],
    });

    // Migration : création docs sous-collection (fenêtre v1)
    await assertSucceeds(
      hizbCol(member, 'legacy1').doc('7').set({
        hizbNumber: 7,
        status: 'reserved',
        reservedBy: 'guest_legacy',
        reservedForName: 'Legacy Guest',
      }),
    );
    await assertSucceeds(
      hizbCol(member, 'legacy1').doc('8').set({
        hizbNumber: 8,
        status: 'completed',
        reservedBy: 'guest_legacy',
        completedAt: new Date().toISOString(),
      }),
    );
    await assertSucceeds(
      creator.collection('khatmat').doc('legacy1').update({
        reservationSchemaVersion: 2,
        completedHizbCount: 1,
      }),
    );

    // Deuxième migration : re-set même doc → échec car v2 + reservedBy != caller
    await assertFails(
      hizbCol(member, 'legacy1').doc('7').set({
        hizbNumber: 7,
        status: 'reserved',
        reservedBy: 'guest_legacy',
      }),
    );
  });

  await testEnv.cleanup();
  console.log(`\n${passed} passed, ${failed} failed`);
  process.exit(failed > 0 ? 1 : 0);
}

main().catch((e) => {
  console.error(e);
  process.exit(1);
});
