/** Sonde temporaire : localiser le dépassement du budget d'expressions. */
const fs = require('fs');
const path = require('path');
const { initializeTestEnvironment } = require('@firebase/rules-unit-testing');

const rulesPath = path.resolve(__dirname, '../../firestore.rules');

const baseKhatma = (overrides = {}) => ({
  title: 'Khatma test',
  createdBy: 'creator@test.com',
  createdAt: new Date().toISOString(),
  isGroup: true,
  reservationMode: true,
  isPublic: false,
  members: ['member@test.com'],
  guestParticipants: {},
  participantIds: [],
  hizbAssignments: {},
  hizbReservations: {},
  reservationSchemaVersion: 2,
  completedHizbCount: 0,
  ...overrides,
});

async function main() {
  const testEnv = await initializeTestEnvironment({
    projectId: 'probe-budget',
    firestore: { rules: fs.readFileSync(rulesPath, 'utf8') },
  });

  const db = (uid, email) =>
    testEnv.authenticatedContext(uid, email ? { email } : {}).firestore();

  const probe = async (name, seedOverrides, uid, email, payload) => {
    await testEnv.clearFirestore();
    await testEnv.withSecurityRulesDisabled(async (ctx) => {
      await ctx.firestore().collection('khatmat').doc('k').set(baseKhatma(seedOverrides));
    });
    try {
      await db(uid, email).collection('khatmat').doc('k').update(payload);
      console.log(`  ${name} -> ALLOWED`);
    } catch (e) {
      const msg = String(e.message || e);
      const kind = msg.includes('maximum of 1000') ? 'BUDGET-OVERFLOW' : 'DENIED';
      console.log(`  ${name} -> ${kind}`);
    }
  };

  console.log('\n-- créateur --');
  await probe('A. creator 0->1', {}, 'c', 'creator@test.com', { completedHizbCount: 1 });

  console.log('\n-- membre, incrément valide --');
  await probe('B. member 0->1', {}, 'm', 'member@test.com', { completedHizbCount: 1 });
  await probe('C. member 59->60', { completedHizbCount: 59 }, 'm', 'member@test.com', {
    completedHizbCount: 60,
  });
  await probe('D. member 59->60 + completedAt', { completedHizbCount: 59 }, 'm', 'member@test.com', {
    completedHizbCount: 60,
    completedAt: new Date(),
  });

  console.log('\n-- membre, incrément invalide (doit être refusé) --');
  await probe('E. member 0->59', {}, 'm', 'member@test.com', { completedHizbCount: 59 });

  console.log('\n-- influence de la taille du document --');
  const bigMap = {};
  for (let i = 1; i <= 60; i++) bigMap[String(i)] = { status: 'reserved', reservedBy: 'x@t.com' };
  await probe('F. member 59->60, hizbReservations 60 entrées',
    { completedHizbCount: 59, hizbReservations: bigMap }, 'm', 'member@test.com',
    { completedHizbCount: 60, completedAt: new Date() });

  const manyMembers = [];
  for (let i = 0; i < 60; i++) manyMembers.push(`u${i}@test.com`);
  manyMembers.push('member@test.com');
  await probe('G. member 59->60, 61 membres',
    { completedHizbCount: 59, members: manyMembers }, 'm', 'member@test.com',
    { completedHizbCount: 60, completedAt: new Date() });

  await testEnv.cleanup();
}

main().catch((e) => {
  console.error(e);
  process.exit(1);
});
