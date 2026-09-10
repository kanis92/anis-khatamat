/**
 * Formation Routes
 * Server-authoritative progress tracking for learning paths
 */

import { Router, Request, Response, NextFunction } from 'express';
import { authMiddleware, AuthenticatedRequest } from '../middleware/auth';
import * as business from '../business';
import { ApiError } from '../errors/api-error';

const router = Router();

/**
 * GET /v1/formations/progress
 * Get all formation progress records for the authenticated user
 */
router.get(
  '/v1/formations/progress',
  authMiddleware,
  async (req: Request, res: Response, next: NextFunction) => {
    try {
      const authReq = req as AuthenticatedRequest;
      const allProgress = await business.getAllFormationProgress(authReq.auth);
      res.json({ data: allProgress });
    } catch (error) {
      next(error);
    }
  }
);

/**
 * GET /v1/formations/:pathId/progress
 * Get user's progress for a learning path
 */
router.get(
  '/v1/formations/:pathId/progress',
  authMiddleware,
  async (req: Request, res: Response, next: NextFunction) => {
    try {
      const authReq = req as AuthenticatedRequest;
      const { pathId } = req.params;

      if (!pathId || typeof pathId !== 'string' || pathId.trim() === '') {
        throw ApiError.invalidArgument('pathId is required');
      }

      const progress = await business.getFormationProgress(
        authReq.auth,
        pathId
      );

      if (!progress) {
        // No progress yet - return 200 with null
        res.json({ data: null });
        return;
      }

      res.json({ data: progress });
    } catch (error) {
      next(error);
    }
  }
);

/**
 * POST /v1/formations/:pathId/lessons/:lessonId/open
 * Record that user opened a lesson
 */
router.post(
  '/v1/formations/:pathId/lessons/:lessonId/open',
  authMiddleware,
  async (req: Request, res: Response, next: NextFunction) => {
    try {
      const authReq = req as AuthenticatedRequest;
      const { pathId, lessonId } = req.params;

      if (!pathId || typeof pathId !== 'string' || pathId.trim() === '') {
        throw ApiError.invalidArgument('pathId is required');
      }

      if (!lessonId || typeof lessonId !== 'string' || lessonId.trim() === '') {
        throw ApiError.invalidArgument('lessonId is required');
      }

      await business.openFormationLesson(authReq.auth, pathId, lessonId);

      res.status(200).json({ data: { success: true } });
    } catch (error) {
      next(error);
    }
  }
);

/**
 * POST /v1/formations/:pathId/lessons/:lessonId/complete
 * Mark a lesson as completed
 */
router.post(
  '/v1/formations/:pathId/lessons/:lessonId/complete',
  authMiddleware,
  async (req: Request, res: Response, next: NextFunction) => {
    try {
      const authReq = req as AuthenticatedRequest;
      const { pathId, lessonId } = req.params;

      if (!pathId || typeof pathId !== 'string' || pathId.trim() === '') {
        throw ApiError.invalidArgument('pathId is required');
      }

      if (!lessonId || typeof lessonId !== 'string' || lessonId.trim() === '') {
        throw ApiError.invalidArgument('lessonId is required');
      }

      await business.completeFormationLesson(authReq.auth, pathId, lessonId);

      res.status(200).json({ data: { success: true } });
    } catch (error) {
      next(error);
    }
  }
);

export default router;
