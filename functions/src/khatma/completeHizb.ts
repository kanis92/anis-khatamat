import * as admin from "firebase-admin";
import * as functions from "firebase-functions/v2";
import {
  CompleteHizbRequest,
  CompleteHizbResponse,
  ErrorCode,
  HizbReservation,
} from "../types";
import {getCanonicalUserId, isAdmin} from "../utils/auth";
import {loadKhatma, requireReady} from "../utils/khatma";
import {TOTAL_HIZB} from "../utils/canonical";

/**
 * Complete a reserved Hizb
 * Uses Firestore transaction for concurrency control
 * Updates parent completedHizbCount
 */
export const completeHizb = functions.https.onCall(
  async (request): Promise<CompleteHizbResponse> => {
    const db = admin.firestore();
    const userId = getCanonicalUserId(request.auth);
    const uid = request.auth!.uid;
    const data = request.data as CompleteHizbRequest;

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
    const khatmaRef = db.collection("khatmat").doc(data.khatmaId);

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

        // Can only complete reserved Hizb
        if (current.status !== "reserved") {
          throw new functions.https.HttpsError(
            ErrorCode.FAILED_PRECONDITION,
            `Hizb ${data.hizbNumber} is ${current.status}, not reserved`
          );
        }

        // Check permission: only the reservation owner can complete
        const isOwner = current.reservedBy === userId || current.reservedBy === uid;
        if (!isAdmin(request.auth) && !isOwner) {
          throw new functions.https.HttpsError(
            ErrorCode.PERMISSION_DENIED,
            "Only the reservation owner can complete this Hizb"
          );
        }

        // Mark as completed
        const updates: {[key: string]: unknown} = {
          status: "completed",
          completedAt: admin.firestore.FieldValue.serverTimestamp(),
          completedBy: userId,
        };

        transaction.update(hizbRef, updates);

        // Increment parent completedHizbCount
        transaction.update(khatmaRef, {
          completedHizbCount: admin.firestore.FieldValue.increment(1),
        });
      });

      return {success: true};
    } catch (error) {
      if (error instanceof functions.https.HttpsError) {
        throw error;
      }
      functions.logger.error("completeHizb transaction failed", {
        khatmaId: data.khatmaId,
        hizbNumber: data.hizbNumber,
        error,
      });
      throw new functions.https.HttpsError(
        ErrorCode.INTERNAL,
        "Failed to complete Hizb"
      );
    }
  }
);
