/**
 * E2E Test: Reserve Hizb
 */

import request from 'supertest';
import { createApp } from '../../src/app';
import * as admin from 'firebase-admin';
import { createTestUsers, clearFirestore, getAuthHeaders, TEST_USERS } from './setup';

describe('E2E: Reserve Hizb', () => {
  const app = createApp();
  let khatmaId: string;

  beforeAll(async () => {
    await createTestUsers();
  });

  beforeEach(async () => {
    await clearFirestore();
    
    // Create test Khatma
    const headers = await getAuthHeaders('creator');
    const response = await request(app)
      .post('/v1/khatmat')
      .set(headers)
      .send({
        title: 'Test Khatma',
        isGroup: true,
        isPublic: false,
        members: [TEST_USERS.participantA.email, TEST_USERS.participantB.email],
      });
    
    khatmaId = response.body.data.khatmaId;
  });

  describe('Self Reservation', () => {
    it('should reserve Hizb for self', async () => {
      const headers = await getAuthHeaders('creator');
      
      const response = await request(app)
        .post(`/v1/khatmat/${khatmaId}/hizb/1/reserve`)
        .set(headers)
        .send({
          assigneeKind: 'self',
        });

      expect(response.status).toBe(200);
      expect(response.body.success).toBe(true);
      expect(response.headers['x-request-id']).toBeDefined();

      // Verify Firestore
      const db = admin.firestore();
      const hizbDoc = await db
        .collection('khatmat').doc(khatmaId)
        .collection('hizb_reservations').doc('1')
        .get();
      
      const hizbData = hizbDoc.data();
      expect(hizbData?.status).toBe('reserved');
      expect(hizbData?.reservedBy).toBe(TEST_USERS.creator.email);
      expect(hizbData?.assigneeKind).toBe('self');
      expect(hizbData?.assigneeUserId).toBe(TEST_USERS.creator.email);
      expect(hizbData?.assignedByUserId).toBeUndefined();
      expect(hizbData?.completedBy).toBeUndefined();
    });

    it('should reject forged reservedBy', async () => {
      const headers = await getAuthHeaders('creator');
      
      const response = await request(app)
        .post(`/v1/khatmat/${khatmaId}/hizb/1/reserve`)
        .set(headers)
        .send({
          assigneeKind: 'self',
          reservedBy: 'forged@user.com',
        });

      expect(response.status).toBe(400);
      expect(response.body.error.code).toBe('INVALID_ARGUMENT');
    });
  });

  describe('Offline Reservation (Fatima)', () => {
    it('should reserve for offline person', async () => {
      const headers = await getAuthHeaders('creator');
      
      const response = await request(app)
        .post(`/v1/khatmat/${khatmaId}/hizb/2/reserve`)
        .set(headers)
        .send({
          assigneeKind: 'offline',
          assigneeDisplayName: 'Fatima',
        });

      expect(response.status).toBe(200);
      expect(response.body.success).toBe(true);

      // Verify Firestore
      const db = admin.firestore();
      const hizbDoc = await db
        .collection('khatmat').doc(khatmaId)
        .collection('hizb_reservations').doc('2')
        .get();
      
      const hizbData = hizbDoc.data();
      expect(hizbData?.status).toBe('reserved');
      expect(hizbData?.reservedBy).toBe(TEST_USERS.creator.email);
      expect(hizbData?.assigneeKind).toBe('offline');
      expect(hizbData?.assigneeDisplayName).toBe('Fatima');
      expect(hizbData?.assigneeUserId).toBeUndefined();
      expect(hizbData?.assignedByUserId).toBeUndefined();
      
      // Verify no fake Firebase user created
      try {
        const auth = admin.auth();
        await auth.getUserByEmail('fatima@fake.com');
        fail('Should not have created fake user');
      } catch (error: any) {
        expect(error.code).toBe('auth/user-not-found');
      }
    });

    it('should reject empty display name', async () => {
      const headers = await getAuthHeaders('creator');
      
      const response = await request(app)
        .post(`/v1/khatmat/${khatmaId}/hizb/2/reserve`)
        .set(headers)
        .send({
          assigneeKind: 'offline',
          assigneeDisplayName: '',
        });

      expect(response.status).toBe(400);
      expect(response.body.error.code).toBe('INVALID_ARGUMENT');
    });

    it('should reject offline with forged assigneeUserId', async () => {
      const headers = await getAuthHeaders('creator');
      
      const response = await request(app)
        .post(`/v1/khatmat/${khatmaId}/hizb/2/reserve`)
        .set(headers)
        .send({
          assigneeKind: 'offline',
          assigneeDisplayName: 'Fatima',
          assigneeUserId: 'forged@user.com',
        });

      expect(response.status).toBe(400);
      expect(response.body.error.code).toBe('INVALID_ARGUMENT');
    });
  });

  describe('Participant Assignment', () => {
    it('should allow organizer to assign to participant via /assign', async () => {
      const headers = await getAuthHeaders('creator');
      
      const response = await request(app)
        .post(`/v1/khatmat/${khatmaId}/hizb/3/assign`)
        .set(headers)
        .send({
          participantUserId: TEST_USERS.participantA.email,
        });

      expect(response.status).toBe(200);
      expect(response.body.success).toBe(true);

      // Verify Firestore
      const db = admin.firestore();
      const hizbDoc = await db
        .collection('khatmat').doc(khatmaId)
        .collection('hizb_reservations').doc('3')
        .get();
      
      const hizbData = hizbDoc.data();
      expect(hizbData?.status).toBe('reserved');
      expect(hizbData?.reservedBy).toBe(TEST_USERS.participantA.email);
      expect(hizbData?.assigneeKind).toBe('participant');
      expect(hizbData?.assigneeUserId).toBe(TEST_USERS.participantA.email);
      expect(hizbData?.assignedByUserId).toBe(TEST_USERS.creator.email);
    });

    it('should reject normal participant trying to assign via /assign', async () => {
      const headers = await getAuthHeaders('participantA');
      
      const response = await request(app)
        .post(`/v1/khatmat/${khatmaId}/hizb/3/assign`)
        .set(headers)
        .send({
          participantUserId: TEST_USERS.participantB.email,
        });

      expect(response.status).toBe(403);
      expect(response.body.error.code).toBe('FORBIDDEN');
    });

    it('should reject outsider trying to assign via /assign', async () => {
      const headers = await getAuthHeaders('outsider');
      
      const response = await request(app)
        .post(`/v1/khatmat/${khatmaId}/hizb/3/assign`)
        .set(headers)
        .send({
          participantUserId: TEST_USERS.participantA.email,
        });

      expect(response.status).toBe(403);
      expect(response.body.error.code).toBe('FORBIDDEN');
    });
  });

  describe('Concurrency Control', () => {
    it('should allow exactly ONE of two concurrent reservations', async () => {
      const headersA = await getAuthHeaders('participantA');
      const headersB = await getAuthHeaders('participantB');
      
      // Both try to reserve Hizb 5 simultaneously
      const results = await Promise.allSettled([
        request(app)
          .post(`/v1/khatmat/${khatmaId}/hizb/5/reserve`)
          .set(headersA)
          .send({ assigneeKind: 'self' }),
        request(app)
          .post(`/v1/khatmat/${khatmaId}/hizb/5/reserve`)
          .set(headersB)
          .send({ assigneeKind: 'self' }),
      ]);

      // Count successes and conflicts
      const successes = results.filter(r => 
        r.status === 'fulfilled' && r.value.status === 200
      );
      const conflicts = results.filter(r => 
        r.status === 'fulfilled' && r.value.status === 409
      );

      expect(successes.length).toBe(1);
      expect(conflicts.length).toBe(1);
      
      // Verify conflict error code
      const conflictResponse = conflicts[0] as PromiseFulfilledResult<any>;
      expect(conflictResponse.value.body.error.code).toBe('CONFLICT');

      // Verify Firestore has only one reservation
      const db = admin.firestore();
      const hizbDoc = await db
        .collection('khatmat').doc(khatmaId)
        .collection('hizb_reservations').doc('5')
        .get();
      
      const hizbData = hizbDoc.data();
      expect(hizbData?.status).toBe('reserved');
      const reservedBy = hizbData?.reservedBy;
      expect([TEST_USERS.participantA.email, TEST_USERS.participantB.email])
        .toContain(reservedBy);
    });

    it('should be deterministic across multiple runs', async () => {
      for (let run = 0; run < 3; run++) {
        // Clear and create fresh Khatma for each run
        await clearFirestore();
        const headers = await getAuthHeaders('creator');
        const createResponse = await request(app)
          .post('/v1/khatmat')
          .set(headers)
          .send({
            title: `Test Khatma ${run}`,
            isGroup: true,
            isPublic: false,
            members: [TEST_USERS.participantA.email, TEST_USERS.participantB.email],
          });
        
        const testKhatmaId = createResponse.body.data.khatmaId;
        
        const headersA = await getAuthHeaders('participantA');
        const headersB = await getAuthHeaders('participantB');
        
        const results = await Promise.allSettled([
          request(app)
            .post(`/v1/khatmat/${testKhatmaId}/hizb/10/reserve`)
            .set(headersA)
            .send({ assigneeKind: 'self' }),
          request(app)
            .post(`/v1/khatmat/${testKhatmaId}/hizb/10/reserve`)
            .set(headersB)
            .send({ assigneeKind: 'self' }),
        ]);

        const successes = results.filter(r => 
          r.status === 'fulfilled' && r.value.status === 200
        );
        
        expect(successes.length).toBe(1);
      }
    });
  });

  describe('Invalid Input', () => {
    it('should reject hizbNumber 0', async () => {
      const headers = await getAuthHeaders('creator');
      
      const response = await request(app)
        .post(`/v1/khatmat/${khatmaId}/hizb/0/reserve`)
        .set(headers)
        .send({ assigneeKind: 'self' });

      expect(response.status).toBe(400);
      expect(response.body.error.code).toBe('INVALID_ARGUMENT');
    });

    it('should reject hizbNumber 61', async () => {
      const headers = await getAuthHeaders('creator');
      
      const response = await request(app)
        .post(`/v1/khatmat/${khatmaId}/hizb/61/reserve`)
        .set(headers)
        .send({ assigneeKind: 'self' });

      expect(response.status).toBe(400);
      expect(response.body.error.code).toBe('INVALID_ARGUMENT');
    });

    it('should reject non-integer hizbNumber', async () => {
      const headers = await getAuthHeaders('creator');
      
      const response = await request(app)
        .post(`/v1/khatmat/${khatmaId}/hizb/abc/reserve`)
        .set(headers)
        .send({ assigneeKind: 'self' });

      expect(response.status).toBe(400);
      expect(response.body.error.code).toBe('INVALID_ARGUMENT');
    });

    it('should reject unknown Khatma', async () => {
      const headers = await getAuthHeaders('creator');
      
      const response = await request(app)
        .post(`/v1/khatmat/nonexistent/hizb/1/reserve`)
        .set(headers)
        .send({ assigneeKind: 'self' });

      expect(response.status).toBe(404);
      expect(response.body.error.code).toBe('NOT_FOUND');
    });
  });
});
