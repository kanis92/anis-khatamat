import * as admin from "firebase-admin";
import * as functions from "firebase-functions/v2";
import {
  ReleaseHizbRequest,
  ReleaseHizbResponse,
  ErrorCode,
  HizbReservation,
} from "../types";
import {getCanonicalUserId, isAdmin} from "../utils/auth";
import {loadKhatma, requireReady, isOrganizer} from "../utils/khatma";
import {TOTAL_HIZB} from "../utils/canonical";

/**
 * Release a reserved Hizb back to available
 * Uses Firestore transaction for concurrency control
 */
export const releaseHizb = functions.https.onCall(
  async (request): Promise<ReleaseHizbResponse> => {
    const db = admin.firestore();
    const userId = getCanonicalUserId(request.auth);
    const uid = request.auth!.uid;
    const data = request.data as ReleaseHizbRequest;

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

    // Load Khatma
    const khatma = await loadKhatma(db, data.khatmaId);
    requireReady(khatma);

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

        // Can only release reserved Hizb
        if (current.status !== "reserved") {
          throw new functions.https.HttpsError(
            ErrorCode.FAILED_PRECONDITION,
            `Hizb ${data.hizbNumber} is ${current.status}, not reserved`
          );
        }

        // Check permission: owner or organizer
        const isOwner = current.reservedBy === userId || current.reservedBy === uid;
        const isOrganizerUser = isOrganizer(khatma, userId);
        const hasPermission = isAdmin(request.auth) || isOwner || isOrganizerUser;

        if (!hasPermission) {
          throw new functions.https.HttpsError(
            ErrorCode.PERMISSION_DENIED,
            "Only the reservation owner or organizers can release this Hizb"
          );
        }

        // Release: clear all assignment fields
        const updates: {[key: string]: unknown} = {
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

      return {success: true};
    } catch (error) {
      if (error instanceof functions.https.HttpsError) {
        throw error;
      }
      functions.logger.error("releaseHizb transaction failed", {
        khatmaId: data.khatmaId,
        hizbNumber: data.hizbNumber,
        error,
      });
      throw new functions.https.HttpsError(
        ErrorCode.INTERNAL,
        "Failed to release Hizb"
      );
    }
  }
);
