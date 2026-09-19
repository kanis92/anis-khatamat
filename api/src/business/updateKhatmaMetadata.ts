/**
 * Update Khatma metadata (title, objectives) — organizer only
 */

import * as admin from 'firebase-admin';
import { AuthContext } from '../middleware/auth';
import { ApiError } from '../errors/api-error';
import {
  UpdateKhatmaMetadataRequest,
  UpdateKhatmaMetadataResponse,
} from '../domain/types';
import { getCanonicalUserId } from '../domain/auth';
import { getFirestore } from '../firebase/admin';
import { isOrganizer, loadKhatma, requireReady } from '../domain/khatma';

const MAX_TITLE_LENGTH = 200;

export async function updateKhatmaMetadata(
  auth: AuthContext,
  khatmaId: string,
  data: UpdateKhatmaMetadataRequest
): Promise<UpdateKhatmaMetadataResponse> {
  const db = getFirestore();
  const userId = getCanonicalUserId(auth);

  const hasTitle = 'title' in data;
  const hasObjectives = 'objectives' in data;
  if (!hasTitle && !hasObjectives) {
    throw ApiError.invalidArgument(
      'At least one of title or objectives must be provided'
    );
  }

  const khatma = await loadKhatma(db, khatmaId);
  requireReady(khatma);

  if (!isOrganizer(khatma, userId, auth.uid)) {
    throw ApiError.forbidden('Only the Khatma creator can edit metadata');
  }

  const updates: Record<string, unknown> = {};

  if (hasTitle) {
    if (typeof data.title !== 'string') {
      throw ApiError.invalidArgument('title must be a string');
    }
    const trimmed = data.title.trim();
    if (trimmed.length === 0) {
      throw ApiError.invalidArgument('Title is required');
    }
    if (trimmed.length > MAX_TITLE_LENGTH) {
      throw ApiError.invalidArgument(
        `Title must be at most ${MAX_TITLE_LENGTH} characters`
      );
    }
    updates.title = trimmed;
  }

  if (hasObjectives) {
    if (data.objectives !== null && typeof data.objectives !== 'string') {
      throw ApiError.invalidArgument('objectives must be a string or null');
    }
    if (
      data.objectives === null ||
      (typeof data.objectives === 'string' && data.objectives.trim().length === 0)
    ) {
      updates.objectives = admin.firestore.FieldValue.delete();
    } else {
      updates.objectives = data.objectives!.trim();
    }
  }

  await db.collection('khatmat').doc(khatmaId).update(updates);

  const updated = await loadKhatma(db, khatmaId);
  return {
    khatmaId,
    success: true,
    title: updated.title,
    objectives: updated.objectives ?? null,
  };
}
