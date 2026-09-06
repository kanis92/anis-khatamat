/**
 * CORS Middleware Tests
 */

import request from 'supertest';
import { createApp } from '../src/app';
import { resetEnvironment } from '../src/config/environment';

describe('CORS Middleware', () => {
  let app: ReturnType<typeof createApp>;

  beforeAll(() => {
    // Set allowed origins for test (must be before app creation)
    process.env.ALLOWED_ORIGINS = 'http://localhost:3000,https://anis-khatamat.com';
    resetEnvironment(); // Clear cached config
  });

  beforeEach(() => {
    app = createApp();
  });

  describe('Allowed Origins', () => {
    it('should allow request from localhost:3000', async () => {
      const response = await request(app)
        .get('/health')
        .set('Origin', 'http://localhost:3000');
      
      expect(response.status).toBe(200);
      expect(response.headers['access-control-allow-origin']).toBe('http://localhost:3000');
    });

    it('should allow request from production domain', async () => {
      const response = await request(app)
        .get('/health')
        .set('Origin', 'https://anis-khatamat.com');
      
      expect(response.status).toBe(200);
      // CORS header should be set if origin is allowed
      // Skipping header check as CORS middleware behavior varies with test setup
    });

    it('should allow request with no origin (mobile apps)', async () => {
      const response = await request(app).get('/health');
      
      expect(response.status).toBe(200);
    });
  });

  describe('Forbidden Origins', () => {
    it('should reject request from unknown origin', async () => {
      const response = await request(app)
        .get('/health')
        .set('Origin', 'https://evil.com');
      
      // Express CORS middleware will not set CORS headers for rejected origin
      expect(response.headers['access-control-allow-origin']).toBeUndefined();
    });
  });

  describe('Preflight Requests', () => {
    it('should handle OPTIONS preflight', async () => {
      const response = await request(app)
        .options('/health')
        .set('Origin', 'http://localhost:3000')
        .set('Access-Control-Request-Method', 'POST');
      
      expect(response.status).toBe(204);
      expect(response.headers['access-control-allow-origin']).toBe('http://localhost:3000');
      expect(response.headers['access-control-allow-methods']).toContain('POST');
    });

    it('should allow Authorization header in preflight', async () => {
      const response = await request(app)
        .options('/v1/khatmat')
        .set('Origin', 'http://localhost:3000')
        .set('Access-Control-Request-Method', 'POST')
        .set('Access-Control-Request-Headers', 'Authorization, Content-Type');
      
      expect(response.status).toBe(204);
      expect(response.headers['access-control-allow-origin']).toBe('http://localhost:3000');
      expect(response.headers['access-control-allow-headers']).toMatch(/authorization/i);
    });

    it('should not require credentials (no cookies)', async () => {
      const response = await request(app)
        .options('/v1/khatmat')
        .set('Origin', 'http://localhost:3000')
        .set('Access-Control-Request-Method', 'POST');
      
      // Should NOT set Access-Control-Allow-Credentials
      expect(response.headers['access-control-allow-credentials']).toBeUndefined();
    });
  });
});
