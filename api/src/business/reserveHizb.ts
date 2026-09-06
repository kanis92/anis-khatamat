/**
 * Reserve Hizb Business Logic
 * Extracted from Firebase Functions, adapted for REST API
 */

import * as admin from 'firebase-admin';
import { AuthContext } from '../middleware/auth';
import { ApiError } from '../errors/api-error';
import {
  ReserveHizbRequest,
  ReserveHizbResponse,
  HizbReservation,
} from '../domain/types';
import { getCanonicalUserId, validateDisplayName, isAdmin } from '../domain/auth';
import { loadKhatma, requireReady, isParticipant, isOrganizer } from '../domain/khatma';
import { TOTAL_HIZB } from '../domain/canonical';
import { getFirestore } from '../firebase/admin';

/**
 * Reserve a Hizb for self, offline person, or participant
 * Uses Firestore transaction for concurrency control
 */
export async function reserveHizb(
  auth: AuthContext,
  data: ReserveHizbRequest
): Promise<ReserveHizbResponse> {
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
  if (!["self", "offline", "participant"].includes(data.assigneeKind)) {
    throw ApiError.invalidArgument(
      "assigneeKind must be self, offline, or participant"
    );
  }

  // Load Khatma
  const khatma = await loadKhatma(db, data.khatmaId);
  requireReady(khatma);

  // Check if user is allowed to reserve in this Khatma
  if (!isAdmin(auth) && !isParticipant(khatma, userId, uid)) {
    throw ApiError.forbidden("You are not a participant of this Khatma");
  }

  // Validate assignee kind specific rules
  if (data.assigneeKind === "offline") {
    validateDisplayName(data.assigneeDisplayName);
    // Offline reservations must NOT have assigneeUserId
    if (data.assigneeUserId) {
      throw ApiError.invalidArgument(
        "Offline reservation cannot have assigneeUserId"
      );
    }
  } else if (data.assigneeKind === "self") {
    // Self reservations must be for the caller
    // No assigneeDisplayName or assigneeUserId
    if (data.assigneeDisplayName || data.assigneeUserId) {
      throw ApiError.invalidArgument(
        "Self reservation cannot have assigneeDisplayName or assigneeUserId"
      );
    }
  } else if (data.assigneeKind === "participant") {
    // Only organizers can assign to participants
    if (!isAdmin(auth) && !isOrganizer(khatma, userId)) {
      throw ApiError.forbidden("Only organizers can assign Hizb to participants");
    }
    if (!data.assigneeUserId || data.assigneeUserId.trim().length === 0) {
      throw ApiError.invalidArgument(
        "assigneeUserId required for participant assignment"
      );
    }
    // Verify target user is actually a participant
    if (!isParticipant(khatma, data.assigneeUserId, data.assigneeUserId)) {
      throw ApiError.forbidden("Target user is not a participant of this Khatma");
    }
  }

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

    const hizb = hizbDoc.data() as HizbReservation;

    // Check if Hizb is available
    if (hizb.status !== "available") {
      throw ApiError.conflict(`Hizb ${data.hizbNumber} is already reserved`);
    }

    // Build update data based on assigneeKind
    const updates: Record<string, unknown> = {
      status: "reserved",
      reservedAt: admin.firestore.FieldValue.serverTimestamp(),
      assigneeKind: data.assigneeKind,
    };

    if (data.assigneeKind === "self") {
      updates.reservedBy = userId;
      updates.assigneeUserId = userId;
      // Clear any previous assignment fields
      updates.assigneeDisplayName = admin.firestore.FieldValue.delete();
      updates.assignedByUserId = admin.firestore.FieldValue.delete();
    } else if (data.assigneeKind === "offline") {
      updates.reservedBy = userId;
      updates.assigneeDisplayName = data.assigneeDisplayName!.trim();
      // Clear UID fields
      updates.assigneeUserId = admin.firestore.FieldValue.delete();
      updates.assignedByUserId = admin.firestore.FieldValue.delete();
    } else if (data.assigneeKind === "participant") {
      updates.reservedBy = data.assigneeUserId;
      updates.assigneeUserId = data.assigneeUserId;
      updates.assignedByUserId = userId;
      // Clear display name
      updates.assigneeDisplayName = admin.firestore.FieldValue.delete();
    }

    transaction.update(hizbRef, updates);
  });

  return { success: true };
}
