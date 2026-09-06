/**
 * E2E Test: Counter Invariants
 */

import request from 'supertest';
import { createApp } from '../../src/app';
import * as admin from 'firebase-admin';
import { createTestUsers, clearFirestore, getAuthHeaders, TEST_USERS } from './setup';

describe('E2E: Counter Invariants', () => {
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

  describe('Completed + Reserved + Available = 60', () => {
    it('should maintain invariant after various operations', async () => {
      const headers = await getAuthHeaders('creator');
      const db = admin.firestore();
      
      // Initial: 0 completed + 0 reserved + 60 available = 60
      let reservations = await db
        .collection('khatmat').doc(khatmaId)
        .collection('hizb_reservations')
        .get();
      
      let completed = reservations.docs.filter(d => d.data().status === 'completed').length;
      let reserved = reservations.docs.filter(d => d.data().status === 'reserved').length;
      let available = reservations.docs.filter(d => d.data().status === 'available').length;
      
      expect(completed + reserved + available).toBe(60);
      expect(completed).toBe(0);
      expect(reserved).toBe(0);
      expect(available).toBe(60);

      // Reserve 3 Hizb
      for (let i = 1; i <= 3; i++) {
        await request(app)
          .post(`/v1/khatmat/${khatmaId}/hizb/${i}/reserve`)
          .set(headers)
          .send({ assigneeKind: 'self' });
      }

      // After reserve: 0 completed + 3 reserved + 57 available = 60
      reservations = await db
        .collection('khatmat').doc(khatmaId)
        .collection('hizb_reservations')
        .get();
      
      completed = reservations.docs.filter(d => d.data().status === 'completed').length;
      reserved = reservations.docs.filter(d => d.data().status === 'reserved').length;
      available = reservations.docs.filter(d => d.data().status === 'available').length;
      
      expect(completed + reserved + available).toBe(60);
      expect(completed).toBe(0);
      expect(reserved).toBe(3);
      expect(available).toBe(57);

      // Complete 2 Hizb
      await request(app)
        .post(`/v1/khatmat/${khatmaId}/hizb/1/complete`)
        .set(headers)
        .send({});

      await request(app)
        .post(`/v1/khatmat/${khatmaId}/hizb/2/complete`)
        .set(headers)
        .send({});

      // After complete: 2 completed + 1 reserved + 57 available = 60
      reservations = await db
        .collection('khatmat').doc(khatmaId)
        .collection('hizb_reservations')
        .get();
      
      completed = reservations.docs.filter(d => d.data().status === 'completed').length;
      reserved = reservations.docs.filter(d => d.data().status === 'reserved').length;
      available = reservations.docs.filter(d => d.data().status === 'available').length;
      
      expect(completed + reserved + available).toBe(60);
      expect(completed).toBe(2);
      expect(reserved).toBe(1);
      expect(available).toBe(57);

      // Release 1 Hizb
      await request(app)
        .post(`/v1/khatmat/${khatmaId}/hizb/3/release`)
        .set(headers)
        .send({});

      // After release: 2 completed + 0 reserved + 58 available = 60
      reservations = await db
        .collection('khatmat').doc(khatmaId)
        .collection('hizb_reservations')
        .get();
      
      completed = reservations.docs.filter(d => d.data().status === 'completed').length;
      reserved = reservations.docs.filter(d => d.data().status === 'reserved').length;
      available = reservations.docs.filter(d => d.data().status === 'available').length;
      
      expect(completed + reserved + available).toBe(60);
      expect(completed).toBe(2);
      expect(reserved).toBe(0);
      expect(available).toBe(58);
    });
  });

  describe('Completed Hizb Count', () => {
    it('should match Khatma completedHizbCount field', async () => {
      const headers = await getAuthHeaders('creator');
      const db = admin.firestore();
      
      // Complete 5 Hizb
      for (let i = 1; i <= 5; i++) {
        await request(app)
          .post(`/v1/khatmat/${khatmaId}/hizb/${i}/reserve`)
          .set(headers)
          .send({ assigneeKind: 'self' });

        await request(app)
          .post(`/v1/khatmat/${khatmaId}/hizb/${i}/complete`)
          .set(headers)
          .send({});
      }

      // Verify Khatma counter
      const khatmaDoc = await db.collection('khatmat').doc(khatmaId).get();
      const khatmaData = khatmaDoc.data();
      expect(khatmaData?.completedHizbCount).toBe(5);

      // Verify actual completed count
      const reservations = await db
        .collection('khatmat').doc(khatmaId)
        .collection('hizb_reservations')
        .get();
      
      const completedCount = reservations.docs.filter(d => 
        d.data().status === 'completed'
      ).length;
      
      expect(completedCount).toBe(5);
      expect(khatmaData?.completedHizbCount).toBe(completedCount);
    });
  });

  describe('No Negative Counters', () => {
    it('should never have negative counts', async () => {
      const headers = await getAuthHeaders('creator');
      const db = admin.firestore();
      
      // Perform various operations
      await request(app)
        .post(`/v1/khatmat/${khatmaId}/hizb/1/reserve`)
        .set(headers)
        .send({ assigneeKind: 'self' });

      await request(app)
        .post(`/v1/khatmat/${khatmaId}/hizb/1/release`)
        .set(headers)
        .send({});

      await request(app)
        .post(`/v1/khatmat/${khatmaId}/hizb/1/reserve`)
        .set(headers)
        .send({ assigneeKind: 'self' });

      await request(app)
        .post(`/v1/khatmat/${khatmaId}/hizb/1/complete`)
        .set(headers)
        .send({});

      // Verify non-negative
      const khatmaDoc = await db.collection('khatmat').doc(khatmaId).get();
      const khatmaData = khatmaDoc.data();
      expect(khatmaData?.completedHizbCount).toBeGreaterThanOrEqual(0);
      
      const reservations = await db
        .collection('khatmat').doc(khatmaId)
        .collection('hizb_reservations')
        .get();
      
      const completed = reservations.docs.filter(d => d.data().status === 'completed').length;
      const reserved = reservations.docs.filter(d => d.data().status === 'reserved').length;
      const available = reservations.docs.filter(d => d.data().status === 'available').length;
      
      expect(completed).toBeGreaterThanOrEqual(0);
      expect(reserved).toBeGreaterThanOrEqual(0);
      expect(available).toBeGreaterThanOrEqual(0);
    });
  });

  describe('No Impossible Counts', () => {
    it('should never exceed 60 total Hizb', async () => {
      const headers = await getAuthHeaders('creator');
      const db = admin.firestore();
      
      // Reserve all 60
      for (let i = 1; i <= 60; i++) {
        await request(app)
          .post(`/v1/khatmat/${khatmaId}/hizb/${i}/reserve`)
          .set(headers)
          .send({ assigneeKind: 'self' });
      }

      // Verify exactly 60
      const reservations = await db
        .collection('khatmat').doc(khatmaId)
        .collection('hizb_reservations')
        .get();
      
      expect(reservations.size).toBe(60);
      
      const reserved = reservations.docs.filter(d => d.data().status === 'reserved').length;
      expect(reserved).toBe(60);
    });

    it('should never have completed > 60', async () => {
      const headers = await getAuthHeaders('creator');
      const db = admin.firestore();
      
      // Complete many Hizb
      for (let i = 1; i <= 20; i++) {
        await request(app)
          .post(`/v1/khatmat/${khatmaId}/hizb/${i}/reserve`)
          .set(headers)
          .send({ assigneeKind: 'self' });

        await request(app)
          .post(`/v1/khatmat/${khatmaId}/hizb/${i}/complete`)
          .set(headers)
          .send({});
      }

      // Verify <= 60
      const khatmaDoc = await db.collection('khatmat').doc(khatmaId).get();
      const khatmaData = khatmaDoc.data();
      expect(khatmaData?.completedHizbCount).toBeLessThanOrEqual(60);
      expect(khatmaData?.completedHizbCount).toBe(20);
    });
  });
});
