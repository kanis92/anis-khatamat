/**
 * Rate Limiting Middleware
 * 
 * Basic rate limiting to prevent abuse
 * Configurable via environment variables
 */

import rateLimit from 'express-rate-limit';
import { getEnvironment } from '../config/environment';

export function createRateLimitMiddleware() {
  const { rateLimitWindowMs, rateLimitMaxRequests, nodeEnv } = getEnvironment();

  // In test mode, use very high limits to avoid rate limiting during E2E tests
  const windowMs = nodeEnv === 'test' ? 60000 : rateLimitWindowMs;
  const max = nodeEnv === 'test' ? 10000 : rateLimitMaxRequests;

  return rateLimit({
    windowMs,
    max,
    standardHeaders: true, // Return rate limit info in `RateLimit-*` headers
    legacyHeaders: false, // Disable `X-RateLimit-*` headers
    message: {
      error: {
        code: 'RATE_LIMITED',
        message: 'Too many requests, please try again later',
      },
    },
  });
}
