/**
 * Authentication Middleware Tests
 */

import request from 'supertest';
import express from 'express';
import { requestIdMiddleware } from '../src/middleware/request-id';
import { authMiddleware, AuthenticatedRequest } from '../src/middleware/auth';
import { errorHandler } from '../src/middleware/error-handler';
import { getFirebaseAuth } from '../src/firebase/admin';

// Mock Firebase Admin
jest.mock('../src/firebase/admin');

describe('Auth Middleware', () => {
  let app: express.Application;
  const mockVerifyIdToken = jest.fn();

  beforeAll(() => {
    // Setup mock
    (getFirebaseAuth as jest.Mock).mockReturnValue({
      verifyIdToken: mockVerifyIdToken,
    });
  });

  beforeEach(() => {
    // Create test app
    app = express();
    app.use(requestIdMiddleware);
    app.use(express.json());

    // Protected route
    app.get('/protected', authMiddleware, (req, res) => {
      const authReq = req as AuthenticatedRequest;
      res.json({
        uid: authReq.auth.uid,
        email: authReq.auth.email,
        isAdmin: authReq.auth.isAdmin,
      });
    });

    app.use(errorHandler);

    // Clear mocks
    mockVerifyIdToken.mockClear();
  });

  describe('Missing Authorization', () => {
    it('should return 401 AUTH_REQUIRED', async () => {
      const response = await request(app).get('/protected');
      expect(response.status).toBe(401);
      expect(response.body.error.code).toBe('AUTH_REQUIRED');
    });
  });

  describe('Malformed Authorization', () => {
    it('should return 401 for missing Bearer prefix', async () => {
      const response = await request(app)
        .get('/protected')
        .set('Authorization', 'InvalidToken123');
      
      expect(response.status).toBe(401);
      expect(response.body.error.code).toBe('AUTH_REQUIRED');
    });

    it('should return 401 for empty Bearer token', async () => {
      const response = await request(app)
        .get('/protected')
        .set('Authorization', 'Bearer ');
      
      expect(response.status).toBe(401);
      expect(response.body.error.code).toBe('AUTH_REQUIRED');
    });
  });

  describe('Invalid Token', () => {
    it('should return 401 AUTH_INVALID for expired token', async () => {
      mockVerifyIdToken.mockRejectedValueOnce(new Error('Token expired'));

      const response = await request(app)
        .get('/protected')
        .set('Authorization', 'Bearer expired-token');
      
      expect(response.status).toBe(401);
      expect(response.body.error.code).toBe('AUTH_INVALID');
    });

    it('should return 401 AUTH_INVALID for invalid signature', async () => {
      mockVerifyIdToken.mockRejectedValueOnce(new Error('Invalid signature'));

      const response = await request(app)
        .get('/protected')
        .set('Authorization', 'Bearer invalid-token');
      
      expect(response.status).toBe(401);
      expect(response.body.error.code).toBe('AUTH_INVALID');
    });
  });

  describe('Valid Token', () => {
    it('should attach auth context with email', async () => {
      mockVerifyIdToken.mockResolvedValueOnce({
        uid: 'user123',
        email: 'user@example.com',
        email_verified: true,
        admin: false,
      });

      const response = await request(app)
        .get('/protected')
        .set('Authorization', 'Bearer valid-token');
      
      expect(response.status).toBe(200);
      expect(response.body).toEqual({
        uid: 'user123',
        email: 'user@example.com',
        isAdmin: false,
      });
    });

    it('should attach auth context without email', async () => {
      mockVerifyIdToken.mockResolvedValueOnce({
        uid: 'user456',
        email_verified: false,
        admin: false,
      });

      const response = await request(app)
        .get('/protected')
        .set('Authorization', 'Bearer valid-token');
      
      expect(response.status).toBe(200);
      expect(response.body).toEqual({
        uid: 'user456',
        email: undefined,
        isAdmin: false,
      });
    });

    it('should detect admin custom claim', async () => {
      mockVerifyIdToken.mockResolvedValueOnce({
        uid: 'admin123',
        email: 'admin@example.com',
        email_verified: true,
        admin: true,
      });

      const response = await request(app)
        .get('/protected')
        .set('Authorization', 'Bearer admin-token');
      
      expect(response.status).toBe(200);
      expect(response.body).toEqual({
        uid: 'admin123',
        email: 'admin@example.com',
        isAdmin: true,
      });
    });
  });
});
