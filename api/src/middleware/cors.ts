/**
 * CORS Middleware for Multi-Platform Support
 * 
 * iOS/Android native apps: NOT restricted by browser CORS
 * Flutter Web + Future Backoffice: ARE restricted by CORS
 * 
 * Security:
 * - NEVER use Access-Control-Allow-Origin: * for production
 * - credentials: false (using Authorization Bearer, not cookies)
 * - Allowed origins from environment
 */

import cors, { CorsOptions } from 'cors';
import { getEnvironment } from '../config/environment';
import { logger } from '../utils/logger';

export function createCorsMiddleware() {
  const { allowedOrigins } = getEnvironment();

  const corsOptions: CorsOptions = {
    origin: (origin, callback) => {
      // Allow requests with no origin (mobile apps, Postman, curl)
      if (!origin) {
        callback(null, true);
        return;
      }

      // Check if origin is in allowed list
      if (allowedOrigins.includes(origin)) {
        callback(null, true);
      } else {
        // Reject without throwing error
        // CORS library will not set Access-Control-Allow-Origin header
        logger.warn('CORS origin rejected', { origin, allowedOrigins });
        callback(null, false);
      }
    },
    methods: ['GET', 'POST', 'OPTIONS'],
    allowedHeaders: ['Content-Type', 'Authorization', 'X-Request-Id'],
    credentials: false, // Not using cookies, using Bearer tokens
    maxAge: 86400, // 24 hours preflight cache
  };

  return cors(corsOptions);
}
