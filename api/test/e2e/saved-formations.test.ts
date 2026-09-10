/**
 * E2E: Saved Formation Items API
 */

import request from 'supertest';
import * as admin from 'firebase-admin';
import { createApp } from '../../src/app';
import { createTestUsers, TEST_USERS } from './setup';

const app = createApp();

describe('E2E: Saved Formation Items API', () => {
  let testCourseId: string;
  let testLessonId: string;

  beforeAll(async () => {
    await createTestUsers();

    // Create test course and lesson structure
    testCourseId = `test-course-${Date.now()}`;
    testLessonId = `test-lesson-${Date.now()}`;

    const db = admin.firestore();
    await db.collection('courses').doc(testCourseId).set({
      title: 'Test Course',
      published: true,
      createdAt: admin.firestore.Timestamp.now(),
    });

    await db
      .collection('courses')
      .doc(testCourseId)
      .collection('lessons')
      .doc(testLessonId)
      .set({
        title: 'Test Lesson',
        order: 1,
        courseId: testCourseId,
      });
  });

  beforeEach(async () => {
    // Clear saved items between tests
    const db = admin.firestore();
    for (const [, user] of Object.entries(TEST_USERS)) {
      if (user.uid) {
        try {
          const savedCollection = db
            .collection('users')
            .doc(user.uid)
            .collection('savedFormations');
          const snapshot = await savedCollection.get();
          const batch = db.batch();
          snapshot.docs.forEach((doc) => batch.delete(doc.ref));
          await batch.commit();
        } catch (e) {
          // Ignore if doesn't exist
        }
      }
    }
  });

  afterAll(async () => {
    // Cleanup
    const db = admin.firestore();

    // Delete lesson
    await db
      .collection('courses')
      .doc(testCourseId)
      .collection('lessons')
      .doc(testLessonId)
      .delete();

    // Delete course
    await db.collection('courses').doc(testCourseId).delete();
  });

  describe('GET /v1/formations/saved', () => {
    it('requires authentication', async () => {
      const res = await request(app).get('/v1/formations/saved');
      expect(res.status).toBe(401);
    });

    it('rejects invalid token', async () => {
      const res = await request(app)
        .get('/v1/formations/saved')
        .set('Authorization', 'Bearer invalid-token');
      expect(res.status).toBe(401);
    });

    it('returns empty list for new user with no saved items', async () => {
      const res = await request(app)
        .get('/v1/formations/saved')
        .set('Authorization', `Bearer ${TEST_USERS.creator.token}`);

      expect(res.status).toBe(200);
      expect(res.body.data).toEqual([]);
    });

    it('returns saved items ordered by savedAt desc', async () => {
      // Save two courses
      const res1 = await request(app)
        .post('/v1/formations/saved')
        .set('Authorization', `Bearer ${TEST_USERS.creator.token}`)
        .send({
          type: 'course',
          targetId: testCourseId,
          courseId: null,
        });
      expect(res1.status).toBe(200);

      // Wait 10ms to ensure different timestamp
      await new Promise((resolve) => setTimeout(resolve, 10));

      const res2 = await request(app)
        .post('/v1/formations/saved')
        .set('Authorization', `Bearer ${TEST_USERS.creator.token}`)
        .send({
          type: 'lesson',
          targetId: testLessonId,
          courseId: testCourseId,
        });
      expect(res2.status).toBe(200);

      // Get all saved items
      const res = await request(app)
        .get('/v1/formations/saved')
        .set('Authorization', `Bearer ${TEST_USERS.creator.token}`);

      expect(res.status).toBe(200);
      expect(res.body.data).toHaveLength(2);
      expect(res.body.data[0].type).toBe('lesson');
      expect(res.body.data[1].type).toBe('course');
    });
  });

  describe('POST /v1/formations/saved', () => {
    it('requires authentication', async () => {
      const res = await request(app).post('/v1/formations/saved').send({
        type: 'course',
        targetId: testCourseId,
        courseId: null,
      });
      expect(res.status).toBe(401);
    });

    it('saves a course', async () => {
      const res = await request(app)
        .post('/v1/formations/saved')
        .set('Authorization', `Bearer ${TEST_USERS.creator.token}`)
        .send({
          type: 'course',
          targetId: testCourseId,
          courseId: null,
        });

      expect(res.status).toBe(200);
      expect(res.body.data.id).toBeDefined();
      expect(res.body.data.type).toBe('course');
      expect(res.body.data.targetId).toBe(testCourseId);
      expect(res.body.data.courseId).toBeNull();
      expect(res.body.data.savedAt).toBeDefined();
    });

    it('saves a lesson with courseId', async () => {
      const res = await request(app)
        .post('/v1/formations/saved')
        .set('Authorization', `Bearer ${TEST_USERS.creator.token}`)
        .send({
          type: 'lesson',
          targetId: testLessonId,
          courseId: testCourseId,
        });

      expect(res.status).toBe(200);
      expect(res.body.data.type).toBe('lesson');
      expect(res.body.data.targetId).toBe(testLessonId);
      expect(res.body.data.courseId).toBe(testCourseId);
    });

    it('is idempotent - duplicate save returns existing item', async () => {
      const res1 = await request(app)
        .post('/v1/formations/saved')
        .set('Authorization', `Bearer ${TEST_USERS.creator.token}`)
        .send({
          type: 'course',
          targetId: testCourseId,
          courseId: null,
        });

      expect(res1.status).toBe(200);
      const savedId1 = res1.body.data.id;

      const res2 = await request(app)
        .post('/v1/formations/saved')
        .set('Authorization', `Bearer ${TEST_USERS.creator.token}`)
        .send({
          type: 'course',
          targetId: testCourseId,
          courseId: null,
        });

      expect(res2.status).toBe(200);
      expect(res2.body.data.id).toBe(savedId1);
    });

    it('requires courseId for lesson type', async () => {
      const res = await request(app)
        .post('/v1/formations/saved')
        .set('Authorization', `Bearer ${TEST_USERS.creator.token}`)
        .send({
          type: 'lesson',
          targetId: testLessonId,
          courseId: null,
        });

      expect(res.status).toBe(400);
    });

    it('rejects courseId for course type', async () => {
      const res = await request(app)
        .post('/v1/formations/saved')
        .set('Authorization', `Bearer ${TEST_USERS.creator.token}`)
        .send({
          type: 'course',
          targetId: testCourseId,
          courseId: testCourseId,
        });

      expect(res.status).toBe(400);
    });

    it('validates type field', async () => {
      const res = await request(app)
        .post('/v1/formations/saved')
        .set('Authorization', `Bearer ${TEST_USERS.creator.token}`)
        .send({
          type: 'invalid',
          targetId: testCourseId,
        });

      expect(res.status).toBe(400);
    });
  });

  describe('DELETE /v1/formations/saved/:savedItemId', () => {
    it('requires authentication', async () => {
      const res = await request(app).delete('/v1/formations/saved/test-id');
      expect(res.status).toBe(401);
    });

    it('removes a saved item by ID', async () => {
      // Save an item
      const saveRes = await request(app)
        .post('/v1/formations/saved')
        .set('Authorization', `Bearer ${TEST_USERS.creator.token}`)
        .send({
          type: 'course',
          targetId: testCourseId,
          courseId: null,
        });

      const savedId = saveRes.body.data.id;

      // Remove it
      const deleteRes = await request(app)
        .delete(`/v1/formations/saved/${savedId}`)
        .set('Authorization', `Bearer ${TEST_USERS.creator.token}`);

      expect(deleteRes.status).toBe(200);

      // Verify removed
      const getRes = await request(app)
        .get('/v1/formations/saved')
        .set('Authorization', `Bearer ${TEST_USERS.creator.token}`);

      expect(getRes.body.data).toHaveLength(0);
    });

    it('is idempotent - removing non-existent item succeeds', async () => {
      const res = await request(app)
        .delete('/v1/formations/saved/non-existent-id')
        .set('Authorization', `Bearer ${TEST_USERS.creator.token}`);

      expect(res.status).toBe(200);
    });

    it('cannot access another user saved item (path isolation)', async () => {
      // User A saves an item
      const saveRes = await request(app)
        .post('/v1/formations/saved')
        .set('Authorization', `Bearer ${TEST_USERS.creator.token}`)
        .send({
          type: 'course',
          targetId: testCourseId,
          courseId: null,
        });

      const savedId = saveRes.body.data.id;

      // User B attempts to delete it using creator's saved ID
      // Path-based isolation means B looks in their own collection
      // The item doesn't exist there, so it's a no-op (idempotent)
      const deleteRes = await request(app)
        .delete(`/v1/formations/saved/${savedId}`)
        .set('Authorization', `Bearer ${TEST_USERS.participantB.token}`);

      expect(deleteRes.status).toBe(200); // Idempotent - not found in B's collection

      // Verify creator's item is still there (B couldn't touch it)
      const getRes = await request(app)
        .get('/v1/formations/saved')
        .set('Authorization', `Bearer ${TEST_USERS.creator.token}`);

      expect(getRes.body.data).toHaveLength(1);
      expect(getRes.body.data[0].id).toBe(savedId);
    });
  });

  describe('DELETE /v1/formations/saved-target', () => {
    it('removes by type and targetId', async () => {
      // Save an item
      await request(app)
        .post('/v1/formations/saved')
        .set('Authorization', `Bearer ${TEST_USERS.creator.token}`)
        .send({
          type: 'course',
          targetId: testCourseId,
          courseId: null,
        });

      // Remove by target
      const deleteRes = await request(app)
        .delete('/v1/formations/saved-target')
        .set('Authorization', `Bearer ${TEST_USERS.creator.token}`)
        .send({
          type: 'course',
          targetId: testCourseId,
        });

      expect(deleteRes.status).toBe(200);

      // Verify removed
      const getRes = await request(app)
        .get('/v1/formations/saved')
        .set('Authorization', `Bearer ${TEST_USERS.creator.token}`);

      expect(getRes.body.data).toHaveLength(0);
    });

    it('is idempotent', async () => {
      const res = await request(app)
        .delete('/v1/formations/saved-target')
        .set('Authorization', `Bearer ${TEST_USERS.creator.token}`)
        .send({
          type: 'course',
          targetId: 'non-existent',
        });

      expect(res.status).toBe(200);
    });
  });

  describe('User isolation', () => {
    it('returns only the authenticated user saved items', async () => {
      // User A saves course
      await request(app)
        .post('/v1/formations/saved')
        .set('Authorization', `Bearer ${TEST_USERS.creator.token}`)
        .send({
          type: 'course',
          targetId: testCourseId,
          courseId: null,
        });

      // User B saves lesson
      await request(app)
        .post('/v1/formations/saved')
        .set('Authorization', `Bearer ${TEST_USERS.participantB.token}`)
        .send({
          type: 'lesson',
          targetId: testLessonId,
          courseId: testCourseId,
        });

      // User A should only see course
      const resA = await request(app)
        .get('/v1/formations/saved')
        .set('Authorization', `Bearer ${TEST_USERS.creator.token}`);

      expect(resA.body.data).toHaveLength(1);
      expect(resA.body.data[0].type).toBe('course');

      // User B should only see lesson
      const resB = await request(app)
        .get('/v1/formations/saved')
        .set('Authorization', `Bearer ${TEST_USERS.participantB.token}`);

      expect(resB.body.data).toHaveLength(1);
      expect(resB.body.data[0].type).toBe('lesson');
    });
  });
});
