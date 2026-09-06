/**
 * Release Hizb Business Logic
 * Extracted from Firebase Functions, adapted for REST API
 */

import * as admin from 'firebase-admin';
import { AuthContext } from '../middleware/auth';
import { ApiError } from '../errors/api-error';
import {
  ReleaseHizbRequest,
  ReleaseHizbResponse,
  HizbReservation,
} from '../domain/types';
import { getCanonicalUserId, isAdmin } from '../domain/auth';
import { loadKhatma, requireReady, isOrganizer } from '../domain/khatma';
import { TOTAL_HIZB } from '../domain/canonical';
import { getFirestore } from '../firebase/admin';

/**
 * Release a reserved Hizb back to available
 * Uses Firestore transaction for concurrency control
 */
export async function releaseHizb(
  auth: AuthContext,
  data: ReleaseHizbRequest
): Promise<ReleaseHizbResponse> {
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

  await db.runTransaction(async (transaction) => {
    const hizbDoc = await transaction.get(hizbRef);

    if (!hizbDoc.exists) {
      throw ApiError.notFound("Hizb", String(data.hizbNumber));
    }

    const current = hizbDoc.data() as HizbReservation;

    // Can only release reserved Hizb
    if (current.status !== "reserved") {
      throw ApiError.conflict(
        `Hizb ${data.hizbNumber} is ${current.status}, not reserved`
      );
    }

    // Check permission: owner or organizer
    const isOwner = current.reservedBy === userId || current.reservedBy === uid;
    const isOrganizerUser = isOrganizer(khatma, userId);
    const hasPermission = isAdmin(auth) || isOwner || isOrganizerUser;

    if (!hasPermission) {
      throw ApiError.forbidden(
        "Only the reservation owner or organizers can release this Hizb"
      );
    }

    // Release: clear all assignment fields
    const updates: Record<string, unknown> = {
      status: "available",
      reservedBy: admin.firestore.FieldValue.delete(),
      assigneeKind: admin.firestore.FieldValue.delete(),
      assigneeUserId: admin.firestore.FieldValue.delete(),
      assigneeDisplayName: admin.firestore.FieldValue.delete(),
      assignedByUserId: admin.firestore.FieldValue.delete(),
      reservedAt: admin.firestore.FieldValue.delete(),
    };

    transaction.update(hizbRef, updates);
  });

  return { success: true };
}
