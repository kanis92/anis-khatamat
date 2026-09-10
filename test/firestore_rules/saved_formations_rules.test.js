/**
 * Firestore Rules Tests: Saved Formation Items
 * Verify client cannot directly read/write savedFormations (server-authoritative only)
 */

const { assertFails, assertSucceeds } = require('@firebase/rules-unit-testing');
const {
  getTestEnv,
  withAuthContext,
  withAdminContext,
} = require('./test-helpers');

const TEST_USER_UID = 'test-user-uid';
const OTHER_USER_UID = 'other-user-uid';

describe('Firestore Rules: Saved Formation Items', () => {
  let testEnv;

  beforeAll(async () => {
    testEnv = await getTestEnv();
  });

  afterAll(async () => {
    await testEnv.cleanup();
  });

  describe('Client access (must be denied)', () => {
    test('authenticated user cannot read own savedFormations', async () => {
      const db = testEnv.authenticatedContext(TEST_USER_UID).firestore();

      await assertFails(
        db
          .collection('users')
          .doc(TEST_USER_UID)
          .collection('savedFormations')
          .get()
      );
    });

    test('authenticated user cannot read specific saved item', async () => {
      const db = testEnv.authenticatedContext(TEST_USER_UID).firestore();

      await assertFails(
        db
          .collection('users')
          .doc(TEST_USER_UID)
          .collection('savedFormations')
          .doc('saved-1')
          .get()
      );
    });

    test('authenticated user cannot write own savedFormations', async () => {
      const db = testEnv.authenticatedContext(TEST_USER_UID).firestore();

      await assertFails(
        db
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

    test('authenticated user cannot update saved item', async () => {
      // First, create via admin
      const adminDb = testEnv.authenticatedContext(TEST_USER_UID, { admin: true }).firestore();
      await adminDb
        .collection('users')
        .doc(TEST_USER_UID)
        .collection('savedFormations')
        .doc('saved-1')
        .set({
          userId: TEST_USER_UID,
          type: 'course',
          targetId: 'test-course',
          courseId: null,
          savedAt: new Date(),
        });

      // Try to update as regular user
      const db = testEnv.authenticatedContext(TEST_USER_UID).firestore();

      await assertFails(
        db
          .collection('users')
          .doc(TEST_USER_UID)
          .collection('savedFormations')
          .doc('saved-1')
          .update({ type: 'lesson' })
      );
    });

    test('authenticated user cannot delete saved item', async () => {
      // First, create via admin
      const adminDb = testEnv.authenticatedContext(TEST_USER_UID, { admin: true }).firestore();
      await adminDb
        .collection('users')
        .doc(TEST_USER_UID)
        .collection('savedFormations')
        .doc('saved-2')
        .set({
          userId: TEST_USER_UID,
          type: 'course',
          targetId: 'test-course',
          courseId: null,
          savedAt: new Date(),
        });

      // Try to delete as regular user
      const db = testEnv.authenticatedContext(TEST_USER_UID).firestore();

      await assertFails(
        db
          .collection('users')
          .doc(TEST_USER_UID)
          .collection('savedFormations')
          .doc('saved-2')
          .delete()
      );
    });

    test('authenticated user cannot read another user savedFormations', async () => {
      const db = testEnv.authenticatedContext(TEST_USER_UID).firestore();

      await assertFails(
        db
          .collection('users')
          .doc(OTHER_USER_UID)
          .collection('savedFormations')
          .get()
      );
    });

    test('authenticated user cannot write to another user savedFormations', async () => {
      const db = testEnv.authenticatedContext(TEST_USER_UID).firestore();

      await assertFails(
        db
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

    test('unauthenticated user cannot read savedFormations', async () => {
      const db = testEnv.unauthenticatedContext().firestore();

      await assertFails(
        db
          .collection('users')
          .doc(TEST_USER_UID)
          .collection('savedFormations')
          .get()
      );
    });

    test('unauthenticated user cannot write savedFormations', async () => {
      const db = testEnv.unauthenticatedContext().firestore();

      await assertFails(
        db
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
  });

  describe('Admin/Server access (allowed)', () => {
    test('admin can read savedFormations', async () => {
      const db = testEnv.authenticatedContext(TEST_USER_UID, { admin: true }).firestore();

      // Admin access via server SDK is unrestricted
      // This test verifies rules don't block admin token (though server uses Admin SDK)
      await assertSucceeds(
        db
          .collection('users')
          .doc(TEST_USER_UID)
          .collection('savedFormations')
          .get()
      );
    });

    test('admin can write savedFormations', async () => {
      const db = testEnv.authenticatedContext(TEST_USER_UID, { admin: true }).firestore();

      await assertSucceeds(
        db
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
  });
});
