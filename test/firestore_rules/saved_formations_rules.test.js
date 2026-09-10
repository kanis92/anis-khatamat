/**
 * Firestore Rules Tests: Saved Formation Items
 * Verify client cannot directly read/write savedFormations (server-authoritative only)
 *
 * Run: cd test/firestore_rules && node saved_formations_rules.test.js
 */

const fs = require('fs');
const path = require('path');
const {
  initializeTestEnvironment,
  assertFails,
  assertSucceeds,
} = require('@firebase/rules-unit-testing');

const PROJECT_ID = 'anis-saved-formations-rules';
const rulesPath = path.resolve(__dirname, '../../firestore.rules');
const TEST_USER_UID = 'test-user-uid';
const OTHER_USER_UID = 'other-user-uid';

async function runTest(name, fn) {
  process.stdout.write(`  ${name} ... `);
  try {
    await fn();
    console.log('PASS');
    return true;
  } catch (err) {
    console.log('FAIL');
    console.error(err);
    throw err;
  }
}

async function main() {
  console.log('\nFirestore Rules: Saved Formation Items');
  console.log('========================================\n');

  const testEnv = await initializeTestEnvironment({
    projectId: PROJECT_ID,
    firestore: {
      rules: fs.readFileSync(rulesPath, 'utf8'),
      host: '127.0.0.1',
      port: 8080,
    },
  });

  const userDb = testEnv
    .authenticatedContext(TEST_USER_UID, { email: 'test@test.com' })
    .firestore();
  const otherUserDb = testEnv
    .authenticatedContext(OTHER_USER_UID, { email: 'other@test.com' })
    .firestore();
  const anonDb = testEnv.unauthenticatedContext().firestore();

  // Client access tests (must be denied)
  console.log('\nClient access (must be denied):');

  await runTest('authenticated user cannot read own savedFormations collection', async () => {
    await assertFails(
      userDb
        .collection('users')
        .doc(TEST_USER_UID)
        .collection('savedFormations')
        .get()
    );
  });

  await runTest('authenticated user cannot read specific saved item', async () => {
    await assertFails(
      userDb
        .collection('users')
        .doc(TEST_USER_UID)
        .collection('savedFormations')
        .doc('saved-1')
        .get()
    );
  });

  await runTest('authenticated user cannot create saved item', async () => {
    await assertFails(
      userDb
        .collection('users')
        .doc(TEST_USER_UID)
        .collection('savedFormations')
        .add({
          userId: TEST_USER_UID,
          type: 'course',
          targetId: 'test-course',
          courseId: null,
          savedAt: new Date(),
        })
    );
  });

  await runTest('authenticated user cannot update saved item', async () => {
    // Create via server context
    await testEnv.withSecurityRulesDisabled(async (context) => {
      const db = context.firestore();
      await db
        .collection('users')
        .doc(TEST_USER_UID)
        .collection('savedFormations')
        .doc('saved-update-test')
        .set({
          userId: TEST_USER_UID,
          type: 'course',
          targetId: 'test-course',
          courseId: null,
          savedAt: new Date(),
        });
    });

    // Try to update as client
    await assertFails(
      userDb
        .collection('users')
        .doc(TEST_USER_UID)
        .collection('savedFormations')
        .doc('saved-update-test')
        .update({ type: 'lesson' })
    );
  });

  await runTest('authenticated user cannot delete saved item', async () => {
    // Create via server context
    await testEnv.withSecurityRulesDisabled(async (context) => {
      const db = context.firestore();
      await db
        .collection('users')
        .doc(TEST_USER_UID)
        .collection('savedFormations')
        .doc('saved-delete-test')
        .set({
          userId: TEST_USER_UID,
          type: 'course',
          targetId: 'test-course',
          courseId: null,
          savedAt: new Date(),
        });
    });

    // Try to delete as client
    await assertFails(
      userDb
        .collection('users')
        .doc(TEST_USER_UID)
        .collection('savedFormations')
        .doc('saved-delete-test')
        .delete()
    );
  });

  await runTest('authenticated user cannot read another user savedFormations', async () => {
    await assertFails(
      userDb
        .collection('users')
        .doc(OTHER_USER_UID)
        .collection('savedFormations')
        .get()
    );
  });

  await runTest('authenticated user cannot write to another user savedFormations', async () => {
    await assertFails(
      userDb
        .collection('users')
        .doc(OTHER_USER_UID)
        .collection('savedFormations')
        .add({
          userId: OTHER_USER_UID,
          type: 'course',
          targetId: 'test-course',
          courseId: null,
          savedAt: new Date(),
        })
    );
  });

  await runTest('unauthenticated user cannot read savedFormations', async () => {
    await assertFails(
      anonDb
        .collection('users')
        .doc(TEST_USER_UID)
        .collection('savedFormations')
        .get()
    );
  });

  await runTest('unauthenticated user cannot write savedFormations', async () => {
    await assertFails(
      anonDb
        .collection('users')
        .doc(TEST_USER_UID)
        .collection('savedFormations')
        .add({
          userId: TEST_USER_UID,
          type: 'course',
          targetId: 'test-course',
          courseId: null,
          savedAt: new Date(),
        })
    );
  });

  // Server access tests
  console.log('\nServer access (with rules disabled):');

  await runTest('server can read and write savedFormations', async () => {
    await testEnv.withSecurityRulesDisabled(async (context) => {
      const db = context.firestore();

      // Server/Admin SDK bypasses all rules
      await db
        .collection('users')
        .doc(TEST_USER_UID)
        .collection('savedFormations')
        .doc('server-created')
        .set({
          userId: TEST_USER_UID,
          type: 'course',
          targetId: 'test-course',
          courseId: null,
          savedAt: new Date(),
        });

      const doc = await db
        .collection('users')
        .doc(TEST_USER_UID)
        .collection('savedFormations')
        .doc('server-created')
        .get();

      if (!doc.exists) {
        throw new Error('Server-created document should exist');
      }
    });
  });

  await testEnv.cleanup();

  console.log('\n✓ All Saved Formations Rules tests passed\n');
  process.exit(0);
}

main().catch((error) => {
  console.error('\n✗ Tests failed:', error);
  process.exit(1);
});
