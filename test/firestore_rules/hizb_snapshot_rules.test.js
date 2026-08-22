/**
 * Tests immuabilité snapshot Hizb canonique.
 * Lancer : cd test/firestore_rules && node hizb_snapshot_rules.test.js
 */
const fs = require('fs');
const path = require('path');
const {
  initializeTestEnvironment,
  assertFails,
  assertSucceeds,
} = require('@firebase/rules-unit-testing');

const PROJECT_ID = 'anis-hizb-snapshot-rules';
const rulesPath = path.resolve(__dirname, '../../firestore.rules');
const CANONICAL = 'quran_foundation_hafs_v1';

const h44Snapshot = {
  hizbNumber: 44,
  status: 'available',
  hizbDefinitionId: CANONICAL,
  startVerseKey: '34:24',
  endVerseKey: '36:27',
  startPageHafs: 431,
  endPageHafs: 441,
};

function authedDb(testEnv, uid, email) {
  return testEnv.authenticatedContext(uid, email ? { email } : {}).firestore();
}

function hizbCol(db, khatmaId) {
  return db.collection('khatmat').doc(khatmaId).collection('hizb_reservations');
}

async function seedKhatma(testEnv, khatmaId, overrides = {}) {
  await testEnv.withSecurityRulesDisabled(async (ctx) => {
    await ctx.firestore().collection('khatmat').doc(khatmaId).set({
      title: 'K',
      createdBy: 'creator@test.com',
      createdAt: new Date().toISOString(),
      isGroup: true,
      reservationMode: true,
      reservationSchemaVersion: 2,
      hizbDefinitionId: CANONICAL,
      members: ['member@test.com'],
      participantIds: ['creator@test.com', 'member@test.com'],
      ...overrides,
    });
  });
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

  await test('création Khatma reservation exige hizbDefinitionId', async () => {
    const creator = authedDb(testEnv, 'c', 'creator@test.com');
    await assertFails(
      creator.collection('khatmat').add({
        title: 'Sans définition',
        createdBy: 'creator@test.com',
        createdAt: new Date().toISOString(),
        isGroup: true,
        reservationMode: true,
        reservationSchemaVersion: 2,
      }),
    );
    await assertSucceeds(
      creator.collection('khatmat').add({
        title: 'Canonique',
        createdBy: 'creator@test.com',
        createdAt: new Date().toISOString(),
        isGroup: true,
        reservationMode: true,
        reservationSchemaVersion: 2,
        hizbDefinitionId: CANONICAL,
        participantIds: ['creator@test.com'],
      }),
    );
  });

  await test('mauvaise hizbDefinitionId refusée à la création', async () => {
    const creator = authedDb(testEnv, 'c', 'creator@test.com');
    await assertFails(
      creator.collection('khatmat').add({
        title: 'Mauvaise définition',
        createdBy: 'creator@test.com',
        createdAt: new Date().toISOString(),
        isGroup: true,
        reservationMode: true,
        reservationSchemaVersion: 2,
        hizbDefinitionId: 'wrong_definition',
        participantIds: ['creator@test.com'],
      }),
    );
  });

  await test('init snapshot H44 par créateur', async () => {
    await seedKhatma(testEnv, 'k1');
    const creator = authedDb(testEnv, 'c', 'creator@test.com');
    await assertSucceeds(hizbCol(creator, 'k1').doc('44').set(h44Snapshot));
  });

  await test('modification startVerseKey refusée', async () => {
    await seedKhatma(testEnv, 'k2');
    await testEnv.withSecurityRulesDisabled(async (ctx) => {
      await hizbCol(ctx.firestore(), 'k2').doc('44').set(h44Snapshot);
    });
    const member = authedDb(testEnv, 'm', 'member@test.com');
    await assertFails(
      hizbCol(member, 'k2').doc('44').update({ startVerseKey: '30:31' }),
    );
  });

  await test('modification endVerseKey refusée', async () => {
    await seedKhatma(testEnv, 'k2b');
    await testEnv.withSecurityRulesDisabled(async (ctx) => {
      await hizbCol(ctx.firestore(), 'k2b').doc('44').set(h44Snapshot);
    });
    const member = authedDb(testEnv, 'm', 'member@test.com');
    await assertFails(
      hizbCol(member, 'k2b').doc('44').update({ endVerseKey: '40:1' }),
    );
  });

  await test('modification startPageHafs refusée', async () => {
    await seedKhatma(testEnv, 'k2c');
    await testEnv.withSecurityRulesDisabled(async (ctx) => {
      await hizbCol(ctx.firestore(), 'k2c').doc('44').set(h44Snapshot);
    });
    const member = authedDb(testEnv, 'm', 'member@test.com');
    await assertFails(
      hizbCol(member, 'k2c').doc('44').update({ startPageHafs: 407 }),
    );
  });

  await test('modification endPageHafs refusée', async () => {
    await seedKhatma(testEnv, 'k2d');
    await testEnv.withSecurityRulesDisabled(async (ctx) => {
      await hizbCol(ctx.firestore(), 'k2d').doc('44').set(h44Snapshot);
    });
    const member = authedDb(testEnv, 'm', 'member@test.com');
    await assertFails(
      hizbCol(member, 'k2d').doc('44').update({ endPageHafs: 500 }),
    );
  });

  await test('modification hizbNumber refusée', async () => {
    await seedKhatma(testEnv, 'k2e');
    await testEnv.withSecurityRulesDisabled(async (ctx) => {
      await hizbCol(ctx.firestore(), 'k2e').doc('44').set({
        ...h44Snapshot,
        status: 'reserved',
        reservedBy: 'member@test.com',
      });
    });
    const member = authedDb(testEnv, 'm', 'member@test.com');
    await assertFails(
      hizbCol(member, 'k2e').doc('44').update({ hizbNumber: 99 }),
    );
  });

  await test('modification hizbDefinitionId refusée', async () => {
    await seedKhatma(testEnv, 'k2f');
    await testEnv.withSecurityRulesDisabled(async (ctx) => {
      await hizbCol(ctx.firestore(), 'k2f').doc('44').set({
        ...h44Snapshot,
        status: 'reserved',
        reservedBy: 'member@test.com',
      });
    });
    const member = authedDb(testEnv, 'm', 'member@test.com');
    await assertFails(
      hizbCol(member, 'k2f').doc('44').update({ hizbDefinitionId: 'wrong' }),
    );
  });

  await test('changement status légitime autorisé', async () => {
    await seedKhatma(testEnv, 'k3');
    await testEnv.withSecurityRulesDisabled(async (ctx) => {
      await hizbCol(ctx.firestore(), 'k3').doc('44').set({
        ...h44Snapshot,
        status: 'reserved',
        reservedBy: 'member@test.com',
      });
    });
    const member = authedDb(testEnv, 'm', 'member@test.com');
    await assertSucceeds(
      hizbCol(member, 'k3').doc('44').update({ status: 'inProgress' }),
    );
  });

  await test('reserve légitime autorisé', async () => {
    await seedKhatma(testEnv, 'k4');
    await testEnv.withSecurityRulesDisabled(async (ctx) => {
      await hizbCol(ctx.firestore(), 'k4').doc('44').set(h44Snapshot);
    });
    const member = authedDb(testEnv, 'm', 'member@test.com');
    const now = new Date().toISOString();
    await assertSucceeds(
      hizbCol(member, 'k4').doc('44').set({
        ...h44Snapshot,
        status: 'reserved',
        reservedBy: 'member@test.com',
        reservedAt: now,
        expiresAt: now,
      }),
    );
  });

  await test('libération préserve snapshot', async () => {
    await seedKhatma(testEnv, 'k5');
    await testEnv.withSecurityRulesDisabled(async (ctx) => {
      await hizbCol(ctx.firestore(), 'k5').doc('44').set({
        ...h44Snapshot,
        status: 'reserved',
        reservedBy: 'member@test.com',
      });
    });
    const member = authedDb(testEnv, 'm', 'member@test.com');
    await assertSucceeds(hizbCol(member, 'k5').doc('44').set(h44Snapshot));
  });

  await test('autre membre ne vole pas réservation', async () => {
    await seedKhatma(testEnv, 'k6', { members: ['member@test.com', 'other@test.com'] });
    await testEnv.withSecurityRulesDisabled(async (ctx) => {
      await hizbCol(ctx.firestore(), 'k6').doc('44').set({
        ...h44Snapshot,
        status: 'reserved',
        reservedBy: 'member@test.com',
      });
    });
    const other = authedDb(testEnv, 'o', 'other@test.com');
    await assertFails(
      hizbCol(other, 'k6').doc('44').update({ status: 'inProgress' }),
    );
  });

  await test('guest autorisé dans son périmètre', async () => {
    await seedKhatma(testEnv, 'k7', {
      guestParticipants: { guest_uid: 'Invité' },
      members: [],
      participantIds: ['creator@test.com', 'guest_uid'],
    });
    const guest = authedDb(testEnv, 'guest_uid');
    const now = new Date().toISOString();
    await assertSucceeds(
      hizbCol(guest, 'k7').doc('15').set({
        hizbNumber: 15,
        status: 'reserved',
        reservedBy: 'guest_uid',
        reservedAt: now,
        expiresAt: now,
        hizbDefinitionId: CANONICAL,
        startVerseKey: '2:1',
        endVerseKey: '2:10',
        startPageHafs: 2,
        endPageHafs: 3,
      }),
    );
  });

  await test('guest ne touche pas réservation d\'un autre guest', async () => {
    await seedKhatma(testEnv, 'k8', {
      guestParticipants: { guest_a: 'A', guest_b: 'B' },
      members: [],
      participantIds: ['creator@test.com', 'guest_a', 'guest_b'],
    });
    await testEnv.withSecurityRulesDisabled(async (ctx) => {
      await hizbCol(ctx.firestore(), 'k8').doc('12').set({
        hizbNumber: 12,
        status: 'reserved',
        reservedBy: 'guest_a',
        hizbDefinitionId: CANONICAL,
        startVerseKey: '2:1',
        endVerseKey: '2:10',
        startPageHafs: 2,
        endPageHafs: 3,
      });
    });
    const guestB = authedDb(testEnv, 'guest_b');
    await assertFails(
      hizbCol(guestB, 'k8').doc('12').update({ status: 'inProgress' }),
    );
  });

  await test('outsider refusé', async () => {
    await seedKhatma(testEnv, 'k9');
    const outsider = authedDb(testEnv, 'out', 'out@test.com');
    const now = new Date().toISOString();
    await assertFails(
      hizbCol(outsider, 'k9').doc('10').set({
        hizbNumber: 10,
        status: 'reserved',
        reservedBy: 'out@test.com',
        reservedAt: now,
        expiresAt: now,
        hizbDefinitionId: CANONICAL,
        startVerseKey: '1:1',
        endVerseKey: '1:10',
        startPageHafs: 1,
        endPageHafs: 2,
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
