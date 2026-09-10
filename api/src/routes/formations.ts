/**
 * Formation Routes
 * Server-authoritative progress tracking and saved items for learning paths
 */

import { Router, Request, Response, NextFunction } from 'express';
import { authMiddleware, AuthenticatedRequest } from '../middleware/auth';
import * as business from '../business';
import { ApiError } from '../errors/api-error';
import { SavedItemType } from '../domain/saved-formations';

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

// ─── Saved Formation Items ───────────────────────────────────────────────────

/**
 * GET /v1/formations/saved
 * Get all saved formation items for the authenticated user
 */
router.get(
  '/v1/formations/saved',
  authMiddleware,
  async (req: Request, res: Response, next: NextFunction) => {
    try {
      const authReq = req as AuthenticatedRequest;
      const savedItems = await business.getAllSavedFormations(authReq.auth);
      res.json({ data: savedItems });
    } catch (error) {
      next(error);
    }
  }
);

/**
 * POST /v1/formations/saved
 * Save a formation item (course or lesson)
 */
router.post(
  '/v1/formations/saved',
  authMiddleware,
  async (req: Request, res: Response, next: NextFunction) => {
    try {
      const authReq = req as AuthenticatedRequest;
      const { type, targetId, courseId } = req.body;

      if (!type || !['course', 'lesson'].includes(type)) {
        throw ApiError.invalidArgument('type must be "course" or "lesson"');
      }

      const savedItem = await business.saveFormationItem(
        authReq.auth,
        type as SavedItemType,
        targetId,
        courseId || null
      );

      res.status(200).json({ data: savedItem });
    } catch (error) {
      next(error);
    }
  }
);

/**
 * DELETE /v1/formations/saved/:savedItemId
 * Remove a saved formation item by ID
 */
router.delete(
  '/v1/formations/saved/:savedItemId',
  authMiddleware,
  async (req: Request, res: Response, next: NextFunction) => {
    try {
      const authReq = req as AuthenticatedRequest;
      const { savedItemId } = req.params;

      await business.removeSavedFormation(authReq.auth, savedItemId);

      res.status(200).json({ data: { success: true } });
    } catch (error) {
      next(error);
    }
  }
);

/**
 * DELETE /v1/formations/saved-target
 * Remove a saved formation item by type and targetId (convenience for UI toggle)
 */
router.delete(
  '/v1/formations/saved-target',
  authMiddleware,
  async (req: Request, res: Response, next: NextFunction) => {
    try {
      const authReq = req as AuthenticatedRequest;
      const { type, targetId } = req.body;

      if (!type || !['course', 'lesson'].includes(type)) {
        throw ApiError.invalidArgument('type must be "course" or "lesson"');
      }

      await business.removeSavedFormationByTarget(
        authReq.auth,
        type as SavedItemType,
        targetId
      );

      res.status(200).json({ data: { success: true } });
    } catch (error) {
      next(error);
    }
  }
);

export default router;
