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

  try {
    // Setup test data first with security disabled
    await testEnv.withSecurityRulesDisabled(async (context) => {
      await context.firestore().collection('khatmat').doc('k1').set({
        title: 'Test',
        createdBy: 'someone@test.com',
        createdAt: new Date().toISOString(),
        isGroup: true,
      });
      await context.firestore().collection('khatmat').doc('k2').set({
        title: 'Test',
        createdBy: 'bob@test.com',
        createdAt: new Date().toISOString(),
        isGroup: true,
      });
      await context.firestore().collection('courses').doc('c1').set({ title: 'Course 1' });
      await context.firestore().collection('lives').doc('l1').set({ title: 'Live 1' });
      await context.firestore().collection('weekly_qa').doc('qa1').set({
        question: 'Q?',
        answer: 'A!',
      });
    });

    const admin = testEnv.authenticatedContext('admin', {
      email: 'admin@test.com',
      admin: true,
    });
    const alice = testEnv.authenticatedContext('alice', { email: 'alice@test.com' });

    // Admin can delete any khatma
    await test('admin can delete any khatma', async () => {
      await assertSucceeds(admin.firestore().collection('khatmat').doc('k1').delete());
    });
    passed++;

    // Non-admin cannot delete others' khatma
    await test('non-admin cannot delete others khatma', async () => {
      await assertFails(alice.firestore().collection('khatmat').doc('k2').delete());
    });
    passed++;

    // Courses: authenticated can read
    await test('authenticated user can read courses', async () => {
      await assertSucceeds(alice.firestore().collection('courses').doc('c1').get());
    });
    passed++;

    // Courses: non-admin cannot create
    await test('non-admin cannot create course', async () => {
      await assertFails(alice.firestore().collection('courses').add({ title: 'New Course' }));
    });
    passed++;

    // Courses: admin can create
    await test('admin can create course', async () => {
      await assertSucceeds(admin.firestore().collection('courses').add({ title: 'Admin Course' }));
    });
    passed++;

    // Lives: authenticated can read
    await test('authenticated user can read lives', async () => {
      await testEnv.withSecurityRulesDisabled(async (context) => {
        await context.firestore().collection('lives').doc('l1').set({ title: 'Live 1' });
      });

      await assertSucceeds(alice.firestore().collection('lives').doc('l1').get());
    });
    passed++;

    // Lives: admin can create
    await test('admin can create live', async () => {
      await assertSucceeds(admin.firestore().collection('lives').add({ title: 'Admin Live' }));
    });
    passed++;

    // Questions: user can create with own userId
    await test('user can create question with own userId', async () => {
      await assertSucceeds(
        alice.firestore().collection('questions').add({
          userId: 'alice',
          text: 'My question?',
        })
      );
    });
    passed++;

    // Questions: user cannot create with wrong userId
    await test('user cannot create question with wrong userId', async () => {
      await assertFails(
        alice.firestore().collection('questions').add({
          userId: 'bob',
          text: 'Fake question?',
        })
      );
    });
    passed++;

    // Weekly QA: user can read
    await test('authenticated user can read weekly_qa', async () => {
      await testEnv.withSecurityRulesDisabled(async (context) => {
        await context.firestore().collection('weekly_qa').doc('qa1').set({
          question: 'Q?',
          answer: 'A!',
        });
      });

      await assertSucceeds(alice.firestore().collection('weekly_qa').doc('qa1').get());
    });
    passed++;

    await testEnv.clearFirestore();

    // Weekly QA: admin can create
    await test('admin can create weekly_qa', async () => {
      await assertSucceeds(
        admin.firestore().collection('weekly_qa').add({
          question: 'Q?',
          answer: 'A!',
        })
      );
    });
    passed++;

    console.log(`\n${passed} passed, ${failed} failed`);
    console.log('✅ Admin + Formations rules tests completed');
  } catch (err) {
    failed++;
    console.error(`\n${passed} passed, ${failed} failed`);
    process.exit(1);
  } finally {
    await testEnv.cleanup();
  }
}

main().catch((err) => {
  console.error(err);
  process.exit(1);
});
