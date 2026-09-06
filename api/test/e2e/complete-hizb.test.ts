/**
 * E2E Test: Complete Hizb
 */

import request from 'supertest';
import { createApp } from '../../src/app';
import * as admin from 'firebase-admin';
import { createTestUsers, clearFirestore, getAuthHeaders, TEST_USERS } from './setup';

describe('E2E: Complete Hizb', () => {
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

  describe('Authorized Completion', () => {
    it('should complete own reserved Hizb', async () => {
      const headers = await getAuthHeaders('creator');
      
      // Reserve first
      await request(app)
        .post(`/v1/khatmat/${khatmaId}/hizb/1/reserve`)
        .set(headers)
        .send({ assigneeKind: 'self' });

      // Complete
      const response = await request(app)
        .post(`/v1/khatmat/${khatmaId}/hizb/1/complete`)
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
      expect(hizbData?.status).toBe('completed');
      expect(hizbData?.completedBy).toBe(TEST_USERS.creator.email);
      expect(hizbData?.completedAt).toBeDefined();
      
      // Verify Khatma counter incremented
      const khatmaDoc = await db.collection('khatmat').doc(khatmaId).get();
      const khatmaData = khatmaDoc.data();
      expect(khatmaData?.completedHizbCount).toBe(1);
    });

    it('should preserve canonical data after completion', async () => {
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
  });

  describe('Unauthorized Completion', () => {
    it('should reject outsider completing reserved Hizb', async () => {
      const creatorHeaders = await getAuthHeaders('creator');
      const outsiderHeaders = await getAuthHeaders('outsider');
      
      // Creator reserves
      await request(app)
        .post(`/v1/khatmat/${khatmaId}/hizb/1/reserve`)
        .set(creatorHeaders)
        .send({ assigneeKind: 'self' });

      // Outsider tries to complete
      const response = await request(app)
        .post(`/v1/khatmat/${khatmaId}/hizb/1/complete`)
        .set(outsiderHeaders)
        .send({});

      expect(response.status).toBe(403);
      expect(response.body.error.code).toBe('FORBIDDEN');
    });

    it('should reject participant completing another participant Hizb', async () => {
      const creatorHeaders = await getAuthHeaders('creator');
      const participantHeaders = await getAuthHeaders('participantA');
      
      // Creator reserves
      await request(app)
        .post(`/v1/khatmat/${khatmaId}/hizb/1/reserve`)
        .set(creatorHeaders)
        .send({ assigneeKind: 'self' });

      // Participant tries to complete
      const response = await request(app)
        .post(`/v1/khatmat/${khatmaId}/hizb/1/complete`)
        .set(participantHeaders)
        .send({});

      expect(response.status).toBe(403);
      expect(response.body.error.code).toBe('FORBIDDEN');
    });
  });

  describe('Invalid State', () => {
    it('should reject completing available Hizb directly', async () => {
      const headers = await getAuthHeaders('creator');
      
      // Try to complete without reserving
      const response = await request(app)
        .post(`/v1/khatmat/${khatmaId}/hizb/1/complete`)
        .set(headers)
        .send({});

      expect(response.status).toBe(409);
      expect(response.body.error.code).toBe('CONFLICT');
    });

    it('should reject completing already completed Hizb', async () => {
      const headers = await getAuthHeaders('creator');
      
      // Reserve and complete once
      await request(app)
        .post(`/v1/khatmat/${khatmaId}/hizb/1/reserve`)
        .set(headers)
        .send({ assigneeKind: 'self' });

      await request(app)
        .post(`/v1/khatmat/${khatmaId}/hizb/1/complete`)
        .set(headers)
        .send({});

      // Try to complete again
      const response = await request(app)
        .post(`/v1/khatmat/${khatmaId}/hizb/1/complete`)
        .set(headers)
        .send({});

      expect(response.status).toBe(409);
      expect(response.body.error.code).toBe('CONFLICT');
    });
  });

  describe('Counter Invariants', () => {
    it('should increment completed count correctly', async () => {
      const headers = await getAuthHeaders('creator');
      const db = admin.firestore();
      
      // Complete 3 Hizb
      for (let i = 1; i <= 3; i++) {
        await request(app)
          .post(`/v1/khatmat/${khatmaId}/hizb/${i}/reserve`)
          .set(headers)
          .send({ assigneeKind: 'self' });

        await request(app)
          .post(`/v1/khatmat/${khatmaId}/hizb/${i}/complete`)
          .set(headers)
          .send({});
      }

      // Verify counter
      const khatmaDoc = await db.collection('khatmat').doc(khatmaId).get();
      const khatmaData = khatmaDoc.data();
      expect(khatmaData?.completedHizbCount).toBe(3);
    });
  });

  describe('Persistence', () => {
    it('should persist completion across API calls', async () => {
      const headers = await getAuthHeaders('creator');
      const db = admin.firestore();
      
      // Reserve and complete
      await request(app)
        .post(`/v1/khatmat/${khatmaId}/hizb/1/reserve`)
        .set(headers)
        .send({ assigneeKind: 'self' });

      await request(app)
        .post(`/v1/khatmat/${khatmaId}/hizb/1/complete`)
        .set(headers)
        .send({});

      // Read directly from Firestore
      const hizbDoc = await db
        .collection('khatmat').doc(khatmaId)
        .collection('hizb_reservations').doc('1')
        .get();
      
      expect(hizbDoc.data()?.status).toBe('completed');

      // Wait a bit and verify state persists
      await new Promise(resolve => setTimeout(resolve, 100));
      
      const hizbDoc2 = await db
        .collection('khatmat').doc(khatmaId)
        .collection('hizb_reservations').doc('1')
        .get();
      
      expect(hizbDoc2.data()?.status).toBe('completed');
    });
  });

  describe('Forged Data Rejection', () => {
    it('should reject client-provided completedBy', async () => {
      const headers = await getAuthHeaders('creator');
      
      // Reserve first
      await request(app)
        .post(`/v1/khatmat/${khatmaId}/hizb/1/reserve`)
        .set(headers)
        .send({ assigneeKind: 'self' });

      // Try to complete with forged completedBy
      const response = await request(app)
        .post(`/v1/khatmat/${khatmaId}/hizb/1/complete`)
        .set(headers)
        .send({
          completedBy: 'forged@user.com',
        });

      expect(response.status).toBe(400);
      expect(response.body.error.code).toBe('INVALID_ARGUMENT');
    });
  });
});
