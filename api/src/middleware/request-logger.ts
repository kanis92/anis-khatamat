/**
 * Request logging middleware
 * Log request/response details without exposing sensitive data
 */

import { Request, Response, NextFunction } from 'express';
import { logger, sanitizeHeaders } from '../utils/logger';
import { RequestWithId } from './request-id';

export function requestLoggerMiddleware(req: Request, res: Response, next: NextFunction): void {
  const start = Date.now();
  const requestId = (req as RequestWithId).requestId;

  // Log incoming request
  logger.info('Incoming request', {
    requestId,
    method: req.method,
    path: req.path,
    query: req.query,
    headers: sanitizeHeaders(req.headers as Record<string, unknown>),
  });

  // Capture response finish event
  res.on('finish', () => {
    const duration = Date.now() - start;
    logger.info('Request completed', {
      requestId,
      method: req.method,
      path: req.path,
      statusCode: res.statusCode,
      durationMs: duration,
    });
  });

  next();
}
