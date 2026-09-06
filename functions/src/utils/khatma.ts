import * as admin from "firebase-admin";
import * as functions from "firebase-functions/v2";
import {ErrorCode, Khatma} from "../types";

/**
 * Check if user is organizer (creator or explicit member)
 */
export function isOrganizer(khatma: Khatma, userId: string): boolean {
  if (khatma.createdBy === userId) {
    return true;
  }
  if (khatma.members && khatma.members.includes(userId)) {
    return true;
  }
  return false;
}

/**
 * Check if user is participant (organizer, participantIds, or guest)
 */
export function isParticipant(khatma: Khatma, userId: string, uid: string): boolean {
  // Creator is always participant
  if (khatma.createdBy === userId) {
    return true;
  }

  // Check participantIds (can include email or UID)
  if (khatma.participantIds && 
      (khatma.participantIds.includes(userId) || khatma.participantIds.includes(uid))) {
    return true;
  }

  // Check members
  if (khatma.members && khatma.members.includes(userId)) {
    return true;
  }

  // Check guestParticipants
  if (khatma.guestParticipants && 
      (userId in khatma.guestParticipants || uid in khatma.guestParticipants)) {
    return true;
  }

  return false;
}

/**
 * Load Khatma document, throw if not found
 */
export async function loadKhatma(db: admin.firestore.Firestore, khatmaId: string): Promise<Khatma> {
  const doc = await db.collection("khatmat").doc(khatmaId).get();
  
  if (!doc.exists) {
    throw new functions.https.HttpsError(
      ErrorCode.NOT_FOUND,
      `Khatma ${khatmaId} not found`
    );
  }

  return {id: doc.id, ...doc.data()} as Khatma;
}

/**
 * Verify Khatma is ready (not initializing)
 */
export function requireReady(khatma: Khatma): void {
  if (khatma.creationState === "initializing") {
    throw new functions.https.HttpsError(
      ErrorCode.FAILED_PRECONDITION,
      "Khatma is still initializing"
    );
  }
}
