/**
 * Get Formation Progress
 * Returns user's progress for a specific learning path
 */

import * as admin from 'firebase-admin';
import { AuthContext } from '../middleware/auth';
import { FormationProgress, FormationProgressResponse } from '../domain/formations';

export async function getFormationProgress(
  auth: AuthContext,
  pathId: string
): Promise<FormationProgressResponse | null> {
  const db = admin.firestore();
  const userId = auth.uid;

  const progressRef = db
    .collection('users')
    .doc(userId)
    .collection('formationProgress')
    .doc(pathId);

  const snap = await progressRef.get();

  if (!snap.exists) {
    return null;
  }

  const data = snap.data() as FormationProgress;

  return {
    pathId: data.pathId,
    lastLessonId: data.lastLessonId,
    completedLessonIds: data.completedLessonIds || [],
    lastAccessedAt: data.lastAccessedAt.toDate().toISOString(),
  };
}
