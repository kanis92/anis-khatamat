/**
 * E2E tests for /reserve trust boundary
 * Ensures clients cannot forge trusted server fields
 */

import request from 'supertest';
import { createApp } from '../../src/app';
import { createTestUsers, clearFirestore, getAuthHeaders, TEST_USERS } from './setup';

describe('E2E: POST /v1/khatmat/:id/hizb/:num/reserve - Trust Boundary', () => {
  const app = createApp();
  let khatmaId: string;

  beforeAll(async () => {
    await createTestUsers();
  });

  beforeEach(async () => {
    await clearFirestore();
    
    // Create a collaborative Khatma for trust boundary tests
    const creatorHeaders = await getAuthHeaders('creator');
    const createRes = await request(app)
      .post('/v1/khatmat')
      .set(creatorHeaders)
      .send({
        title: 'Trust Boundary Test Khatma',
        isGroup: true,
        isPublic: false,
        members: [TEST_USERS.participantA.email],
      });

    expect(createRes.status).toBe(201);
    khatmaId = createRes.body.data.khatmaId;
  });

  describe('Forbidden Fields Rejection', () => {
    it('rejects reservedBy field', async () => {
      const headers = await getAuthHeaders('participantA');
      const res = await request(app)
        .post(`/v1/khatmat/${khatmaId}/hizb/1/reserve`)
        .set(headers)
        .send({
          assigneeKind: 'self',
          reservedBy: 'forged@attacker.com', // FORBIDDEN
        });

      expect(res.status).toBe(400);
      expect(res.body.error.code).toBe('INVALID_ARGUMENT');
      expect(res.body.error.message).toContain('reservedBy');
    });

    it('rejects assigneeUserId field', async () => {
      const headers = await getAuthHeaders('participantA');
      const res = await request(app)
        .post(`/v1/khatmat/${khatmaId}/hizb/1/reserve`)
        .set(headers)
        .send({
          assigneeKind: 'self',
          assigneeUserId: 'forged@attacker.com', // FORBIDDEN
        });

      expect(res.status).toBe(400);
      expect(res.body.error.code).toBe('INVALID_ARGUMENT');
      expect(res.body.error.message).toContain('assigneeUserId');
    });

    it('rejects assignedByUserId field', async () => {
      const headers = await getAuthHeaders('participantA');
      const res = await request(app)
        .post(`/v1/khatmat/${khatmaId}/hizb/1/reserve`)
        .set(headers)
        .send({
          assigneeKind: 'self',
          assignedByUserId: 'forged@attacker.com', // FORBIDDEN
        });

      expect(res.status).toBe(400);
      expect(res.body.error.code).toBe('INVALID_ARGUMENT');
      expect(res.body.error.message).toContain('assignedByUserId');
    });

    it('rejects completedBy field', async () => {
      const headers = await getAuthHeaders('participantA');
      const res = await request(app)
        .post(`/v1/khatmat/${khatmaId}/hizb/1/reserve`)
        .set(headers)
        .send({
          assigneeKind: 'self',
          completedBy: 'forged@attacker.com', // FORBIDDEN
        });

      expect(res.status).toBe(400);
      expect(res.body.error.code).toBe('INVALID_ARGUMENT');
      expect(res.body.error.message).toContain('completedBy');
    });

    it('rejects completedAt field', async () => {
      const headers = await getAuthHeaders('participantA');
      const res = await request(app)
        .post(`/v1/khatmat/${khatmaId}/hizb/1/reserve`)
        .set(headers)
        .send({
          assigneeKind: 'self',
          completedAt: new Date().toISOString(), // FORBIDDEN
        });

      expect(res.status).toBe(400);
      expect(res.body.error.code).toBe('INVALID_ARGUMENT');
      expect(res.body.error.message).toContain('completedAt');
    });
  });

  describe('Organizer Assignment via /reserve is Blocked', () => {
    it('participant cannot use assigneeKind=participant (not organizer)', async () => {
      const headers = await getAuthHeaders('participantA');
      const res = await request(app)
        .post(`/v1/khatmat/${khatmaId}/hizb/1/reserve`)
        .set(headers)
        .send({
          assigneeKind: 'participant', // Requires organizer permission
        });

      // Will fail with 403 because participant is not organizer, or 400 if assigneeUserId is missing
      expect([400, 403]).toContain(res.status);
      expect(['INVALID_ARGUMENT', 'FORBIDDEN']).toContain(res.body.error.code);
    });

    it('organizer must use /assign endpoint for participant assignment', async () => {
      const creatorHeaders = await getAuthHeaders('creator');
      
      // Organizer tries to use /reserve with participant kind (blocked)
      const reserveRes = await request(app)
        .post(`/v1/khatmat/${khatmaId}/hizb/1/reserve`)
        .set(creatorHeaders)
        .send({
          assigneeKind: 'participant',
          assigneeUserId: TEST_USERS.participantA.email, // BLOCKED
        });

      expect(reserveRes.status).toBe(400);
      expect(reserveRes.body.error.code).toBe('INVALID_ARGUMENT');
      expect(reserveRes.body.error.message).toContain('assigneeUserId');

      // Correct way: use /assign endpoint
      const assignRes = await request(app)
        .post(`/v1/khatmat/${khatmaId}/hizb/1/assign`)
        .set(creatorHeaders)
        .send({
          participantUserId: TEST_USERS.participantA.email,
        });

      expect(assignRes.status).toBe(200);
      expect(assignRes.body.success).toBe(true);
    });
  });

  describe('Valid /reserve Payloads', () => {
    it('self reservation with only assigneeKind', async () => {
      const headers = await getAuthHeaders('participantA');
      const res = await request(app)
        .post(`/v1/khatmat/${khatmaId}/hizb/2/reserve`)
        .set(headers)
        .send({
          assigneeKind: 'self',
        });

      expect(res.status).toBe(200);
      expect(res.body.success).toBe(true);
    });

    it('offline reservation with assigneeDisplayName', async () => {
      const headers = await getAuthHeaders('creator');
      const res = await request(app)
        .post(`/v1/khatmat/${khatmaId}/hizb/3/reserve`)
        .set(headers)
        .send({
          assigneeKind: 'offline',
          assigneeDisplayName: 'Fatima',
        });

      expect(res.status).toBe(200);
      expect(res.body.success).toBe(true);
    });
  });
});
