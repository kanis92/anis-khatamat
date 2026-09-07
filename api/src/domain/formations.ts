/**
 * Formation Progress Domain Types
 * Server-authoritative progress tracking for learning paths
 */

export interface FormationProgress {
  userId: string;
  pathId: string;
  lastLessonId: string | null;
  completedLessonIds: string[];
  lastAccessedAt: FirebaseFirestore.Timestamp;
}

export interface OpenLessonRequest {
  // pathId and lessonId come from route params
  // No body needed - server derives user from auth token
}

export interface CompleteLessonRequest {
  // pathId and lessonId come from route params
  // No body needed - server derives user from auth token
}

export interface FormationProgressResponse {
  pathId: string;
  lastLessonId: string | null;
  completedLessonIds: string[];
  lastAccessedAt: string; // ISO 8601
}
