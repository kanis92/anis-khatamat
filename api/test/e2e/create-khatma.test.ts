/**
 * E2E Test: Create Khatma
 */

import request from 'supertest';
import { createApp } from '../../src/app';
import * as admin from 'firebase-admin';
import { createTestUsers, clearFirestore, getAuthHeaders, TEST_USERS } from './setup';

describe('E2E: Create Khatma', () => {
  const app = createApp();
  let khatmaId: string;

  beforeAll(async () => {
    await createTestUsers();
  });

  beforeEach(async () => {
    await clearFirestore();
  });

  describe('Authenticated Create', () => {
    it('should create Khatma with 60 canonical Hizb', async () => {
      const headers = await getAuthHeaders('creator');
      
      const response = await request(app)
        .post('/v1/khatmat')
        .set(headers)
        .send({
          title: 'Test Khatma',
          isGroup: true,
          isPublic: false,
        });

      expect(response.status).toBe(201);
      expect(response.body.data).toHaveProperty('khatmaId');
      expect(response.headers['x-request-id']).toBeDefined();
      
      khatmaId = response.body.data.khatmaId;

      // Verify parent document
      const db = admin.firestore();
      const khatmaDoc = await db.collection('khatmat').doc(khatmaId).get();
      
      expect(khatmaDoc.exists).toBe(true);
      const khatmaData = khatmaDoc.data();
      expect(khatmaData?.creationState).toBe('ready');
      expect(khatmaData?.createdBy).toBe(TEST_USERS.creator.email);
      expect(khatmaData?.title).toBe('Test Khatma');
      expect(khatmaData?.isGroup).toBe(true);
      expect(khatmaData?.reservationMode).toBe(true);
      expect(khatmaData?.completedHizbCount).toBe(0);

      // Verify exactly 60 Hizb
      const reservations = await khatmaDoc.ref.collection('hizb_reservations').get();
      expect(reservations.size).toBe(60);

      // Verify Hizb IDs 1-60
      const hizbNumbers = reservations.docs.map(doc => parseInt(doc.id)).sort((a, b) => a - b);
      expect(hizbNumbers).toEqual(Array.from({ length: 60 }, (_, i) => i + 1));

      // Verify canonical data
      const firstHizb = reservations.docs.find(doc => doc.id === '1');
      expect(firstHizb).toBeDefined();
      const hizbData = firstHizb!.data();
      expect(hizbData.hizbDefinitionId).toBe('quran_foundation_hafs_v1');
      expect(hizbData.status).toBe('available');
      expect(hizbData.hizbNumber).toBe(1);
      expect(hizbData.startVerseKey).toBeDefined();
      expect(hizbData.endVerseKey).toBeDefined();
    });

    it('should reject client-provided createdBy', async () => {
      const headers = await getAuthHeaders('creator');
      
      const response = await request(app)
        .post('/v1/khatmat')
        .set(headers)
        .send({
          title: 'Test Khatma',
          isGroup: true,
          isPublic: false,
          createdBy: 'forged@user.com', // Should be rejected
        });

      expect(response.status).toBe(400);
      expect(response.body.error.code).toBe('INVALID_ARGUMENT');
      expect(response.body.error.message).toContain('createdBy');
    });

    it('should reject client-provided creationState', async () => {
      const headers = await getAuthHeaders('creator');
      
      const response = await request(app)
        .post('/v1/khatmat')
        .set(headers)
        .send({
          title: 'Test Khatma',
          isGroup: true,
          isPublic: false,
          creationState: 'ready', // Should be rejected
        });

      expect(response.status).toBe(400);
      expect(response.body.error.code).toBe('INVALID_ARGUMENT');
    });
  });

  describe('Unauthenticated', () => {
    it('should return 401 AUTH_REQUIRED', async () => {
      const response = await request(app)
        .post('/v1/khatmat')
        .send({
          title: 'Test Khatma',
          isGroup: true,
          isPublic: false,
        });

      expect(response.status).toBe(401);
      expect(response.body.error.code).toBe('AUTH_REQUIRED');
    });
  });

  describe('Invalid Input', () => {
    it('should reject empty title', async () => {
      const headers = await getAuthHeaders('creator');
      
      const response = await request(app)
        .post('/v1/khatmat')
        .set(headers)
        .send({
          title: '',
          isGroup: true,
          isPublic: false,
        });

      expect(response.status).toBe(400);
      expect(response.body.error.code).toBe('INVALID_ARGUMENT');
    });
  });
});
