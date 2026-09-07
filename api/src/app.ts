/**
 * Express Application Setup
 */

import express from 'express';
import helmet from 'helmet';
import { getEnvironment } from './config/environment';
import { initializeFirebaseAdmin } from './firebase/admin';
import { requestIdMiddleware } from './middleware/request-id';
import { requestLoggerMiddleware } from './middleware/request-logger';
import { createCorsMiddleware } from './middleware/cors';
import { createRateLimitMiddleware } from './middleware/rate-limit';
import { errorHandler, notFoundHandler } from './middleware/error-handler';
import healthRouter from './routes/health';
import khatmatRouter from './routes/khatmat';
import formationsRouter from './routes/formations';

export function createApp(): express.Application {
  const app = express();
  const { bodyLimitBytes } = getEnvironment();

  // Initialize Firebase Admin SDK
  initializeFirebaseAdmin();

  // Security headers
  app.use(helmet());

  // CORS (must be early)
  app.use(createCorsMiddleware());

  // Request ID (must be first middleware to attach ID)
  app.use(requestIdMiddleware);

  // Request logging
  app.use(requestLoggerMiddleware);

  // Body parsing with size limit
  app.use(express.json({ limit: bodyLimitBytes }));
  app.use(express.urlencoded({ extended: true, limit: bodyLimitBytes }));

  // Rate limiting
  app.use(createRateLimitMiddleware());

  // Routes
  app.use(healthRouter);
  app.use(khatmatRouter);
  app.use(formationsRouter);

  // 404 handler (must be after all routes)
  app.use(notFoundHandler);

  // Error handler (must be last)
  app.use(errorHandler);

  return app;
}
