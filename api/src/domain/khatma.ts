import { ApiError } from "../errors/api-error";
import { Khatma } from "./types";

/**
 * Check if user is organizer (creator only)
 * 
 * Note: members are participants, not organizers
 * 
 * LEGACY COMPATIBILITY:
 * - Checks both normalized (lowercase) and raw createdBy
 * - Historical mixed-case creator emails still recognized
 */
export function isOrganizer(khatma: Khatma, userId: string): boolean {
  return khatma.createdBy === userId || 
         khatma.createdBy.toLowerCase() === userId.toLowerCase();
}

/**
 * Check if user is participant (organizer, participantIds, or guest)
 * 
 * LEGACY COMPATIBILITY:
 * - Checks both normalized (lowercase) and raw values
 * - Historical mixed-case emails (e.g., "User@Test.com") still recognized
 * - No data migration required for existing Khatmat
 */
export function isParticipant(khatma: Khatma, userId: string, uid: string): boolean {
  const normalizedUserId = userId.toLowerCase();
  
  // Creator is always participant (check both normalized and raw for legacy)
  if (khatma.createdBy === userId || khatma.createdBy.toLowerCase() === normalizedUserId) {
    return true;
  }

  // Check participantIds (can include email or UID)
  if (khatma.participantIds) {
    for (const pid of khatma.participantIds) {
      if (pid === userId || pid === uid || 
          (typeof pid === 'string' && pid.toLowerCase() === normalizedUserId)) {
        return true;
      }
    }
  }

  // Check members (legacy mixed-case compatibility)
  if (khatma.members) {
    for (const member of khatma.members) {
      if (member === userId || 
          (typeof member === 'string' && member.toLowerCase() === normalizedUserId)) {
        return true;
      }
    }
  }

  // Check guestParticipants
  if (khatma.guestParticipants) {
    if (userId in khatma.guestParticipants || uid in khatma.guestParticipants) {
      return true;
    }
    // Check lowercase normalized key for legacy
    for (const key of Object.keys(khatma.guestParticipants)) {
      if (key.toLowerCase() === normalizedUserId) {
        return true;
      }
    }
  }

  return false;
}

/**
 * Load Khatma document, throw if not found
 */
export async function loadKhatma(db: FirebaseFirestore.Firestore, khatmaId: string): Promise<Khatma> {
  const doc = await db.collection("khatmat").doc(khatmaId).get();
  
  if (!doc.exists) {
    throw ApiError.notFound("Khatma", khatmaId);
  }

  return {id: doc.id, ...doc.data()} as Khatma;
}

/**
 * Verify Khatma is ready (not initializing)
 */
export function requireReady(khatma: Khatma): void {
  if (khatma.creationState === "initializing") {
    throw ApiError.conflict("Khatma is still initializing");
  }
}
