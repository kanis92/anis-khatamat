/**
 * Error Contract Tests
 */

import request from 'supertest';
import express from 'express';
import { requestIdMiddleware } from '../src/middleware/request-id';
import { errorHandler } from '../src/middleware/error-handler';
import { ApiError } from '../src/errors/api-error';

describe('Error Contract', () => {
  let app: express.Application;

  beforeEach(() => {
    app = express();
    app.use(requestIdMiddleware);
    app.use(express.json());

    // Test routes
    app.get('/api-error', (_req, _res, next) => {
      next(ApiError.invalidArgument('Test error', { field: 'testField' }));
    });

    app.get('/unknown-error', () => {
      throw new Error('Unexpected error');
    });

    app.use(errorHandler);
  });

  describe('ApiError', () => {
    it('should return stable error structure', async () => {
      const response = await request(app).get('/api-error');
      
      expect(response.status).toBe(400);
      expect(response.body).toHaveProperty('error');
      expect(response.body.error).toEqual({
        code: 'INVALID_ARGUMENT',
        message: 'Test error',
        details: { field: 'testField' },
      });
    });

    it('should not expose stack trace', async () => {
      const response = await request(app).get('/api-error');
      
      expect(response.body.error).not.toHaveProperty('stack');
    });
  });

  describe('Unknown Error', () => {
    it('should sanitize unexpected errors', async () => {
      const response = await request(app).get('/unknown-error');
      
      expect(response.status).toBe(500);
      expect(response.body).toEqual({
        error: {
          code: 'INTERNAL',
          message: 'Internal server error',
        },
      });
    });

    it('should not expose internal error details', async () => {
      const response = await request(app).get('/unknown-error');
      
      expect(response.body.error.message).not.toContain('Unexpected error');
      expect(response.body.error).not.toHaveProperty('stack');
    });
  });
});
