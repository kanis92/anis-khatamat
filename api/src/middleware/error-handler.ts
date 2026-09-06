/**
 * Centralized error handling middleware
 * 
 * Security:
 * - Never expose stack traces to clients
 * - Never expose internal Firebase exception strings
 * - Never expose service-account details
 */

import { Request, Response, NextFunction } from 'express';
import { ApiError, ErrorCode } from '../errors/api-error';
import { logger } from '../utils/logger';
import { RequestWithId } from './request-id';

export function errorHandler(
  error: Error,
  req: Request,
  res: Response,
  _next: NextFunction
): void {
  const requestId = (req as RequestWithId).requestId;

  // Known API errors
  if (error instanceof ApiError) {
    logger.warn('API error', {
      requestId,
      code: error.code,
      statusCode: error.statusCode,
      message: error.message,
    });

    res.status(error.statusCode).json(error.toJSON());
    return;
  }

  // Handle body-parser errors (malformed JSON, etc.)
  if (error instanceof SyntaxError && 'body' in error) {
    logger.warn('Malformed request body', {
      requestId,
      error: error.message,
    });

    const malformedError = new ApiError(
      400,
      ErrorCode.INVALID_ARGUMENT,
      'Malformed request body'
    );

    res.status(400).json(malformedError.toJSON());
    return;
  }

  // Unknown errors - sanitize before sending
  logger.error('Unexpected error', {
    requestId,
    error: error.message,
    stack: error.stack, // Only logged server-side
  });

  // Never expose internal error details to client
  const sanitizedError = new ApiError(
    500,
    ErrorCode.INTERNAL,
    'Internal server error'
  );

  res.status(500).json(sanitizedError.toJSON());
}

/**
 * 404 handler for unknown routes
 */
export function notFoundHandler(req: Request, res: Response): void {
  const requestId = (req as RequestWithId).requestId;

  logger.warn('Route not found', {
    requestId,
    method: req.method,
    path: req.path,
  });

  const error = ApiError.notFound('Route', req.path);
  res.status(404).json(error.toJSON());
}
