/**
 * E2E Test: Release Hizb
 */

import request from 'supertest';
import { createApp } from '../../src/app';
import * as admin from 'firebase-admin';
import { createTestUsers, clearFirestore, getAuthHeaders, TEST_USERS } from './setup';

describe('E2E: Release Hizb', () => {
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
        members: [TEST_USERS.participantA.email],
      });
    
    khatmaId = response.body.data.khatmaId;
  });

  describe('Authorized Release', () => {
    it('should release own reserved Hizb', async () => {
      const headers = await getAuthHeaders('creator');
      
      // Reserve first
      await request(app)
        .post(`/v1/khatmat/${khatmaId}/hizb/1/reserve`)
        .set(headers)
        .send({ assigneeKind: 'self' });

      // Release
      const response = await request(app)
        .post(`/v1/khatmat/${khatmaId}/hizb/1/release`)
        .set(headers)
        .send({});

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
      expect(hizbData?.status).toBe('available');
      expect(hizbData?.reservedBy).toBeUndefined();
      expect(hizbData?.assigneeKind).toBeUndefined();
      expect(hizbData?.assigneeUserId).toBeUndefined();
      expect(hizbData?.assigneeDisplayName).toBeUndefined();
      expect(hizbData?.assignedByUserId).toBeUndefined();
    });

    it('should preserve canonical data after release', async () => {
      const headers = await getAuthHeaders('creator');
      
      // Reserve and release
      await request(app)
        .post(`/v1/khatmat/${khatmaId}/hizb/1/reserve`)
        .set(headers)
        .send({ assigneeKind: 'self' });

      await request(app)
        .post(`/v1/khatmat/${khatmaId}/hizb/1/release`)
        .set(headers)
        .send({});

      // Verify canonical fields unchanged
      const db = admin.firestore();
      const hizbDoc = await db
        .collection('khatmat').doc(khatmaId)
        .collection('hizb_reservations').doc('1')
        .get();
      
      const hizbData = hizbDoc.data();
      expect(hizbData?.hizbDefinitionId).toBe('quran_foundation_hafs_v1');
      expect(hizbData?.hizbNumber).toBe(1);
      expect(hizbData?.startVerseKey).toBeDefined();
      expect(hizbData?.endVerseKey).toBeDefined();
    });

    it('should not delete document on release', async () => {
      const headers = await getAuthHeaders('creator');
      
      // Reserve and release
      await request(app)
        .post(`/v1/khatmat/${khatmaId}/hizb/1/reserve`)
        .set(headers)
        .send({ assigneeKind: 'self' });

      await request(app)
        .post(`/v1/khatmat/${khatmaId}/hizb/1/release`)
        .set(headers)
        .send({});

      // Verify document still exists
      const db = admin.firestore();
      const hizbDoc = await db
        .collection('khatmat').doc(khatmaId)
        .collection('hizb_reservations').doc('1')
        .get();
      
      expect(hizbDoc.exists).toBe(true);
    });

    it('should allow organizer to release participant reservation', async () => {
      const creatorHeaders = await getAuthHeaders('creator');
      
      // Organizer assigns to participant via /assign
      await request(app)
        .post(`/v1/khatmat/${khatmaId}/hizb/1/assign`)
        .set(creatorHeaders)
        .send({
          participantUserId: TEST_USERS.participantA.email,
        });

      // Organizer releases
      const response = await request(app)
        .post(`/v1/khatmat/${khatmaId}/hizb/1/release`)
        .set(creatorHeaders)
        .send({});

      expect(response.status).toBe(200);
      
      // Verify available
      const db = admin.firestore();
      const hizbDoc = await db
        .collection('khatmat').doc(khatmaId)
        .collection('hizb_reservations').doc('1')
        .get();
      
      expect(hizbDoc.data()?.status).toBe('available');
    });
  });

  describe('Unauthorized Release', () => {
    it('should reject outsider releasing reserved Hizb', async () => {
      const creatorHeaders = await getAuthHeaders('creator');
      const outsiderHeaders = await getAuthHeaders('outsider');
      
      // Creator reserves
      await request(app)
        .post(`/v1/khatmat/${khatmaId}/hizb/1/reserve`)
        .set(creatorHeaders)
        .send({ assigneeKind: 'self' });

      // Outsider tries to release
      const response = await request(app)
        .post(`/v1/khatmat/${khatmaId}/hizb/1/release`)
        .set(outsiderHeaders)
        .send({});

      expect(response.status).toBe(403);
      expect(response.body.error.code).toBe('FORBIDDEN');
    });

    it('should reject participant releasing another participant Hizb', async () => {
      const creatorHeaders = await getAuthHeaders('creator');
      const participantHeaders = await getAuthHeaders('participantA');
      
      // Creator reserves
      await request(app)
        .post(`/v1/khatmat/${khatmaId}/hizb/1/reserve`)
        .set(creatorHeaders)
        .send({ assigneeKind: 'self' });

      // Participant tries to release
      const response = await request(app)
        .post(`/v1/khatmat/${khatmaId}/hizb/1/release`)
        .set(participantHeaders)
        .send({});

      expect(response.status).toBe(403);
      expect(response.body.error.code).toBe('FORBIDDEN');
    });
  });

  describe('Invalid State', () => {
    it('should reject releasing available Hizb', async () => {
      const headers = await getAuthHeaders('creator');
      
      // Try to release without reserving
      const response = await request(app)
        .post(`/v1/khatmat/${khatmaId}/hizb/1/release`)
        .set(headers)
        .send({});

      expect(response.status).toBe(409);
      expect(response.body.error.code).toBe('CONFLICT');
    });

    it('should reject releasing completed Hizb', async () => {
      const headers = await getAuthHeaders('creator');
      
      // Reserve and complete
      await request(app)
        .post(`/v1/khatmat/${khatmaId}/hizb/1/reserve`)
        .set(headers)
        .send({ assigneeKind: 'self' });

      await request(app)
        .post(`/v1/khatmat/${khatmaId}/hizb/1/complete`)
        .set(headers)
        .send({});

      // Try to release completed Hizb
      const response = await request(app)
        .post(`/v1/khatmat/${khatmaId}/hizb/1/release`)
        .set(headers)
        .send({});

      expect(response.status).toBe(409);
      expect(response.body.error.code).toBe('CONFLICT');
    });
  });

  describe('Offline Assignment Release', () => {
    it('should release offline assignment', async () => {
      const headers = await getAuthHeaders('creator');
      
      // Reserve for offline person
      await request(app)
        .post(`/v1/khatmat/${khatmaId}/hizb/1/reserve`)
        .set(headers)
        .send({
          assigneeKind: 'offline',
          assigneeDisplayName: 'Fatima',
        });

      // Release
      const response = await request(app)
        .post(`/v1/khatmat/${khatmaId}/hizb/1/release`)
        .set(headers)
        .send({});

      expect(response.status).toBe(200);

      // Verify all assignee fields cleared
      const db = admin.firestore();
      const hizbDoc = await db
        .collection('khatmat').doc(khatmaId)
        .collection('hizb_reservations').doc('1')
        .get();
      
      const hizbData = hizbDoc.data();
      expect(hizbData?.status).toBe('available');
      expect(hizbData?.assigneeDisplayName).toBeUndefined();
      expect(hizbData?.assigneeKind).toBeUndefined();
    });
  });

  describe('Persistence', () => {
    it('should persist release across API calls', async () => {
      const headers = await getAuthHeaders('creator');
      const db = admin.firestore();
      
      // Reserve and release
      await request(app)
        .post(`/v1/khatmat/${khatmaId}/hizb/1/reserve`)
        .set(headers)
        .send({ assigneeKind: 'self' });

      await request(app)
        .post(`/v1/khatmat/${khatmaId}/hizb/1/release`)
        .set(headers)
        .send({});

      // Read directly from Firestore
      const hizbDoc = await db
        .collection('khatmat').doc(khatmaId)
        .collection('hizb_reservations').doc('1')
        .get();
      
      expect(hizbDoc.data()?.status).toBe('available');

      // Wait and verify persistence
      await new Promise(resolve => setTimeout(resolve, 100));
      
      const hizbDoc2 = await db
        .collection('khatmat').doc(khatmaId)
        .collection('hizb_reservations').doc('1')
        .get();
      
      expect(hizbDoc2.data()?.status).toBe('available');
    });
  });
});
