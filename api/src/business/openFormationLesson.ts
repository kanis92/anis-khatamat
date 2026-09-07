/**
 * Open Formation Lesson
 * Records that a user opened a specific lesson
 */

import * as admin from 'firebase-admin';
import { AuthContext } from '../middleware/auth';
import { ApiError } from '../errors/api-error';

export async function openFormationLesson(
  auth: AuthContext,
  pathId: string,
  lessonId: string
): Promise<void> {
  const db = admin.firestore();
  const userId = auth.uid;

  // Validate path exists (basic check)
  const pathRef = db.collection('courses').doc(pathId);
  const pathSnap = await pathRef.get();
  
  if (!pathSnap.exists) {
    throw ApiError.notFound(`Learning path '${pathId}' not found`);
  }

  // Validate lesson belongs to path
  const lessonRef = pathRef.collection('lessons').doc(lessonId);
  const lessonSnap = await lessonRef.get();
  
  if (!lessonSnap.exists) {
    throw ApiError.notFound(`Lesson '${lessonId}' not found in path '${pathId}'`);
  }

  const lessonData = lessonSnap.data();
  if (lessonData?.courseId !== pathId) {
    throw ApiError.invalidArgument(
      `Lesson '${lessonId}' does not belong to path '${pathId}'`
    );
  }

  // Update progress
  const progressRef = db
    .collection('users')
    .doc(userId)
    .collection('formationProgress')
    .doc(pathId);

  await progressRef.set(
    {
      userId,
      pathId,
      lastLessonId: lessonId,
      lastAccessedAt: admin.firestore.FieldValue.serverTimestamp(),
    },
    { merge: true }
  );
}
