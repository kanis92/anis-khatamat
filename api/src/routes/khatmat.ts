/**
 * Khatma Routes
 * Maps HTTP requests to business logic
 */

import { Router, Request, Response, NextFunction } from 'express';
import { authMiddleware, AuthenticatedRequest } from '../middleware/auth';
import * as business from '../business';
import {
  CreateKhatmaRequest,
  UpdateKhatmaMetadataRequest,
  ReserveHizbRequest,
  AssignHizbToParticipantRequest,
  ReleaseHizbRequest,
  CompleteHizbRequest,
} from '../domain/types';
import { ApiError } from '../errors/api-error';

const router = Router();

const METADATA_FORBIDDEN_FIELDS = [
  'id',
  'createdBy',
  'creatorUid',
  'creationState',
  'completedHizbCount',
  'participantIds',
  'members',
  'isGroup',
  'isPublic',
  'reservationMode',
  'hizbDefinitionId',
];

async function handleUpdateKhatmaMetadata(
  req: Request,
  res: Response,
  next: NextFunction
): Promise<void> {
  try {
    const authReq = req as AuthenticatedRequest;
    for (const field of METADATA_FORBIDDEN_FIELDS) {
      if (field in req.body) {
        throw ApiError.invalidArgument(
          `Field '${field}' cannot be provided by client`
        );
      }
    }

    const data: UpdateKhatmaMetadataRequest = req.body;
    const result = await business.updateKhatmaMetadata(
      authReq.auth,
      req.params.khatmaId,
      data
    );
    res.json({ data: result });
  } catch (error) {
    next(error);
  }
}

/**
 * POST /v1/khatmat
 * Create a new collaborative Khatma
 */
router.post(
  '/v1/khatmat',
  authMiddleware,
  async (req: Request, res: Response, next: NextFunction) => {
    try {
      const authReq = req as AuthenticatedRequest;
      const data: CreateKhatmaRequest = req.body;

      // Validate that client is not sending trusted fields
      const forbidden = ['id', 'createdBy', 'creatorUid', 'creationState', 'completedHizbCount'];
      for (const field of forbidden) {
        if (field in data) {
          throw ApiError.invalidArgument(
            `Field '${field}' cannot be provided by client`
          );
        }
      }

      const result = await business.createCollaborativeKhatma(authReq.auth, data);
      res.status(201).json({ data: result });
    } catch (error) {
      next(error);
    }
  }
);

/**
 * POST /v1/khatmat/:khatmaId/metadata
 * Update title and/or objectives (creator only) — preferred (same as other mutations)
 */
router.post(
  '/v1/khatmat/:khatmaId/metadata',
  authMiddleware,
  handleUpdateKhatmaMetadata
);

/**
 * PATCH /v1/khatmat/:khatmaId
 * Update title and/or objectives (creator only)
 */
router.patch(
  '/v1/khatmat/:khatmaId',
  authMiddleware,
  handleUpdateKhatmaMetadata
);

/**
 * POST /v1/khatmat/:khatmaId/hizb/:hizbNumber/reserve
 * Reserve a Hizb for self, offline, or participant
 */
router.post(
  '/v1/khatmat/:khatmaId/hizb/:hizbNumber/reserve',
  authMiddleware,
  async (req: Request, res: Response, next: NextFunction) => {
    try {
      const authReq = req as AuthenticatedRequest;
      const hizbNumber = parseInt(req.params.hizbNumber, 10);

      if (isNaN(hizbNumber)) {
        throw ApiError.invalidArgument("hizbNumber must be an integer");
      }

      // Validate that client is not sending trusted fields
      const forbidden = [
        'reservedBy',
        'assigneeUserId',
        'assignedByUserId',
        'completedBy',
        'completedAt',
      ];
      for (const field of forbidden) {
        if (field in req.body) {
          throw ApiError.invalidArgument(
            `Field '${field}' cannot be provided by client`
          );
        }
      }

      const data: ReserveHizbRequest = {
        khatmaId: req.params.khatmaId,
        hizbNumber,
        ...req.body,
      };

      const result = await business.reserveHizb(authReq.auth, data);
      res.json(result);
    } catch (error) {
      next(error);
    }
  }
);

/**
 * POST /v1/khatmat/:khatmaId/hizb/:hizbNumber/assign
 * Assign a Hizb to a participant (organizer only)
 */
router.post(
  '/v1/khatmat/:khatmaId/hizb/:hizbNumber/assign',
  authMiddleware,
  async (req: Request, res: Response, next: NextFunction) => {
    try {
      const authReq = req as AuthenticatedRequest;
      const hizbNumber = parseInt(req.params.hizbNumber, 10);

      if (isNaN(hizbNumber)) {
        throw ApiError.invalidArgument("hizbNumber must be an integer");
      }

      const data: AssignHizbToParticipantRequest = {
        khatmaId: req.params.khatmaId,
        hizbNumber,
        participantUserId: req.body.participantUserId,
      };

      const result = await business.assignHizbToParticipant(authReq.auth, data);
      res.json(result);
    } catch (error) {
      next(error);
    }
  }
);

/**
 * POST /v1/khatmat/:khatmaId/hizb/:hizbNumber/release
 * Release a reserved Hizb
 */
router.post(
  '/v1/khatmat/:khatmaId/hizb/:hizbNumber/release',
  authMiddleware,
  async (req: Request, res: Response, next: NextFunction) => {
    try {
      const authReq = req as AuthenticatedRequest;
      const hizbNumber = parseInt(req.params.hizbNumber, 10);

      if (isNaN(hizbNumber)) {
        throw ApiError.invalidArgument("hizbNumber must be an integer");
      }

      const data: ReleaseHizbRequest = {
        khatmaId: req.params.khatmaId,
        hizbNumber,
      };

      const result = await business.releaseHizb(authReq.auth, data);
      res.json(result);
    } catch (error) {
      next(error);
    }
  }
);

/**
 * POST /v1/khatmat/:khatmaId/hizb/:hizbNumber/complete
 * Complete a reserved Hizb
 */
router.post(
  '/v1/khatmat/:khatmaId/hizb/:hizbNumber/complete',
  authMiddleware,
  async (req: Request, res: Response, next: NextFunction) => {
    try {
      const authReq = req as AuthenticatedRequest;
      const hizbNumber = parseInt(req.params.hizbNumber, 10);

      if (isNaN(hizbNumber)) {
        throw ApiError.invalidArgument("hizbNumber must be an integer");
      }

      // Reject client-provided trusted fields
      const forbidden = ['completedBy', 'completedAt'];
      for (const field of forbidden) {
        if (field in req.body) {
          throw ApiError.invalidArgument(`${field} cannot be provided by client`);
        }
      }

      const data: CompleteHizbRequest = {
        khatmaId: req.params.khatmaId,
        hizbNumber,
      };

      const result = await business.completeHizb(authReq.auth, data);
      res.json(result);
    } catch (error) {
      next(error);
    }
  }
);

export default router;
