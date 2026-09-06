/**
 * SERVER-AUTHORITATIVE KHATMA VALIDATION
 * 
 * This test validates the new architecture where:
 * - All Khatma/reservation WRITES are server-authoritative (client writes denied)
 * - Client READS remain authorized for participants
 * - Unknown paths are denied
 */

const fs = require('fs');
const path = require('path');
const { initializeTestEnvironment } = require('@firebase/rules-unit-testing');

const RULES = fs.readFileSync(path.resolve(__dirname, '../../firestore.rules'), 'utf8');

async function main() {
  const testEnv = await initializeTestEnvironment({
    projectId: 'anis-test-server-auth',
    firestore: { rules: RULES },
  });

  let passed = 0;
  let failed = 0;

  const test = async (name, fn) => {
    process.stdout.write(`  ${name} ... `);
    try {
      await testEnv.clearFirestore();
      await fn(testEnv);
      console.log('PASS');
      passed++;
    } catch (err) {
      console.log('FAIL');
      console.error(err);
      failed++;
    }
  };

  console.log('\nServer-Authoritative Khatma Validation');
  
  await test('1. Authorized user can READ Khatma they created', async (testEnv) => {
    const creator = 'creator@test.com';
    const khatmaId = 'test-khatma-001';
    
    // Setup: admin seeds the Khatma (simulating server-side creation)
    await testEnv.withSecurityRulesDisabled(async (ctx) => {
      await ctx.firestore().collection('khatmat').doc(khatmaId).set({
        creatorEmail: creator,
        creatorId: 'creator-uid',
        members: [creator],
        participantIds: [creator],
        title: 'Test Khatma',
        status: 'ready',
        initializing: false,
        createdAt: new Date(),
        completedHizbCount: 0
      });
    });
    
    // Test: creator can read
    const creatorCtx = testEnv.authenticatedContext(creator, { email: creator });
    const doc = await creatorCtx.firestore().collection('khatmat').doc(khatmaId).get();
    
    if (!doc.exists) throw new Error('Expected Khatma to be readable by creator');
  });
  
  await test('2. Participant can READ Khatma they joined', async (testEnv) => {
    const creator = 'creator@test.com';
    const participant = 'participant@test.com';
    const khatmaId = 'test-khatma-002';
    
    // Setup
    await testEnv.withSecurityRulesDisabled(async (ctx) => {
      await ctx.firestore().collection('khatmat').doc(khatmaId).set({
        creatorEmail: creator,
        creatorId: 'creator-uid',
        members: [creator],
        participantIds: [creator, participant],
        title: 'Collaborative Khatma',
        status: 'ready',
        initializing: false,
        createdAt: new Date(),
        completedHizbCount: 0
      });
    });
    
    // Test: participant can read
    const participantCtx = testEnv.authenticatedContext(participant, { email: participant });
    const doc = await participantCtx.firestore().collection('khatmat').doc(khatmaId).get();
    
    if (!doc.exists) throw new Error('Expected Khatma to be readable by participant');
  });
  
  await test('3. Outsider CANNOT READ Khatma', async (testEnv) => {
    const creator = 'creator@test.com';
    const outsider = 'outsider@test.com';
    const khatmaId = 'test-khatma-003';
    
    // Setup
    await testEnv.withSecurityRulesDisabled(async (ctx) => {
      await ctx.firestore().collection('khatmat').doc(khatmaId).set({
        creatorEmail: creator,
        creatorId: 'creator-uid',
        members: [creator],
        participantIds: [creator],
        title: 'Private Khatma',
        status: 'ready',
        initializing: false,
        createdAt: new Date(),
        completedHizbCount: 0
      });
    });
    
    // Test: outsider cannot read
    const outsiderCtx = testEnv.authenticatedContext(outsider, { email: outsider });
    let denied = false;
    try {
      await outsiderCtx.firestore().collection('khatmat').doc(khatmaId).get();
    } catch (err) {
      if (err.code === 'permission-denied') denied = true;
    }
    
    if (!denied) throw new Error('Expected outsider to be denied read access');
  });
  
  await test('4. Client CANNOT CREATE Khatma (server-authoritative)', async (testEnv) => {
    const creator = 'creator@test.com';
    const khatmaId = 'test-khatma-004';
    
    const creatorCtx = testEnv.authenticatedContext(creator, { email: creator });
    let denied = false;
    try {
      await creatorCtx.firestore().collection('khatmat').doc(khatmaId).set({
        creatorEmail: creator,
        creatorId: 'creator-uid',
        members: [creator],
        participantIds: [creator],
        title: 'Client Created Khatma',
        status: 'ready',
        initializing: false,
        createdAt: new Date(),
        completedHizbCount: 0
      });
    } catch (err) {
      if (err.code === 'permission-denied') denied = true;
    }
    
    if (!denied) throw new Error('Expected client Khatma creation to be denied');
  });
  
  await test('5. Client CANNOT UPDATE Khatma (server-authoritative)', async (testEnv) => {
    const creator = 'creator@test.com';
    const khatmaId = 'test-khatma-005';
    
    // Setup
    await testEnv.withSecurityRulesDisabled(async (ctx) => {
      await ctx.firestore().collection('khatmat').doc(khatmaId).set({
        creatorEmail: creator,
        creatorId: 'creator-uid',
        members: [creator],
        participantIds: [creator],
        title: 'Original Title',
        status: 'ready',
        initializing: false,
        createdAt: new Date(),
        completedHizbCount: 0
      });
    });
    
    // Test: creator cannot update
    const creatorCtx = testEnv.authenticatedContext(creator, { email: creator });
    let denied = false;
    try {
      await creatorCtx.firestore().collection('khatmat').doc(khatmaId).update({
        title: 'Modified Title',
        completedHizbCount: 5
      });
    } catch (err) {
      if (err.code === 'permission-denied') denied = true;
    }
    
    if (!denied) throw new Error('Expected client Khatma update to be denied');
  });
  
  await test('6. Client CANNOT CREATE hizb_reservation (server-authoritative)', async (testEnv) => {
    const creator = 'creator@test.com';
    const khatmaId = 'test-khatma-006';
    
    // Setup: Khatma exists
    await testEnv.withSecurityRulesDisabled(async (ctx) => {
      await ctx.firestore().collection('khatmat').doc(khatmaId).set({
        creatorEmail: creator,
        creatorId: 'creator-uid',
        members: [creator],
        participantIds: [creator],
        title: 'Test Khatma',
        status: 'ready',
        initializing: false,
        createdAt: new Date(),
        completedHizbCount: 0
      });
    });
    
    // Test: client cannot create reservation
    const creatorCtx = testEnv.authenticatedContext(creator, { email: creator });
    let denied = false;
    try {
      await creatorCtx.firestore()
        .collection('khatmat').doc(khatmaId)
        .collection('hizb_reservations').doc('1').set({
          hizbNumber: 1,
          status: 'reserved',
          reservedBy: creator,
          reservedAt: new Date(),
          assigneeKind: 'self'
        });
    } catch (err) {
      if (err.code === 'permission-denied') denied = true;
    }
    
    if (!denied) throw new Error('Expected client hizb_reservation creation to be denied');
  });
  
  await test('7. Client CANNOT UPDATE hizb_reservation (server-authoritative)', async (testEnv) => {
    const creator = 'creator@test.com';
    const khatmaId = 'test-khatma-007';
    
    // Setup: Khatma + reservation exist
    await testEnv.withSecurityRulesDisabled(async (ctx) => {
      const fs = ctx.firestore();
      await fs.collection('khatmat').doc(khatmaId).set({
        creatorEmail: creator,
        creatorId: 'creator-uid',
        members: [creator],
        participantIds: [creator],
        title: 'Test Khatma',
        status: 'ready',
        initializing: false,
        createdAt: new Date(),
        completedHizbCount: 0
      });
      await fs.collection('khatmat').doc(khatmaId)
        .collection('hizb_reservations').doc('1').set({
          hizbNumber: 1,
          status: 'reserved',
          reservedBy: creator,
          reservedAt: new Date(),
          assigneeKind: 'self'
        });
    });
    
    // Test: client cannot update reservation
    const creatorCtx = testEnv.authenticatedContext(creator, { email: creator });
    let denied = false;
    try {
      await creatorCtx.firestore()
        .collection('khatmat').doc(khatmaId)
        .collection('hizb_reservations').doc('1').update({
          status: 'completed',
          completedAt: new Date()
        });
    } catch (err) {
      if (err.code === 'permission-denied') denied = true;
    }
    
    if (!denied) throw new Error('Expected client hizb_reservation update to be denied');
  });
  
  await test('8. Client CAN READ hizb_reservation (authorized participant)', async (testEnv) => {
    const creator = 'creator@test.com';
    const participant = 'participant@test.com';
    const khatmaId = 'test-khatma-008';
    
    // Setup
    await testEnv.withSecurityRulesDisabled(async (ctx) => {
      const fs = ctx.firestore();
      await fs.collection('khatmat').doc(khatmaId).set({
        creatorEmail: creator,
        creatorId: 'creator-uid',
        members: [creator],
        participantIds: [creator, participant],
        title: 'Test Khatma',
        status: 'ready',
        initializing: false,
        createdAt: new Date(),
        completedHizbCount: 0
      });
      await fs.collection('khatmat').doc(khatmaId)
        .collection('hizb_reservations').doc('1').set({
          hizbNumber: 1,
          status: 'available'
        });
    });
    
    // Test: participant can read
    const participantCtx = testEnv.authenticatedContext(participant, { email: participant });
    const doc = await participantCtx.firestore()
      .collection('khatmat').doc(khatmaId)
      .collection('hizb_reservations').doc('1').get();
    
    if (!doc.exists) throw new Error('Expected participant to read hizb_reservation');
  });
  
  await test('9. Unknown path denied', async (testEnv) => {
    const user = 'user@test.com';
    const userCtx = testEnv.authenticatedContext(user, { email: user });
    
    let denied = false;
    try {
      await userCtx.firestore().collection('unknown_collection').doc('test').set({ data: 'test' });
    } catch (err) {
      if (err.code === 'permission-denied') denied = true;
    }
    
    if (!denied) throw new Error('Expected unknown path to be denied');
  });
  
  await test('10. No "1000 expressions" error on rule evaluation', async (testEnv) => {
    // This test ensures the simplified rules don't hit expression limits
    // by attempting multiple operations that would have triggered complex evaluation
    const creator = 'creator@test.com';
    const khatmaId = 'test-khatma-010';
    
    // Setup
    await testEnv.withSecurityRulesDisabled(async (ctx) => {
      await ctx.firestore().collection('khatmat').doc(khatmaId).set({
        creatorEmail: creator,
        creatorId: 'creator-uid',
        members: [creator],
        participantIds: [creator],
        title: 'Test Khatma',
        status: 'ready',
        initializing: false,
        createdAt: new Date(),
        completedHizbCount: 0
      });
    });
    
    // Test: denied write should return permission-denied, not "1000 expressions" evaluation error
    const creatorCtx = testEnv.authenticatedContext(creator, { email: creator });
    
    let gotPermissionDenied = false;
    let gotEvaluationError = false;
    
    try {
      await creatorCtx.firestore()
        .collection('khatmat').doc(khatmaId)
        .collection('hizb_reservations').doc('1').set({
          hizbNumber: 1,
          status: 'reserved'
        });
    } catch (err) {
      if (err.code === 'permission-denied') gotPermissionDenied = true;
      const msg = String(err.message || '');
      if (msg.includes('1000 expressions') || msg.includes('maximum 1000')) {
        gotEvaluationError = true;
      }
    }
    
    if (gotEvaluationError) {
      throw new Error('Encountered "1000 expressions" evaluation error - rules too complex');
    }
    if (!gotPermissionDenied) {
      throw new Error('Expected permission-denied for client write');
    }
  });

  await testEnv.cleanup();
  
  console.log(`\n${passed} passed, ${failed} failed\n`);
  process.exit(failed > 0 ? 1 : 0);
}

main().catch((err) => {
  console.error('Fatal error:', err);
  process.exit(1);
});
