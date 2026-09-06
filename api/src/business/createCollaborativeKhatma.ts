/**
 * Create Collaborative Khatma Business Logic
 * Extracted from Firebase Functions, adapted for REST API
 */

import * as admin from 'firebase-admin';
import { AuthContext } from '../middleware/auth';
import { ApiError } from '../errors/api-error';
import {
  CreateKhatmaRequest,
  CreateKhatmaResponse,
} from '../domain/types';
import { getCanonicalUserId } from '../domain/auth';
import { createCanonicalReservation, DEFINITION_ID, TOTAL_HIZB } from '../domain/canonical';
import { getFirestore } from '../firebase/admin';
import { logger } from '../utils/logger';

/**
 * Create collaborative Khatma with 60 canonical Hizb
 * Server-authoritative: allocates ID, creates parent, initializes reservations
 */
export async function createCollaborativeKhatma(
  auth: AuthContext,
  data: CreateKhatmaRequest
): Promise<CreateKhatmaResponse> {
  const db = getFirestore();
  const userId = getCanonicalUserId(auth);

  // Validate input
  if (!data.title || data.title.trim().length === 0) {
    throw ApiError.invalidArgument("Title is required");
  }

  const hizbDefinitionId = data.hizbDefinitionId || DEFINITION_ID;
  if (hizbDefinitionId !== DEFINITION_ID) {
    throw ApiError.invalidArgument(
      `Unsupported hizbDefinitionId: ${hizbDefinitionId}`
    );
  }

  // Allocate Khatma ID
  const khatmaRef = db.collection("khatmat").doc();
  const khatmaId = khatmaRef.id;

  try {
    // Use batch for atomic creation
    const batch = db.batch();

    // Prepare invited members (unique, excluding creator)
    const invited = (data.members || [])
      .map((m) => m.trim())
      .filter((m) => m.length > 0 && m !== userId)
      .filter((m, i, arr) => arr.indexOf(m) === i); // unique

    // Create parent document (initializing state)
    const parentData: Record<string, unknown> = {
      title: data.title.trim(),
      createdBy: userId,
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
      isGroup: data.isGroup,
      isPublic: data.isPublic,
      reservationMode: true,
      reservationSchemaVersion: 2,
      completedHizbCount: 0,
      participantIds: [userId, ...invited],
      members: invited,
      guestParticipants: {},
      creationState: "initializing",
      hizbDefinitionId,
    };

    if (data.objectives && data.objectives.trim().length > 0) {
      parentData.objectives = data.objectives.trim();
    }

    batch.set(khatmaRef, parentData);

    // Create all 60 canonical Hizb reservations
    for (let i = 1; i <= TOTAL_HIZB; i++) {
      const reservation = createCanonicalReservation(i, hizbDefinitionId);
      const hizbRef = khatmaRef.collection("hizb_reservations").doc(String(i));
      batch.set(hizbRef, reservation);
    }

    // Mark parent as ready
    batch.update(khatmaRef, { creationState: "ready" });

    // Commit all writes atomically
    await batch.commit();

    return { khatmaId };
  } catch (error) {
    logger.error("createCollaborativeKhatma failed", {
      khatmaId,
      error: error instanceof Error ? error.message : "Unknown error",
    });
    throw ApiError.internal("Failed to create Khatma");
  }
}
