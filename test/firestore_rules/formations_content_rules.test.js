/**
 * Formations published content — client read boundaries (emulator rules).
 *
 * Proves authenticated users can read published course + nested modules/lessons,
 * while writes and personal progress remain restricted.
 *
 * Run: cd test/firestore_rules && node formations_content_rules.test.js
 */
const fs = require('fs');
const path = require('path');
const {
  initializeTestEnvironment,
  assertFails,
  assertSucceeds,
} = require('@firebase/rules-unit-testing');

const PROJECT_ID = 'anis-formations-content';
const rulesPath = path.resolve(__dirname, '../../firestore.rules');
const COURSE_ID = 'course-foundations_practice';
const MODULE_ID = 'course-foundations_practice-module-1';
const LESSON_ID = 'course-foundations_practice-module-1-lesson-1';

function authedDb(testEnv, uid, email) {
  return testEnv.authenticatedContext(uid, email ? { email } : {}).firestore();
}

async function seedPublishedCourse(testEnv) {
  await testEnv.withSecurityRulesDisabled(async (context) => {
    const db = context.firestore();
    await db.collection('courses').doc(COURSE_ID).set({
      title: 'Bases & pratique',
      description: 'Preview course',
      isPublished: true,
      pillarId: 'foundations_practice',
      createdAt: new Date().toISOString(),
    });
    await db.collection('courses').doc(COURSE_ID)
      .collection('modules').doc(MODULE_ID).set({
        title: 'Getting started',
        order: 1,
        courseId: COURSE_ID,
        translations: { fr: { title: 'Bien démarrer', description: 'Intro' } },
      });
    await db.collection('courses').doc(COURSE_ID)
      .collection('lessons').doc(LESSON_ID).set({
        title: 'Welcome',
        order: 1,
        courseId: COURSE_ID,
        moduleId: MODULE_ID,
      });
  });
}

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
  const testEnv = await initializeTestEnvironment({
    projectId: PROJECT_ID,
    firestore: {
      rules: fs.readFileSync(rulesPath, 'utf8'),
      host: '127.0.0.1',
      port: 8080,
    },
  });

  await seedPublishedCourse(testEnv);
  const preview = authedDb(testEnv, 'preview-user', 'preview@test.com');
  const admin = testEnv.authenticatedContext('admin-user', {
    email: 'admin@test.com',
    admin: true,
  }).firestore();

  await runTest('authenticated preview user can read published course', async () => {
    await assertSucceeds(preview.collection('courses').doc(COURSE_ID).get());
  });

  await runTest('authenticated preview user can list modules subcollection', async () => {
    await assertSucceeds(
      preview.collection('courses').doc(COURSE_ID).collection('modules').orderBy('order').get(),
    );
  });

  await runTest('authenticated preview user can read module document', async () => {
    await assertSucceeds(
      preview.collection('courses').doc(COURSE_ID).collection('modules').doc(MODULE_ID).get(),
    );
  });

  await runTest('authenticated preview user can list lessons subcollection', async () => {
    await assertSucceeds(
      preview.collection('courses').doc(COURSE_ID).collection('lessons').orderBy('order').get(),
    );
  });

  await runTest('authenticated preview user can query published pillar courses', async () => {
    await assertSucceeds(
      preview.collection('courses')
        .where('isPublished', '==', true)
        .where('pillarId', '==', 'foundations_practice')
        .get(),
    );
  });

  await runTest('unauthenticated client cannot read modules', async () => {
    const anon = testEnv.unauthenticatedContext().firestore();
    await assertFails(
      anon.collection('courses').doc(COURSE_ID).collection('modules').doc(MODULE_ID).get(),
    );
  });

  await runTest('preview user cannot create course', async () => {
    await assertFails(
      preview.collection('courses').doc('evil-course').set({ title: 'Hack' }),
    );
  });

  await runTest('preview user cannot update module', async () => {
    await assertFails(
      preview.collection('courses').doc(COURSE_ID)
        .collection('modules').doc(MODULE_ID)
        .update({ title: 'Hacked' }),
    );
  });

  await runTest('preview user cannot delete lesson', async () => {
    await assertFails(
      preview.collection('courses').doc(COURSE_ID)
        .collection('lessons').doc(LESSON_ID)
        .delete(),
    );
  });

  await runTest('admin can create course', async () => {
    await assertSucceeds(
      admin.collection('courses').doc('admin-course').set({ title: 'Admin course' }),
    );
  });

  await runTest('preview user cannot read another user formation progress', async () => {
    await testEnv.withSecurityRulesDisabled(async (context) => {
      await context.firestore()
        .collection('users').doc('owner-uid')
        .collection('formationProgress').doc(COURSE_ID)
        .set({ courseId: COURSE_ID, userId: 'owner-uid' });
    });
    await assertFails(
      preview.collection('users').doc('owner-uid')
        .collection('formationProgress').doc(COURSE_ID)
        .get(),
    );
  });

  await testEnv.cleanup();
  console.log('\n✅ Formations content rules tests completed');
}

main().catch((error) => {
  console.error(error);
  process.exit(1);
});
