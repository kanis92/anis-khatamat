/**
 * Complete Hizb Business Logic
 * Extracted from Firebase Functions, adapted for REST API
 */

import * as admin from 'firebase-admin';
import { AuthContext } from '../middleware/auth';
import { ApiError } from '../errors/api-error';
import {
  CompleteHizbRequest,
  CompleteHizbResponse,
  HizbReservation,
} from '../domain/types';
import { getCanonicalUserId, isAdmin } from '../domain/auth';
import { loadKhatma, requireReady } from '../domain/khatma';
import { TOTAL_HIZB } from '../domain/canonical';
import { getFirestore } from '../firebase/admin';

/**
 * Complete a reserved Hizb
 * Uses Firestore transaction for concurrency control
 * Updates parent completedHizbCount
 */
export async function completeHizb(
  auth: AuthContext,
  data: CompleteHizbRequest
): Promise<CompleteHizbResponse> {
  const db = getFirestore();
  const userId = getCanonicalUserId(auth);
  const uid = auth.uid;

  // Validate input
  if (!data.khatmaId || data.khatmaId.trim().length === 0) {
    throw ApiError.invalidArgument("khatmaId is required");
  }
  if (data.hizbNumber < 1 || data.hizbNumber > TOTAL_HIZB) {
    throw ApiError.invalidArgument(`hizbNumber must be 1-${TOTAL_HIZB}`);
  }

  // Load Khatma
  const khatma = await loadKhatma(db, data.khatmaId);
  requireReady(khatma);

  // Use transaction for concurrency control
  const hizbRef = db
    .collection("khatmat")
    .doc(data.khatmaId)
    .collection("hizb_reservations")
    .doc(String(data.hizbNumber));
  const khatmaRef = db.collection("khatmat").doc(data.khatmaId);

  await db.runTransaction(async (transaction) => {
    const hizbDoc = await transaction.get(hizbRef);

    if (!hizbDoc.exists) {
      throw ApiError.notFound("Hizb", String(data.hizbNumber));
    }

    const current = hizbDoc.data() as HizbReservation;

    // Can only complete reserved Hizb
    if (current.status !== "reserved") {
      throw ApiError.conflict(
        `Hizb ${data.hizbNumber} is ${current.status}, not reserved`
      );
    }

    // Check permission: only the reservation owner can complete
    const isOwner = current.reservedBy === userId || current.reservedBy === uid;
    if (!isAdmin(auth) && !isOwner) {
      throw ApiError.forbidden(
        "Only the reservation owner can complete this Hizb"
      );
    }

    // Mark as completed
    const updates: Record<string, unknown> = {
      status: "completed",
      completedBy: userId,
      completedAt: admin.firestore.FieldValue.serverTimestamp(),
    };

    transaction.update(hizbRef, updates);

    // Increment parent counter
    transaction.update(khatmaRef, {
      completedHizbCount: admin.firestore.FieldValue.increment(1),
    });
  });

  return { success: true };
}
