/**
 * Firebase Authentication Middleware
 * 
 * Verifies Firebase ID tokens and attaches trusted auth context to request
 * NEVER trust uid/email/admin from request body - only from verified token
 */

import { Request, Response, NextFunction } from 'express';
import { getFirebaseAuth } from '../firebase/admin';
import { ApiError } from '../errors/api-error';
import { logger } from '../utils/logger';
import { RequestWithId } from './request-id';

export interface AuthContext {
  uid: string;
  email?: string;
  emailVerified?: boolean;
  isAdmin: boolean;
  customClaims?: Record<string, unknown>;
}

export interface AuthenticatedRequest extends RequestWithId {
  auth: AuthContext;
}

/**
 * Extract Bearer token from Authorization header
 */
function extractBearerToken(authHeader: string | undefined): string | null {
  if (!authHeader) {
    return null;
  }

  const parts = authHeader.split(' ');
  if (parts.length !== 2 || parts[0] !== 'Bearer') {
    return null;
  }

  return parts[1];
}

/**
 * Auth middleware - verifies Firebase ID token
 */
export async function authMiddleware(
  req: Request,
  _res: Response,
  next: NextFunction
): Promise<void> {
  const requestId = (req as RequestWithId).requestId;

  try {
    const token = extractBearerToken(req.headers.authorization);

    if (!token) {
      logger.warn('Missing or malformed Authorization header', { requestId });
      throw ApiError.authRequired('Missing Authorization header');
    }

    // Verify token with Firebase Admin SDK
    const decodedToken = await getFirebaseAuth().verifyIdToken(token);

    // Attach trusted auth context to request
    const authContext: AuthContext = {
      uid: decodedToken.uid,
      email: decodedToken.email,
      emailVerified: decodedToken.email_verified,
      isAdmin: decodedToken.admin === true,
      customClaims: decodedToken,
    };

    (req as AuthenticatedRequest).auth = authContext;

    logger.debug('Token verified', {
      requestId,
      uid: authContext.uid,
      email: authContext.email,
      isAdmin: authContext.isAdmin,
    });

    next();
  } catch (error) {
    // Firebase SDK throws specific errors for invalid/expired tokens
    if (error instanceof ApiError) {
      next(error);
      return;
    }

    logger.warn('Token verification failed', {
      requestId,
      error: error instanceof Error ? error.message : 'Unknown error',
    });

    next(ApiError.authInvalid('Invalid or expired authentication token'));
  }
}

/**
 * Get canonical user ID from auth context
 * Prefer email, fallback to UID
 */
export function getCanonicalUserId(auth: AuthContext): string {
  return auth.email?.trim() || auth.uid;
}
