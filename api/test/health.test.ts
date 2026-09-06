/**
 * Health Endpoint Tests
 */

import request from 'supertest';
import { createApp } from '../src/app';

describe('GET /health', () => {
  const app = createApp();

  it('should return 200 OK', async () => {
    const response = await request(app).get('/health');
    expect(response.status).toBe(200);
  });

  it('should return correct JSON structure', async () => {
    const response = await request(app).get('/health');
    expect(response.body).toEqual({
      status: 'ok',
      service: 'anis-api',
    });
  });

  it('should include X-Request-Id header', async () => {
    const response = await request(app).get('/health');
    expect(response.headers['x-request-id']).toBeDefined();
    expect(typeof response.headers['x-request-id']).toBe('string');
  });
});
