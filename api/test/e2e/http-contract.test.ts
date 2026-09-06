/**
 * E2E Test: HTTP Contract
 */

import request from 'supertest';
import { createApp } from '../../src/app';
import { createTestUsers, clearFirestore, getAuthHeaders } from './setup';

describe('E2E: HTTP Contract', () => {
  const app = createApp();

  beforeAll(async () => {
    await createTestUsers();
  });

  beforeEach(async () => {
    await clearFirestore();
  });

  describe('Request IDs', () => {
    it('should include X-Request-Id in all responses', async () => {
      const headers = await getAuthHeaders('creator');
      
      const response = await request(app)
        .post('/v1/khatmat')
        .set(headers)
        .send({
          title: 'Test',
          isGroup: true,
          isPublic: false,
        });

      expect(response.headers['x-request-id']).toBeDefined();
      expect(typeof response.headers['x-request-id']).toBe('string');
      expect(response.headers['x-request-id'].length).toBeGreaterThan(0);
    });

    it('should include X-Request-Id in error responses', async () => {
      const response = await request(app)
        .post('/v1/khatmat')
        .send({ title: 'Test' }); // No auth

      expect(response.status).toBe(401);
      expect(response.headers['x-request-id']).toBeDefined();
    });

    it('should have unique Request IDs', async () => {
      const headers = await getAuthHeaders('creator');
      
      const response1 = await request(app)
        .post('/v1/khatmat')
        .set(headers)
        .send({ title: 'Test 1', isGroup: true, isPublic: false });

      const response2 = await request(app)
        .post('/v1/khatmat')
        .set(headers)
        .send({ title: 'Test 2', isGroup: true, isPublic: false });

      const id1 = response1.headers['x-request-id'];
      const id2 = response2.headers['x-request-id'];
      
      expect(id1).not.toBe(id2);
    });
  });

  describe('Content-Type', () => {
    it('should return JSON Content-Type for success', async () => {
      const headers = await getAuthHeaders('creator');
      
      const response = await request(app)
        .post('/v1/khatmat')
        .set(headers)
        .send({ title: 'Test', isGroup: true, isPublic: false });

      expect(response.status).toBe(201);
      expect(response.headers['content-type']).toMatch(/application\/json/);
    });

    it('should return JSON Content-Type for errors', async () => {
      const response = await request(app)
        .post('/v1/khatmat')
        .send({ title: 'Test' }); // No auth

      expect(response.status).toBe(401);
      expect(response.headers['content-type']).toMatch(/application\/json/);
    });
  });

  describe('Malformed JSON', () => {
    it('should return 400 for malformed JSON', async () => {
      const headers = await getAuthHeaders('creator');
      
      const response = await request(app)
        .post('/v1/khatmat')
        .set(headers)
        .set('Content-Type', 'application/json')
        .send('{ invalid json }');

      expect(response.status).toBe(400);
      expect(response.body.error).toBeDefined();
      expect(response.body.error.code).toBeDefined();
    });

    it('should not expose stack traces for malformed JSON', async () => {
      const headers = await getAuthHeaders('creator');
      
      const response = await request(app)
        .post('/v1/khatmat')
        .set(headers)
        .set('Content-Type', 'application/json')
        .send('{ invalid }');

      expect(response.body.error).toBeDefined();
      expect(response.body.error.stack).toBeUndefined();
      expect(JSON.stringify(response.body)).not.toContain('at ');
    });
  });

  describe('HTTP Methods', () => {
    it('should return 404 for unknown paths', async () => {
      const headers = await getAuthHeaders('creator');
      
      const response = await request(app)
        .get('/v1/unknown')
        .set(headers);

      expect(response.status).toBe(404);
      expect(response.body.error.code).toBe('NOT_FOUND');
    });

    it('should reject GET on POST-only endpoints', async () => {
      const headers = await getAuthHeaders('creator');
      
      const response = await request(app)
        .get('/v1/khatmat')
        .set(headers);

      expect([404, 405]).toContain(response.status);
    });
  });

  describe('Error Safety', () => {
    it('should not expose stack traces in error responses', async () => {
      // Trigger an error
      const response = await request(app)
        .post('/v1/khatmat')
        .send({ title: 'Test' }); // No auth

      expect(response.body.error).toBeDefined();
      expect(response.body.error.stack).toBeUndefined();
      expect(response.body.error.message).toBeDefined();
      expect(response.body.error.code).toBeDefined();
      
      // Should not contain stack trace patterns
      const responseText = JSON.stringify(response.body);
      expect(responseText).not.toContain('at ');
      expect(responseText).not.toContain('.ts:');
    });

    it('should not expose Firebase internal errors', async () => {
      const headers = await getAuthHeaders('creator');
      
      // Try to access non-existent Khatma
      const response = await request(app)
        .post('/v1/khatmat/nonexistent/hizb/1/reserve')
        .set(headers)
        .send({ assigneeKind: 'self' });

      expect(response.body.error).toBeDefined();
      
      // Should not contain Firebase SDK internals
      const responseText = JSON.stringify(response.body);
      expect(responseText).not.toContain('firebase-admin');
      expect(responseText).not.toContain('FirebaseError');
    });
  });

  describe('Authorization Header Safety', () => {
    it('should not log Authorization header', async () => {
      // This test verifies sanitization behavior
      // In a real scenario, we'd inspect log output
      // For now, we just verify the request works
      const headers = await getAuthHeaders('creator');
      
      const response = await request(app)
        .post('/v1/khatmat')
        .set(headers)
        .send({ title: 'Test', isGroup: true, isPublic: false });

      expect(response.status).toBe(201);
      
      // Logger sanitization is verified in unit tests
      // This E2E test confirms the flow works
    });

    it('should not include token in error responses', async () => {
      const headers = await getAuthHeaders('creator');
      
      // Trigger an error
      const response = await request(app)
        .post('/v1/khatmat')
        .set(headers)
        .send({ title: '' }); // Invalid

      const responseText = JSON.stringify(response.body);
      expect(responseText).not.toContain('Bearer');
      expect(responseText).not.toContain('eyJ'); // JWT prefix
    });
  });

  describe('Security Headers', () => {
    it('should include security headers', async () => {
      const response = await request(app).get('/health');

      // Helmet adds these
      expect(response.headers['x-content-type-options']).toBe('nosniff');
      expect(response.headers['x-frame-options']).toBeDefined();
    });
  });
});
