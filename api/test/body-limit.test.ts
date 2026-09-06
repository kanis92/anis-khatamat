/**
 * Body Size Limit Tests
 */

import request from 'supertest';
import express from 'express';
import { requestIdMiddleware } from '../src/middleware/request-id';
import { errorHandler } from '../src/middleware/error-handler';

describe('Body Size Limit', () => {
  let app: express.Application;

  beforeEach(() => {
    // Create minimal app with body limit
    app = express();
    app.use(requestIdMiddleware);
    app.use(express.json({ limit: '1kb' })); // 1KB limit for test

    app.post('/test', (req, res) => {
      res.json({ received: req.body });
    });

    // Error handler for body parser errors
    app.use((err: Error, _req: express.Request, res: express.Response, next: express.NextFunction) => {
      if (err.message.includes('request entity too large')) {
        res.status(413).json({ error: { code: 'PAYLOAD_TOO_LARGE', message: 'Request entity too large' } });
      } else {
        next(err);
      }
    });

    app.use(errorHandler);
  });

  it('should accept payload within limit', async () => {
    const smallPayload = { data: 'x'.repeat(100) }; // ~100 bytes
    
    const response = await request(app)
      .post('/test')
      .send(smallPayload);
    
    expect(response.status).toBe(200);
  });

  it('should reject payload exceeding limit', async () => {
    const largePayload = { data: 'x'.repeat(2000) }; // ~2KB
    
    const response = await request(app)
      .post('/test')
      .send(largePayload);
    
    expect(response.status).toBe(413); // Payload Too Large
  });
});
