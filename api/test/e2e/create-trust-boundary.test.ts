/**
 * E2E tests for /create trust boundary
 * Ensures clients cannot forge trusted server fields at creation
 */

import request from 'supertest';
import { createApp } from '../../src/app';
import { createTestUsers, clearFirestore, getAuthHeaders, TEST_USERS } from './setup';
import * as admin from 'firebase-admin';

describe('E2E: POST /v1/khatmat - Creation Trust Boundary', () => {
  const app = createApp();

  beforeAll(async () => {
    await createTestUsers();
  });

  beforeEach(async () => {
    await clearFirestore();
  });

  describe('Forbidden Fields Rejection', () => {
    it('rejects createdBy field', async () => {
      const headers = await getAuthHeaders('creator');
      const res = await request(app)
        .post('/v1/khatmat')
        .set(headers)
        .send({
          title: 'Test Khatma',
          isGroup: true,
          isPublic: false,
          createdBy: 'forged@attacker.com', // FORBIDDEN
        });

      expect(res.status).toBe(400);
      expect(res.body.error.code).toBe('INVALID_ARGUMENT');
      expect(res.body.error.message).toContain('createdBy');
    });

    it('rejects creatorUid field', async () => {
      const headers = await getAuthHeaders('creator');
      const res = await request(app)
        .post('/v1/khatmat')
        .set(headers)
        .send({
          title: 'Test Khatma',
          isGroup: true,
          isPublic: false,
          creatorUid: 'forged-uid-123', // FORBIDDEN
        });

      expect(res.status).toBe(400);
      expect(res.body.error.code).toBe('INVALID_ARGUMENT');
      expect(res.body.error.message).toContain('creatorUid');
    });

    it('rejects id field', async () => {
      const headers = await getAuthHeaders('creator');
      const res = await request(app)
        .post('/v1/khatmat')
        .set(headers)
        .send({
          title: 'Test Khatma',
          isGroup: true,
          isPublic: false,
          id: 'forged-khatma-id', // FORBIDDEN
        });

      expect(res.status).toBe(400);
      expect(res.body.error.code).toBe('INVALID_ARGUMENT');
      expect(res.body.error.message).toContain('id');
    });

    it('rejects creationState field', async () => {
      const headers = await getAuthHeaders('creator');
      const res = await request(app)
        .post('/v1/khatmat')
        .set(headers)
        .send({
          title: 'Test Khatma',
          isGroup: true,
          isPublic: false,
          creationState: 'ready', // FORBIDDEN
        });

      expect(res.status).toBe(400);
      expect(res.body.error.code).toBe('INVALID_ARGUMENT');
      expect(res.body.error.message).toContain('creationState');
    });

    it('rejects completedHizbCount field', async () => {
      const headers = await getAuthHeaders('creator');
      const res = await request(app)
        .post('/v1/khatmat')
        .set(headers)
        .send({
          title: 'Test Khatma',
          isGroup: true,
          isPublic: false,
          completedHizbCount: 60, // FORBIDDEN
        });

      expect(res.status).toBe(400);
      expect(res.body.error.code).toBe('INVALID_ARGUMENT');
      expect(res.body.error.message).toContain('completedHizbCount');
    });
  });

  describe('Members Field - Legitimate Intent', () => {
    it('allows members field as legitimate invitation intent', async () => {
      const headers = await getAuthHeaders('creator');
      const res = await request(app)
        .post('/v1/khatmat')
        .set(headers)
        .send({
          title: 'Collaborative Khatma',
          isGroup: true,
          isPublic: false,
          members: [TEST_USERS.participantA.email, TEST_USERS.participantB.email],
        });

      expect(res.status).toBe(201);
      expect(res.body.data).toHaveProperty('khatmaId');

      // Verify server sets createdBy to authenticated user, NOT from members
      const db = admin.firestore();
      const khatmaDoc = await db.collection('khatmat').doc(res.body.data.khatmaId).get();
      const data = khatmaDoc.data();

      expect(data?.createdBy).toBe(TEST_USERS.creator.email); // Server-derived
      expect(data?.members).toContain(TEST_USERS.participantA.email);
      expect(data?.members).toContain(TEST_USERS.participantB.email);
      expect(data?.participantIds).toContain(TEST_USERS.creator.email); // Creator is always participant
      expect(data?.participantIds).toContain(TEST_USERS.participantA.email);
    });

    it('creator cannot forge organizer authority via members', async () => {
      const headers = await getAuthHeaders('participantA');
      const res = await request(app)
        .post('/v1/khatmat')
        .set(headers)
        .send({
          title: 'Attack Khatma',
          isGroup: true,
          isPublic: false,
          members: [TEST_USERS.creator.email], // Try to make creator organizer
        });

      expect(res.status).toBe(201);

      // Verify createdBy is the ACTUAL authenticated user, not the invited member
      const db = admin.firestore();
      const khatmaDoc = await db.collection('khatmat').doc(res.body.data.khatmaId).get();
      const data = khatmaDoc.data();

      expect(data?.createdBy).toBe(TEST_USERS.participantA.email); // Authenticated user
      expect(data?.members).toContain(TEST_USERS.creator.email); // Just an invited participant
    });

    it('members does not influence organizer authority', async () => {
      const headers = await getAuthHeaders('creator');
      const createRes = await request(app)
        .post('/v1/khatmat')
        .set(headers)
        .send({
          title: 'Test Khatma',
          isGroup: true,
          isPublic: false,
          members: [TEST_USERS.participantA.email],
        });

      const khatmaId = createRes.body.data.khatmaId;

      // ParticipantA tries to use /assign (organizer-only operation)
      const participantHeaders = await getAuthHeaders('participantA');
      const assignRes = await request(app)
        .post(`/v1/khatmat/${khatmaId}/hizb/1/assign`)
        .set(participantHeaders)
        .send({
          participantUserId: TEST_USERS.participantB.email,
        });

      // Should fail - participantA is NOT organizer
      expect(assignRes.status).toBe(403);
      expect(assignRes.body.error.code).toBe('FORBIDDEN');
    });
  });
});
