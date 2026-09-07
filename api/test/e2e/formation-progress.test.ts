/**
 * Formation Progress API E2E Tests
 * 
 * Tests server-authoritative progress tracking with Firebase emulators
 */

import request from 'supertest';
import * as admin from 'firebase-admin';
import { createApp } from '../../src/app';
import { createTestUsers, getAuthHeaders, TEST_USERS } from './setup';

describe('E2E: Formation Progress API', () => {
  const app = createApp();
  let testPathId: string;
  let testLessonId1: string;
  let testLessonId2: string;
  let testModuleId: string;

  beforeAll(async () => {
    await createTestUsers();

    // Create test course structure
    testPathId = `test-path-${Date.now()}`;
    testModuleId = `test-module-${Date.now()}`;
    testLessonId1 = `test-lesson1-${Date.now()}`;
    testLessonId2 = `test-lesson2-${Date.now()}`;

    const db = admin.firestore();

    // Create test course
    await db.collection('courses').doc(testPathId).set({
      title: 'Test Formation',
      description: 'Test description',
      isPublished: true,
      level: 'beginner',
      category: 'other',
      instructor: 'Test Instructor',
      totalLessons: 2,
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
    });

    // Create test module
    await db.collection('courses').doc(testPathId)
      .collection('modules').doc(testModuleId).set({
        courseId: testPathId,
        title: 'Test Module',
        order: 1,
        lessonIds: [testLessonId1, testLessonId2],
      });

    // Create test lessons
    await db.collection('courses').doc(testPathId)
      .collection('lessons').doc(testLessonId1).set({
        courseId: testPathId,
        moduleId: testModuleId,
        title: 'Test Lesson 1',
        type: 'text',
        contentText: 'Test content',
        order: 1,
      });

    await db.collection('courses').doc(testPathId)
      .collection('lessons').doc(testLessonId2).set({
        courseId: testPathId,
        moduleId: testModuleId,
        title: 'Test Lesson 2',
        type: 'text',
        contentText: 'Test content 2',
        order: 2,
      });
  });

  beforeEach(async () => {
    // Clear progress between tests
    const db = admin.firestore();
    for (const [, user] of Object.entries(TEST_USERS)) {
      if (user.uid) {
        try {
          await db.collection('users').doc(user.uid)
            .collection('formationProgress').doc(testPathId).delete();
        } catch (e) {
          // Ignore if doesn't exist
        }
      }
    }
  });

  afterAll(async () => {
    // Cleanup
    const db = admin.firestore();
    
    // Delete lessons
    await db.collection('courses').doc(testPathId)
      .collection('lessons').doc(testLessonId1).delete();
    await db.collection('courses').doc(testPathId)
      .collection('lessons').doc(testLessonId2).delete();

    // Delete module
    await db.collection('courses').doc(testPathId)
      .collection('modules').doc(testModuleId).delete();

    // Delete course
    await db.collection('courses').doc(testPathId).delete();
  });

  describe('GET /v1/formations/:pathId/progress', () => {
    it('requires authentication', async () => {
      const res = await request(app)
        .get(`/v1/formations/${testPathId}/progress`);

      expect(res.status).toBe(401);
      expect(res.body.error).toBeDefined();
      expect(res.body.error.code).toBe('AUTH_REQUIRED');
    });

    it('rejects invalid token', async () => {
      const res = await request(app)
        .get(`/v1/formations/${testPathId}/progress`)
        .set('Authorization', 'Bearer invalid-token');

      expect(res.status).toBe(401);
    });

    it('returns null for new user with no progress', async () => {
      const headers = await getAuthHeaders('creator');

      const res = await request(app)
        .get(`/v1/formations/${testPathId}/progress`)
        .set(headers);

      expect(res.status).toBe(200);
      expect(res.body.data).toBeNull();
    });

    it('returns existing progress', async () => {
      const headers = await getAuthHeaders('creator');

      // First complete a lesson
      await request(app)
        .post(`/v1/formations/${testPathId}/lessons/${testLessonId1}/complete`)
        .set(headers);

      // Then get progress
      const res = await request(app)
        .get(`/v1/formations/${testPathId}/progress`)
        .set(headers);

      expect(res.status).toBe(200);
      expect(res.body.data).toBeDefined();
      expect(res.body.data.pathId).toBe(testPathId);
      expect(res.body.data.completedLessonIds).toContain(testLessonId1);
      expect(res.body.data.lastAccessedAt).toBeDefined();
    });

    it('requires valid pathId', async () => {
      const headers = await getAuthHeaders('creator');

      const res = await request(app)
        .get('/v1/formations/ /progress')
        .set(headers);

      expect(res.status).toBe(400);
      expect(res.body.error.code).toBe('INVALID_ARGUMENT');
    });
  });

  describe('POST /v1/formations/:pathId/lessons/:lessonId/open', () => {
    it('requires authentication', async () => {
      const res = await request(app)
        .post(`/v1/formations/${testPathId}/lessons/${testLessonId1}/open`);

      expect(res.status).toBe(401);
    });

    it('persists lastLessonId', async () => {
      const headers = await getAuthHeaders('creator');

      const res = await request(app)
        .post(`/v1/formations/${testPathId}/lessons/${testLessonId1}/open`)
        .set(headers);

      expect(res.status).toBe(200);
      expect(res.body.data.success).toBe(true);

      // Verify in Firestore
      const db = admin.firestore();
      const progressDoc = await db.collection('users').doc(TEST_USERS.creator.uid)
        .collection('formationProgress').doc(testPathId).get();

      const progressData = progressDoc.data();
      expect(progressData?.lastLessonId).toBe(testLessonId1);
      expect(progressData?.userId).toBe(TEST_USERS.creator.uid);
      expect(progressData?.pathId).toBe(testPathId);
    });

    it('returns NOT_FOUND for invalid path', async () => {
      const headers = await getAuthHeaders('creator');

      const res = await request(app)
        .post(`/v1/formations/nonexistent-path/lessons/${testLessonId1}/open`)
        .set(headers);

      expect(res.status).toBe(404);
      expect(res.body.error.code).toBe('NOT_FOUND');
    });

    it('returns NOT_FOUND for invalid lesson', async () => {
      const headers = await getAuthHeaders('creator');

      const res = await request(app)
        .post(`/v1/formations/${testPathId}/lessons/nonexistent-lesson/open`)
        .set(headers);

      expect(res.status).toBe(404);
      expect(res.body.error.code).toBe('NOT_FOUND');
    });

    it('rejects lesson/path mismatch', async () => {
      const headers = await getAuthHeaders('creator');

      // Create a lesson in a different path
      const otherPathId = `other-path-${Date.now()}`;
      const otherLessonId = `other-lesson-${Date.now()}`;

      const db = admin.firestore();
      await db.collection('courses').doc(otherPathId).set({
        title: 'Other Path',
        isPublished: true,
        level: 'beginner',
        category: 'other',
        instructor: 'Test',
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
      });

      await db.collection('courses').doc(otherPathId)
        .collection('lessons').doc(otherLessonId).set({
          courseId: otherPathId,
          moduleId: 'some-module',
          title: 'Other Lesson',
          type: 'text',
          order: 1,
        });

      // Try to open lesson from different path
      const res = await request(app)
        .post(`/v1/formations/${testPathId}/lessons/${otherLessonId}/open`)
        .set(headers);

      expect(res.status).toBe(404);
      expect(res.body.error.code).toBe('NOT_FOUND');

      // Cleanup
      await db.collection('courses').doc(otherPathId)
        .collection('lessons').doc(otherLessonId).delete();
      await db.collection('courses').doc(otherPathId).delete();
    });
  });

  describe('POST /v1/formations/:pathId/lessons/:lessonId/complete', () => {
    it('requires authentication', async () => {
      const res = await request(app)
        .post(`/v1/formations/${testPathId}/lessons/${testLessonId1}/complete`);

      expect(res.status).toBe(401);
    });

    it('persists lesson completion', async () => {
      const headers = await getAuthHeaders('creator');

      const res = await request(app)
        .post(`/v1/formations/${testPathId}/lessons/${testLessonId2}/complete`)
        .set(headers);

      expect(res.status).toBe(200);
      expect(res.body.data.success).toBe(true);

      // Verify in Firestore
      const db = admin.firestore();
      const progressDoc = await db.collection('users').doc(TEST_USERS.creator.uid)
        .collection('formationProgress').doc(testPathId).get();

      const progressData = progressDoc.data();
      expect(progressData?.completedLessonIds).toContain(testLessonId2);
    });

    it('duplicate completion is idempotent', async () => {
      const headers = await getAuthHeaders('creator');

      // Complete once
      await request(app)
        .post(`/v1/formations/${testPathId}/lessons/${testLessonId1}/complete`)
        .set(headers);

      // Complete again
      const res = await request(app)
        .post(`/v1/formations/${testPathId}/lessons/${testLessonId1}/complete`)
        .set(headers);

      expect(res.status).toBe(200);

      // Verify lesson appears only once
      const db = admin.firestore();
      const progressDoc = await db.collection('users').doc(TEST_USERS.creator.uid)
        .collection('formationProgress').doc(testPathId).get();

      const progressData = progressDoc.data();
      const completedIds = progressData?.completedLessonIds || [];
      const count = completedIds.filter((id: string) => id === testLessonId1).length;
      expect(count).toBe(1);
    });

    it('updates lastAccessedAt', async () => {
      const headers = await getAuthHeaders('creator');
      const db = admin.firestore();

      // Complete first lesson
      await request(app)
        .post(`/v1/formations/${testPathId}/lessons/${testLessonId1}/complete`)
        .set(headers);

      const before = await db.collection('users').doc(TEST_USERS.creator.uid)
        .collection('formationProgress').doc(testPathId).get();
      const beforeTime = before.data()?.lastAccessedAt;

      // Wait a moment
      await new Promise(resolve => setTimeout(resolve, 100));

      // Complete second lesson
      await request(app)
        .post(`/v1/formations/${testPathId}/lessons/${testLessonId2}/complete`)
        .set(headers);

      // Verify timestamp updated
      const after = await db.collection('users').doc(TEST_USERS.creator.uid)
        .collection('formationProgress').doc(testPathId).get();
      const afterTime = after.data()?.lastAccessedAt;

      expect(afterTime).toBeDefined();
      if (beforeTime && afterTime) {
        expect(afterTime.toMillis()).toBeGreaterThan(beforeTime.toMillis());
      }
    });

    it('user cannot mutate another user progress', async () => {
      const headersA = await getAuthHeaders('participantA');
      const headersB = await getAuthHeaders('participantB');

      // User A completes lesson 1
      await request(app)
        .post(`/v1/formations/${testPathId}/lessons/${testLessonId1}/complete`)
        .set(headersA);

      // User B completes lesson 2
      await request(app)
        .post(`/v1/formations/${testPathId}/lessons/${testLessonId2}/complete`)
        .set(headersB);

      // Verify User A's progress
      const db = admin.firestore();
      const userAProgress = await db.collection('users').doc(TEST_USERS.participantA.uid)
        .collection('formationProgress').doc(testPathId).get();
      
      const userAData = userAProgress.data();
      expect(userAData?.completedLessonIds).toContain(testLessonId1);
      expect(userAData?.completedLessonIds).not.toContain(testLessonId2);

      // Verify User B's progress
      const userBProgress = await db.collection('users').doc(TEST_USERS.participantB.uid)
        .collection('formationProgress').doc(testPathId).get();
      
      const userBData = userBProgress.data();
      expect(userBData?.completedLessonIds).toContain(testLessonId2);
      expect(userBData?.completedLessonIds).not.toContain(testLessonId1);
    });

    it('returns NOT_FOUND for invalid path', async () => {
      const headers = await getAuthHeaders('creator');

      const res = await request(app)
        .post(`/v1/formations/nonexistent-path/lessons/${testLessonId1}/complete`)
        .set(headers);

      expect(res.status).toBe(404);
      expect(res.body.error.code).toBe('NOT_FOUND');
    });

    it('returns NOT_FOUND for invalid lesson', async () => {
      const headers = await getAuthHeaders('creator');

      const res = await request(app)
        .post(`/v1/formations/${testPathId}/lessons/nonexistent-lesson/complete`)
        .set(headers);

      expect(res.status).toBe(404);
      expect(res.body.error.code).toBe('NOT_FOUND');
    });
  });

  describe('Authorization - Identity forgery protection', () => {
    it('request body cannot override userId', async () => {
      const headers = await getAuthHeaders('creator');
      const fakeUserId = 'fake-user-id';

      const res = await request(app)
        .post(`/v1/formations/${testPathId}/lessons/${testLessonId1}/complete`)
        .set(headers)
        .send({ userId: fakeUserId });

      expect(res.status).toBe(200);

      // Verify progress was saved under real UID, not fake one
      const db = admin.firestore();
      const realProgress = await db.collection('users').doc(TEST_USERS.creator.uid)
        .collection('formationProgress').doc(testPathId).get();
      expect(realProgress.exists).toBe(true);

      const fakeProgress = await db.collection('users').doc(fakeUserId)
        .collection('formationProgress').doc(testPathId).get();
      expect(fakeProgress.exists).toBe(false);
    });

    it('request body cannot override uid', async () => {
      const headers = await getAuthHeaders('creator');
      const fakeUid = 'fake-uid';

      const res = await request(app)
        .post(`/v1/formations/${testPathId}/lessons/${testLessonId1}/open`)
        .set(headers)
        .send({ uid: fakeUid });

      expect(res.status).toBe(200);

      // Verify progress was saved under real UID
      const db = admin.firestore();
      const realProgress = await db.collection('users').doc(TEST_USERS.creator.uid)
        .collection('formationProgress').doc(testPathId).get();
      expect(realProgress.data()?.userId).toBe(TEST_USERS.creator.uid);
    });
  });
});
