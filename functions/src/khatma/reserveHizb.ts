import * as admin from "firebase-admin";
import * as functions from "firebase-functions/v2";
import {
  ReserveHizbRequest,
  ReserveHizbResponse,
  ErrorCode,
  HizbReservation,
} from "../types";
import {getCanonicalUserId, validateDisplayName, isAdmin} from "../utils/auth";
import {loadKhatma, requireReady, isParticipant, isOrganizer} from "../utils/khatma";
import {TOTAL_HIZB} from "../utils/canonical";

/**
 * Reserve a Hizb for self, offline person, or participant
 * Uses Firestore transaction for concurrency control
 */
export const reserveHizb = functions.https.onCall(
  async (request): Promise<ReserveHizbResponse> => {
    const db = admin.firestore();
    const userId = getCanonicalUserId(request.auth);
    const uid = request.auth!.uid;
    const data = request.data as ReserveHizbRequest;

    // Validate input
    if (!data.khatmaId || data.khatmaId.trim().length === 0) {
      throw new functions.https.HttpsError(
        ErrorCode.INVALID_ARGUMENT,
        "khatmaId is required"
      );
    }
    if (data.hizbNumber < 1 || data.hizbNumber > TOTAL_HIZB) {
      throw new functions.https.HttpsError(
        ErrorCode.INVALID_ARGUMENT,
        `hizbNumber must be 1-${TOTAL_HIZB}`
      );
    }
    if (!["self", "offline", "participant"].includes(data.assigneeKind)) {
      throw new functions.https.HttpsError(
        ErrorCode.INVALID_ARGUMENT,
        "assigneeKind must be self, offline, or participant"
      );
    }

    // Load Khatma
    const khatma = await loadKhatma(db, data.khatmaId);
    requireReady(khatma);

    // Check if user is allowed to reserve in this Khatma
    if (!isAdmin(request.auth) && !isParticipant(khatma, userId, uid)) {
      throw new functions.https.HttpsError(
        ErrorCode.PERMISSION_DENIED,
        "You are not a participant of this Khatma"
      );
    }

    // Validate assignee kind specific rules
    if (data.assigneeKind === "offline") {
      validateDisplayName(data.assigneeDisplayName);
      // Offline reservations must NOT have assigneeUserId
      if (data.assigneeUserId) {
        throw new functions.https.HttpsError(
          ErrorCode.INVALID_ARGUMENT,
          "Offline reservation cannot have assigneeUserId"
        );
      }
    } else if (data.assigneeKind === "self") {
      // Self reservations must be for the caller
      // No assigneeDisplayName or assigneeUserId
      if (data.assigneeDisplayName || data.assigneeUserId) {
        throw new functions.https.HttpsError(
          ErrorCode.INVALID_ARGUMENT,
          "Self reservation cannot have assigneeDisplayName or assigneeUserId"
        );
      }
    } else if (data.assigneeKind === "participant") {
      // Only organizers can assign to participants
      if (!isAdmin(request.auth) && !isOrganizer(khatma, userId)) {
        throw new functions.https.HttpsError(
          ErrorCode.PERMISSION_DENIED,
          "Only organizers can assign Hizb to participants"
        );
      }
      if (!data.assigneeUserId || data.assigneeUserId.trim().length === 0) {
        throw new functions.https.HttpsError(
          ErrorCode.INVALID_ARGUMENT,
          "assigneeUserId required for participant assignment"
        );
      }
      // Verify target user is actually a participant
      if (!isParticipant(khatma, data.assigneeUserId, data.assigneeUserId)) {
        throw new functions.https.HttpsError(
          ErrorCode.PERMISSION_DENIED,
          "Target user is not a participant of this Khatma"
        );
      }
    }

    // Use transaction for concurrency control
    const hizbRef = db
      .collection("khatmat")
      .doc(data.khatmaId)
      .collection("hizb_reservations")
      .doc(String(data.hizbNumber));

    try {
      await db.runTransaction(async (transaction) => {
        const hizbDoc = await transaction.get(hizbRef);
        
        if (!hizbDoc.exists) {
          throw new functions.https.HttpsError(
            ErrorCode.NOT_FOUND,
            `Hizb ${data.hizbNumber} not found`
          );
        }

        const current = hizbDoc.data() as HizbReservation;

        // Check if already reserved
        if (current.status !== "available") {
          throw new functions.https.HttpsError(
            "already-exists",
            `Hizb ${data.hizbNumber} is already ${current.status}`
          );
        }

        // Build update data based on assigneeKind
        const updates: {[key: string]: unknown} = {
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

      return {success: true};
    } catch (error) {
      // Re-throw HttpsError
      if (error instanceof functions.https.HttpsError) {
        throw error;
      }
      functions.logger.error("reserveHizb transaction failed", {
        khatmaId: data.khatmaId,
        hizbNumber: data.hizbNumber,
        error,
      });
      throw new functions.https.HttpsError(
        ErrorCode.INTERNAL,
        "Failed to reserve Hizb"
      );
    }
  }
);
