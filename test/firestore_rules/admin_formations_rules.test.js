/**
 * Tests Firestore Rules — Admin custom claims + Formations security
 *
 * Lancer : cd test/firestore_rules && node admin_formations_rules.test.js
 */
const fs = require('fs');
const path = require('path');
const {
  initializeTestEnvironment,
  assertFails,
  assertSucceeds,
} = require('@firebase/rules-unit-testing');

const PROJECT_ID = 'anis-admin-formations';
const rulesPath = path.resolve(__dirname, '../../firestore.rules');

async function test(name, fn) {
  try {
    await fn();
    console.log(`  ${name} ... PASS`);
    return true;
  } catch (err) {
    console.error(`  ${name} ... FAIL`);
    console.error(err);
    throw err;
  }
}

function authedDb(testEnv, uid, email) {
  return testEnv.authenticatedContext(uid, email ? { email } : {}).firestore();
}

async function main() {
  const testEnv = await initializeTestEnvironment({
    projectId: PROJECT_ID,
    firestore: {
      rules: fs.readFileSync(rulesPath, 'utf8'),
      host: 'localhost',
      port: 8080,
    },
  });

  let passed = 0;
  let failed = 0;

  // Test 1: Admin can delete khatma
  await test('admin can delete any khatma', async () => {
    await testEnv.withSecurityRulesDisabled(async (context) => {
      await context.firestore().collection('khatmat').doc('k1').set({
        title: 'Test',
        createdBy: 'someone@test.com',
        createdAt: new Date().toISOString(),
        isGroup: true,
      });
    });
    const admin = testEnv.authenticatedContext('admin', {
      email: 'admin@test.com',
      admin: true,
    });
    await assertSucceeds(admin.firestore().collection('khatmat').doc('k1').delete());
  });
  passed++;

  // Test 2: Non-admin cannot delete others' khatma
  await test('non-admin cannot delete others khatma', async () => {
    await testEnv.withSecurityRulesDisabled(async (context) => {
      await context.firestore().collection('khatmat').doc('k2').set({
        title: 'Test',
        createdBy: 'bob@test.com',
        createdAt: new Date().toISOString(),
        isGroup: true,
      });
    });
    const alice = authedDb(testEnv, 'alice', 'alice@test.com');
    await assertFails(alice.collection('khatmat').doc('k2').delete());
  });
  passed++;

  // Test 3: User can read courses
  await test('authenticated user can read courses', async () => {
    await testEnv.withSecurityRulesDisabled(async (context) => {
      await context.firestore().collection('courses').doc('c1').set({ title: 'Course 1' });
    });
    const alice = authedDb(testEnv, 'alice', 'alice@test.com');
    await assertSucceeds(alice.collection('courses').doc('c1').get());
  });
  passed++;

  // Test 4: Admin can create course
  await test('admin can create course', async () => {
    const admin = testEnv.authenticatedContext('admin', {
      email: 'admin@test.com',
      admin: true,
    });
    await assertSucceeds(admin.firestore().collection('courses').add({ title: 'Admin Course' }));
  });
  passed++;

  // Test 5: User can create question with own userId
  await test('user can create question with own userId', async () => {
    const alice = authedDb(testEnv, 'alice', 'alice@test.com');
    await assertSucceeds(
      alice.collection('questions').add({
        userId: 'alice',
        text: 'My question?',
      })
    );
  });
  passed++;

  // Test 6: User cannot create question with wrong userId
  await test('user cannot create question with wrong userId', async () => {
    const alice = authedDb(testEnv, 'alice', 'alice@test.com');
    await assertFails(
      alice.collection('questions').add({
        userId: 'bob',
        text: 'Fake question?',
      })
    );
  });
  passed++;

  await testEnv.cleanup();
  console.log(`\n${passed} passed, ${failed} failed`);
  console.log('✅ Admin + Formations rules tests completed');
  process.exit(failed > 0 ? 1 : 0);
}

main().catch((e) => {
  console.error(e);
  process.exit(1);
});
