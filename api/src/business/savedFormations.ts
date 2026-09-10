/**
 * Saved Formation Items Business Logic
 */

import * as admin from 'firebase-admin';
import { AuthContext } from '../middleware/auth';
import { ApiError } from '../errors/api-error';
import {
  SavedFormationItem,
  SavedFormationItemResponse,
  SavedItemType,
} from '../domain/saved-formations';

function getDb() {
  return admin.firestore();
}

function savedItemToResponse(
  item: SavedFormationItem
): SavedFormationItemResponse {
  return {
    id: item.id,
    type: item.type,
    targetId: item.targetId,
    courseId: item.courseId,
    savedAt: item.savedAt.toDate().toISOString(),
  };
}

/**
 * Get all saved items for the authenticated user
 */
export async function getAllSavedFormations(
  auth: AuthContext
): Promise<SavedFormationItemResponse[]> {
  const db = getDb();
  const snapshot = await db
    .collection('users')
    .doc(auth.uid)
    .collection('savedFormations')
    .orderBy('savedAt', 'desc')
    .get();

  if (snapshot.empty) {
    return [];
  }

  return snapshot.docs.map((doc) => {
    const data = doc.data() as Omit<SavedFormationItem, 'id'>;
    return savedItemToResponse({
      id: doc.id,
      ...data,
    });
  });
}

/**
 * Save a formation item (idempotent)
 */
export async function saveFormationItem(
  auth: AuthContext,
  type: SavedItemType,
  targetId: string,
  courseId: string | null
): Promise<SavedFormationItemResponse> {
  if (!targetId || typeof targetId !== 'string' || targetId.trim() === '') {
    throw ApiError.invalidArgument('targetId is required');
  }

  if (type === 'lesson' && !courseId) {
    throw ApiError.invalidArgument('courseId is required for lesson type');
  }

  if (type === 'course' && courseId) {
    throw ApiError.invalidArgument('courseId must be null for course type');
  }

  const db = getDb();
  const collection = db
    .collection('users')
    .doc(auth.uid)
    .collection('savedFormations');

  // Check if already saved (prevent duplicates)
  const existing = await collection
    .where('type', '==', type)
    .where('targetId', '==', targetId)
    .limit(1)
    .get();

  if (!existing.empty) {
    // Already saved - idempotent
    const doc = existing.docs[0];
    const data = doc.data() as Omit<SavedFormationItem, 'id'>;
    return savedItemToResponse({
      id: doc.id,
      ...data,
    });
  }

  // Create new saved item
  const now = admin.firestore.Timestamp.now();
  const newDoc = await collection.add({
    userId: auth.uid,
    type,
    targetId,
    courseId,
    savedAt: now,
  });

  return {
    id: newDoc.id,
    type,
    targetId,
    courseId,
    savedAt: now.toDate().toISOString(),
  };
}

/**
 * Remove a saved formation item (idempotent)
 */
export async function removeSavedFormation(
  auth: AuthContext,
  savedItemId: string
): Promise<void> {
  if (
    !savedItemId ||
    typeof savedItemId !== 'string' ||
    savedItemId.trim() === ''
  ) {
    throw ApiError.invalidArgument('savedItemId is required');
  }

  const db = getDb();
  const docRef = db
    .collection('users')
    .doc(auth.uid)
    .collection('savedFormations')
    .doc(savedItemId);

  const doc = await docRef.get();

  if (!doc.exists) {
    // Already removed or never existed in this user's collection - idempotent
    return;
  }

  // Path-based isolation ensures we can only access our own items
  await docRef.delete();
}

/**
 * Remove by type and targetId (convenience for UI toggle)
 */
export async function removeSavedFormationByTarget(
  auth: AuthContext,
  type: SavedItemType,
  targetId: string
): Promise<void> {
  if (!targetId || typeof targetId !== 'string' || targetId.trim() === '') {
    throw ApiError.invalidArgument('targetId is required');
  }

  const db = getDb();
  const snapshot = await db
    .collection('users')
    .doc(auth.uid)
    .collection('savedFormations')
    .where('type', '==', type)
    .where('targetId', '==', targetId)
    .limit(1)
    .get();

  if (snapshot.empty) {
    // Already absent - idempotent
    return;
  }

  await snapshot.docs[0].ref.delete();
}
