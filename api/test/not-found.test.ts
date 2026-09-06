/**
 * 404 Not Found Tests
 */

import request from 'supertest';
import { createApp } from '../src/app';

describe('404 Not Found', () => {
  const app = createApp();

  it('should return 404 for unknown route', async () => {
    const response = await request(app).get('/unknown-route');
    expect(response.status).toBe(404);
  });

  it('should return stable error structure', async () => {
    const response = await request(app).get('/unknown-route');
    expect(response.body).toHaveProperty('error');
    expect(response.body.error).toHaveProperty('code', 'NOT_FOUND');
    expect(response.body.error).toHaveProperty('message');
    expect(typeof response.body.error.message).toBe('string');
  });

  it('should not expose stack trace', async () => {
    const response = await request(app).get('/unknown-route');
    expect(response.body.error).not.toHaveProperty('stack');
  });
});
