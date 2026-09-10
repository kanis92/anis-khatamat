/**
 * Get All Formation Progress
 * Returns all formation progress records for the authenticated user
 */

import * as admin from 'firebase-admin';
import { AuthContext } from '../middleware/auth';
import { FormationProgress, FormationProgressResponse } from '../domain/formations';

export async function getAllFormationProgress(
  auth: AuthContext
): Promise<FormationProgressResponse[]> {
  const db = admin.firestore();
  const userId = auth.uid;

  const progressCollectionRef = db
    .collection('users')
    .doc(userId)
    .collection('formationProgress');

  const snap = await progressCollectionRef.get();

  if (snap.empty) {
    return [];
  }

  const progressList: FormationProgressResponse[] = snap.docs.map((doc) => {
    const data = doc.data() as FormationProgress;
    return {
      pathId: data.pathId,
      lastLessonId: data.lastLessonId,
      completedLessonIds: data.completedLessonIds || [],
      lastAccessedAt: data.lastAccessedAt.toDate().toISOString(),
    };
  });

  return progressList;
}
