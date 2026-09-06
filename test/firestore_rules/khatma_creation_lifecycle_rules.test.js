/**
 * Lifecycle creationState + outsider isolation.
 * Run via npm test in this directory.
 */
const fs = require('fs');
const path = require('path');
const {
  initializeTestEnvironment,
  assertFails,
  assertSucceeds,
} = require('@firebase/rules-unit-testing');

const PROJECT_ID = 'anis-creation-lifecycle';
const rulesPath = path.resolve(__dirname, '../../firestore.rules');
const CANONICAL = 'quran_foundation_hafs_v1';

function authedDb(testEnv, uid, email) {
  return testEnv.authenticatedContext(uid, email ? { email } : {}).firestore();
}

function parentDoc(email, state) {
  return {
    title: 'Lifecycle',
    createdBy: email,
    createdAt: new Date().toISOString(),
    isGroup: true,
    isPublic: false,
    reservationMode: true,
    reservationSchemaVersion: 2,
    hizbDefinitionId: CANONICAL,
    participantIds: [email],
    members: [],
    guestParticipants: {},
    completedHizbCount: 0,
    creationState: state,
  };
}

async function main() {
  const testEnv = await initializeTestEnvironment({
    projectId: PROJECT_ID,
    firestore: { rules: fs.readFileSync(rulesPath, 'utf8') },
  });

  let failed = 0;
  const test = async (name, fn) => {
    await testEnv.clearFirestore();
    process.stdout.write(`  ${name} ... `);
    try {
      await fn();
      console.log('PASS');
    } catch (e) {
      failed++;
      console.log('FAIL');
      console.error(e.message);
    }
  };

  await test('creator writes initializing parent', async () => {
    const db = authedDb(testEnv, 'c', 'creator@test.com');
    await assertSucceeds(
      db.collection('khatmat').doc('k1').set(parentDoc('creator@test.com', 'initializing')),
    );
  });

  await test('outsider cannot read initializing parent', async () => {
    const creator = authedDb(testEnv, 'c', 'creator@test.com');
    await creator.collection('khatmat').doc('k1').set(parentDoc('creator@test.com', 'initializing'));
    const outsider = authedDb(testEnv, 'o', 'out@test.com');
    await assertFails(outsider.collection('khatmat').doc('k1').get());
  });

  await test('initializing -> ready allowed for creator', async () => {
    const db = authedDb(testEnv, 'c', 'creator@test.com');
    await db.collection('khatmat').doc('k1').set(parentDoc('creator@test.com', 'initializing'));
    await assertSucceeds(
      db.collection('khatmat').doc('k1').update({ creationState: 'ready' }),
    );
  });

  await test('ready -> initializing denied', async () => {
    const db = authedDb(testEnv, 'c', 'creator@test.com');
    await db.collection('khatmat').doc('k1').set(parentDoc('creator@test.com', 'ready'));
    await assertFails(
      db.collection('khatmat').doc('k1').update({ creationState: 'initializing' }),
    );
  });

  await test('legacy missing creationState remains readable by creator', async () => {
    const db = authedDb(testEnv, 'c', 'creator@test.com');
    const legacy = parentDoc('creator@test.com', 'ready');
    delete legacy.creationState;
    await db.collection('khatmat').doc('k1').set(legacy);
    await assertSucceeds(db.collection('khatmat').doc('k1').get());
  });

  await test('member reserve self with assigneeKind', async () => {
    const creator = authedDb(testEnv, 'c', 'creator@test.com');
    const ready = parentDoc('creator@test.com', 'ready');
    ready.participantIds = ['creator@test.com', 'member@test.com'];
    ready.members = ['member@test.com'];
    await creator.collection('khatmat').doc('k1').set(ready);
    await creator.collection('khatmat').doc('k1').collection('hizb_reservations').doc('1').set({
      hizbNumber: 1,
      status: 'available',
      hizbDefinitionId: CANONICAL,
      startVerseKey: '1:1',
      endVerseKey: '2:74',
      startPageHafs: 1,
      endPageHafs: 11,
    });
    const member = authedDb(testEnv, 'm', 'member@test.com');
    await assertSucceeds(
      member.collection('khatmat').doc('k1').collection('hizb_reservations').doc('1').set({
        hizbNumber: 1,
        status: 'reserved',
        reservedBy: 'member@test.com',
        assigneeKind: 'self',
        assigneeUserId: 'member@test.com',
        hizbDefinitionId: CANONICAL,
        startVerseKey: '1:1',
        endVerseKey: '2:74',
        startPageHafs: 1,
        endPageHafs: 11,
      }),
    );
  });

  await test('member reserve offline Fatima without UID', async () => {
    const creator = authedDb(testEnv, 'c', 'creator@test.com');
    const ready = parentDoc('creator@test.com', 'ready');
    ready.participantIds = ['creator@test.com', 'member@test.com'];
    ready.members = ['member@test.com'];
    await creator.collection('khatmat').doc('k1').set(ready);
    await creator.collection('khatmat').doc('k1').collection('hizb_reservations').doc('2').set({
      hizbNumber: 2,
      status: 'available',
      hizbDefinitionId: CANONICAL,
      startVerseKey: '1:1',
      endVerseKey: '2:74',
      startPageHafs: 1,
      endPageHafs: 11,
    });
    const member = authedDb(testEnv, 'm', 'member@test.com');
    await assertSucceeds(
      member.collection('khatmat').doc('k1').collection('hizb_reservations').doc('2').set({
        hizbNumber: 2,
        status: 'reserved',
        reservedBy: 'member@test.com',
        assigneeKind: 'offline',
        assigneeDisplayName: 'Fatima',
        hizbDefinitionId: CANONICAL,
        startVerseKey: '1:1',
        endVerseKey: '2:74',
        startPageHafs: 1,
        endPageHafs: 11,
      }),
    );
  });

  await test('offline reservation with fake UID denied', async () => {
    const creator = authedDb(testEnv, 'c', 'creator@test.com');
    const ready = parentDoc('creator@test.com', 'ready');
    ready.participantIds = ['creator@test.com', 'member@test.com'];
    ready.members = ['member@test.com'];
    await creator.collection('khatmat').doc('k1').set(ready);
    await creator.collection('khatmat').doc('k1').collection('hizb_reservations').doc('3').set({
      hizbNumber: 3,
      status: 'available',
      hizbDefinitionId: CANONICAL,
      startVerseKey: '1:1',
      endVerseKey: '2:74',
      startPageHafs: 1,
      endPageHafs: 11,
    });
    const member = authedDb(testEnv, 'm', 'member@test.com');
    await assertFails(
      member.collection('khatmat').doc('k1').collection('hizb_reservations').doc('3').set({
        hizbNumber: 3,
        status: 'reserved',
        reservedBy: 'member@test.com',
        assigneeKind: 'offline',
        assigneeUserId: 'fake-uid-123',
        assigneeDisplayName: 'Fatima',
        hizbDefinitionId: CANONICAL,
        startVerseKey: '1:1',
        endVerseKey: '2:74',
        startPageHafs: 1,
        endPageHafs: 11,
      }),
    );
  });

  await test('organizer assigns ANIS participant', async () => {
    const creator = authedDb(testEnv, 'c', 'creator@test.com');
    const ready = parentDoc('creator@test.com', 'ready');
    ready.participantIds = ['creator@test.com', 'member@test.com'];
    ready.members = ['member@test.com'];
    await creator.collection('khatmat').doc('k1').set(ready);
    await creator.collection('khatmat').doc('k1').collection('hizb_reservations').doc('4').set({
      hizbNumber: 4,
      status: 'available',
      hizbDefinitionId: CANONICAL,
      startVerseKey: '1:1',
      endVerseKey: '2:74',
      startPageHafs: 1,
      endPageHafs: 11,
    });
    await assertSucceeds(
      creator.collection('khatmat').doc('k1').collection('hizb_reservations').doc('4').set({
        hizbNumber: 4,
        status: 'reserved',
        reservedBy: 'member@test.com',
        assigneeKind: 'participant',
        assigneeUserId: 'member@test.com',
        assignedByUserId: 'creator@test.com',
        hizbDefinitionId: CANONICAL,
        startVerseKey: '1:1',
        endVerseKey: '2:74',
        startPageHafs: 1,
        endPageHafs: 11,
      }),
    );
  });

  await test('forged assigneeKind participant by non-creator denied', async () => {
    const creator = authedDb(testEnv, 'c', 'creator@test.com');
    const ready = parentDoc('creator@test.com', 'ready');
    ready.participantIds = ['creator@test.com', 'member@test.com'];
    ready.members = ['member@test.com'];
    await creator.collection('khatmat').doc('k1').set(ready);
    await creator
      .collection('khatmat')
      .doc('k1')
      .collection('hizb_reservations')
      .doc('1')
      .set({
        hizbNumber: 1,
        status: 'available',
        hizbDefinitionId: CANONICAL,
        startVerseKey: '1:1',
        endVerseKey: '2:74',
        startPageHafs: 1,
        endPageHafs: 11,
      });
    const member = authedDb(testEnv, 'm', 'member@test.com');
    await assertFails(
      member
        .collection('khatmat')
        .doc('k1')
        .collection('hizb_reservations')
        .doc('1')
        .set({
          hizbNumber: 1,
          status: 'reserved',
          reservedBy: 'victim@test.com',
          assigneeKind: 'participant',
          assigneeUserId: 'victim@test.com',
          assignedByUserId: 'member@test.com',
          hizbDefinitionId: CANONICAL,
          startVerseKey: '1:1',
          endVerseKey: '2:74',
          startPageHafs: 1,
          endPageHafs: 11,
        }),
    );
  });

  await test('canonical snapshot mutation denied', async () => {
    const creator = authedDb(testEnv, 'c', 'creator@test.com');
    const ready = parentDoc('creator@test.com', 'ready');
    ready.participantIds = ['creator@test.com', 'member@test.com'];
    ready.members = ['member@test.com'];
    await creator.collection('khatmat').doc('k1').set(ready);
    await creator.collection('khatmat').doc('k1').collection('hizb_reservations').doc('5').set({
      hizbNumber: 5,
      status: 'available',
      hizbDefinitionId: CANONICAL,
      startVerseKey: '1:1',
      endVerseKey: '2:74',
      startPageHafs: 1,
      endPageHafs: 11,
    });
    const member = authedDb(testEnv, 'm', 'member@test.com');
    await assertFails(
      member.collection('khatmat').doc('k1').collection('hizb_reservations').doc('5').update({
        startVerseKey: '99:1',
      }),
    );
  });

  await test('canonical reservation delete denied', async () => {
    const creator = authedDb(testEnv, 'c', 'creator@test.com');
    const ready = parentDoc('creator@test.com', 'ready');
    await creator.collection('khatmat').doc('k1').set(ready);
    await creator.collection('khatmat').doc('k1').collection('hizb_reservations').doc('6').set({
      hizbNumber: 6,
      status: 'available',
      hizbDefinitionId: CANONICAL,
      startVerseKey: '1:1',
      endVerseKey: '2:74',
      startPageHafs: 1,
      endPageHafs: 11,
    });
    const member = authedDb(testEnv, 'm', 'member@test.com');
    await assertFails(
      member.collection('khatmat').doc('k1').collection('hizb_reservations').doc('6').delete(),
    );
  });

  await testEnv.cleanup();
  process.exit(failed === 0 ? 0 : 1);
}

main().catch((e) => {
  console.error(e);
  process.exit(1);
});
