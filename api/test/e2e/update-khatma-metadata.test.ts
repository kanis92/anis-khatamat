/**
 * E2E Test: Update Khatma metadata
 */

import request from 'supertest';
import { createApp } from '../../src/app';
import * as admin from 'firebase-admin';
import { createTestUsers, clearFirestore, getAuthHeaders } from './setup';

describe('E2E: Update Khatma metadata', () => {
  const app = createApp();
  let khatmaId: string;

  beforeAll(async () => {
    await createTestUsers();
  });

  beforeEach(async () => {
    await clearFirestore();

    const headers = await getAuthHeaders('creator');
    const response = await request(app)
      .post('/v1/khatmat')
      .set(headers)
      .send({
        title: 'Original Title',
        isGroup: true,
        isPublic: false,
        objectives: 'Read together',
      });

    khatmaId = response.body.data.khatmaId;
  });

  it('should allow creator to update title and objectives via POST metadata', async () => {
    const headers = await getAuthHeaders('creator');

    const response = await request(app)
      .post(`/v1/khatmat/${khatmaId}/metadata`)
      .set(headers)
      .send({
        title: 'Updated Title',
        objectives: 'New goals',
      });

    expect(response.status).toBe(200);
    expect(response.body.data.success).toBe(true);
    expect(response.body.data.khatmaId).toBe(khatmaId);
    expect(response.body.data.title).toBe('Updated Title');

    const db = admin.firestore();
    const doc = await db.collection('khatmat').doc(khatmaId).get();
    expect(doc.data()?.title).toBe('Updated Title');
    expect(doc.data()?.objectives).toBe('New goals');
  });

  it('should allow creator to clear objectives via PATCH', async () => {
    const headers = await getAuthHeaders('creator');

    const response = await request(app)
      .patch(`/v1/khatmat/${khatmaId}`)
      .set(headers)
      .send({ objectives: null });

    expect(response.status).toBe(200);

    const db = admin.firestore();
    const doc = await db.collection('khatmat').doc(khatmaId).get();
    expect(doc.data()?.objectives).toBeUndefined();
  });

  it('should reject participant', async () => {
    const headers = await getAuthHeaders('participantA');

    const response = await request(app)
      .patch(`/v1/khatmat/${khatmaId}`)
      .set(headers)
      .send({ title: 'Hacked' });

    expect(response.status).toBe(403);
    expect(response.body.error.code).toBe('FORBIDDEN');
  });

  it('should reject outsider', async () => {
    const headers = await getAuthHeaders('outsider');

    const response = await request(app)
      .patch(`/v1/khatmat/${khatmaId}`)
      .set(headers)
      .send({ title: 'Hacked' });

    expect(response.status).toBe(403);
  });

  it('should reject forged createdBy in body', async () => {
    const headers = await getAuthHeaders('creator');

    const response = await request(app)
      .patch(`/v1/khatmat/${khatmaId}`)
      .set(headers)
      .send({ title: 'Ok', createdBy: 'forged@test.com' });

    expect(response.status).toBe(400);
    expect(response.body.error.message).toContain('createdBy');
  });
});
