/**
 * Certification E2E Firestore — scénarios User A / B / Guest / Outsider.
 * Lancer : cd test/firestore_rules && node certification_e2e.test.js
 */
const fs = require('fs');
const path = require('path');
const {
  initializeTestEnvironment,
  assertFails,
  assertSucceeds,
} = require('@firebase/rules-unit-testing');

const PROJECT_ID = 'anis-cert-e2e';
const rulesPath = path.resolve(__dirname, '../../firestore.rules');
const SUBCOLLECTION = 'hizb_reservations';

const CANONICAL_DEFINITION = 'quran_foundation_hafs_v1';

const baseKhatma = (overrides = {}) => ({
  title: 'Khatma cert',
  createdBy: 'usera@test.com',
  createdAt: new Date().toISOString(),
  isGroup: true,
  reservationMode: true,
  isPublic: false,
  members: [],
  guestParticipants: {},
  participantIds: ['usera@test.com'],
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
  return { hizbNumber: n, status: 'reserved', reservedBy, ...canonicalSnapshot(n) };
}

function authedDb(testEnv, uid, email) {
  return testEnv.authenticatedContext(uid, email ? { email } : {}).firestore();
}

async function main() {
  const testEnv = await initializeTestEnvironment({
    projectId: PROJECT_ID,
    firestore: { rules: fs.readFileSync(rulesPath, 'utf8') },
  });

  let passed = 0;
  let failed = 0;

  async function test(name, fn) {
    await testEnv.clearFirestore();
    process.stdout.write(`  ${name} ... `);
    try {
      await fn();
      console.log('PASS');
      passed++;
    } catch (e) {
      console.log('FAIL');
      console.error(`    ${e.message || e}`);
      failed++;
    }
  }

  await test('E2E-A saveKhatma User A (email auth + createdBy match)', async () => {
    const userA = authedDb(testEnv, 'uid_a', 'usera@test.com');
    const ref = await assertSucceeds(
      userA.collection('khatmat').add({
        title: 'Cert A',
        createdBy: 'usera@test.com',
        createdAt: new Date().toISOString(),
        isGroup: true,
        participantIds: ['usera@test.com'],
      }),
    );
    await assertSucceeds(userA.collection('khatmat').doc(ref.id).get());
  });

  await test('E2E-A getMyKhatmat + load + reserve Hizb 44', async () => {
    await testEnv.withSecurityRulesDisabled(async (ctx) => {
      const db = ctx.firestore();
      await db.collection('khatmat').doc('ka').set(baseKhatma());
      await db.collection('khatmat').doc('ka').collection(SUBCOLLECTION).doc('44').set(availableDoc(44));
    });
    const userA = authedDb(testEnv, 'uid_a', 'usera@test.com');
    const list = await assertSucceeds(
      userA.collection('khatmat')
        .where('createdBy', '==', 'usera@test.com')
        .limit(100)
        .get(),
    );
    if (list.size !== 1) throw new Error(`getMyKhatmat: ${list.size}`);
    await assertSucceeds(userA.collection('khatmat').doc('ka').get());
    await assertSucceeds(
      userA.collection('khatmat').doc('ka').collection(SUBCOLLECTION).doc('44').set(
        reservedDoc(44, 'usera@test.com'),
      ),
    );
  });

  await test('E2E-B User B member — load + reserve autre Hizb', async () => {
    await testEnv.withSecurityRulesDisabled(async (ctx) => {
      const db = ctx.firestore();
      await db.collection('khatmat').doc('kb').set(
        baseKhatma({
          members: ['userb@test.com'],
          participantIds: ['usera@test.com', 'userb@test.com'],
        }),
      );
      await db.collection('khatmat').doc('kb').collection(SUBCOLLECTION).doc('13').set(availableDoc(13));
    });
    const userB = authedDb(testEnv, 'uid_b', 'userb@test.com');
    await assertSucceeds(userB.collection('khatmat').doc('kb').get());
    const snap = await assertSucceeds(
      userB.collection('khatmat')
        .where('members', 'array-contains', 'userb@test.com')
        .limit(100)
        .get(),
    );
    if (snap.size !== 1) throw new Error(`Mes Khatmas B: ${snap.size}`);
    await assertSucceeds(
      userB.collection('khatmat').doc('kb').collection(SUBCOLLECTION).doc('13').set(
        reservedDoc(13, 'userb@test.com'),
      ),
    );
  });

  await test('E2E-G Guest anonymous — join + reload + reserve', async () => {
    await testEnv.withSecurityRulesDisabled(async (ctx) => {
      await ctx.firestore().collection('khatmat').doc('kg').set(
        baseKhatma({ isPublic: true, createdBy: 'usera@test.com' }),
      );
    });
    const guest = authedDb(testEnv, 'guest_uid');
    await assertSucceeds(
      guest.collection('khatmat').doc('kg').update({
        guestParticipants: { 'guest_uid': 'Invité' },
        participantIds: ['usera@test.com', 'guest_uid'],
      }),
    );
    await assertSucceeds(guest.collection('khatmat').doc('kg').get());
    await assertSucceeds(
      guest.collection('khatmat').doc('kg').collection(SUBCOLLECTION).doc('60').set(
        reservedDoc(60, 'guest_uid'),
      ),
    );
  });

  await test('E2E-O Outsider — accès privé FAIL', async () => {
    await testEnv.withSecurityRulesDisabled(async (ctx) => {
      await ctx.firestore().collection('khatmat').doc('kp').set(baseKhatma());
    });
    const outsider = authedDb(testEnv, 'uid_o', 'outsider@test.com');
    await assertFails(outsider.collection('khatmat').doc('kp').get());
  });

  await test('E2E-P getPublicKhatmat — auth requis (pas unauthenticated)', async () => {
    await testEnv.withSecurityRulesDisabled(async (ctx) => {
      await ctx.firestore().collection('khatmat').doc('kpub').set(
        baseKhatma({ isPublic: true }),
      );
    });
    const unauth = testEnv.unauthenticatedContext().firestore();
    await assertFails(
      unauth.collection('khatmat').where('isPublic', '==', true).limit(50).get(),
    );
    const authed = authedDb(testEnv, 'any', 'any@test.com');
    const snap = await assertSucceeds(
      authed.collection('khatmat').where('isPublic', '==', true).limit(50).get(),
    );
    if (snap.size !== 1) throw new Error(`public list: ${snap.size}`);
  });

  await testEnv.cleanup();
  console.log(`\n${passed} passed, ${failed} failed`);
  process.exit(failed > 0 ? 1 : 0);
}

main().catch((e) => {
  console.error(e);
  process.exit(1);
});
