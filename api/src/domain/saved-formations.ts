/**
 * Saved Formation Items Domain
 * Private user bookmarks for learning content
 */

import * as admin from 'firebase-admin';

export type SavedItemType = 'course' | 'lesson';

export interface SavedFormationItem {
  id: string;
  userId: string;
  type: SavedItemType;
  targetId: string;
  courseId: string | null; // Required for lessons, null for courses
  savedAt: admin.firestore.Timestamp;
}

export interface SavedFormationItemResponse {
  id: string;
  type: SavedItemType;
  targetId: string;
  courseId: string | null;
  savedAt: string; // ISO 8601
}
