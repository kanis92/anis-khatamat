/**
 * Request ID Tests
 */

import request from 'supertest';
import { createApp } from '../src/app';

describe('Request ID', () => {
  const app = createApp();

  it('should attach X-Request-Id header', async () => {
    const response = await request(app).get('/health');
    
    expect(response.headers['x-request-id']).toBeDefined();
    expect(typeof response.headers['x-request-id']).toBe('string');
    expect(response.headers['x-request-id'].length).toBeGreaterThan(0);
  });

  it('should generate unique request IDs', async () => {
    const response1 = await request(app).get('/health');
    const response2 = await request(app).get('/health');
    
    expect(response1.headers['x-request-id']).not.toBe(response2.headers['x-request-id']);
  });

  it('should include request ID in error responses', async () => {
    const response = await request(app).get('/unknown-route');
    
    expect(response.status).toBe(404);
    expect(response.headers['x-request-id']).toBeDefined();
  });
});
