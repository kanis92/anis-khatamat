import * as admin from "firebase-admin";
import * as functions from "firebase-functions/v2";
import {
  CreateKhatmaRequest,
  CreateKhatmaResponse,
  ErrorCode,
} from "../types";
import {getCanonicalUserId} from "../utils/auth";
import {createCanonicalReservation, DEFINITION_ID, TOTAL_HIZB} from "../utils/canonical";

/**
 * Create collaborative Khatma with 60 canonical Hizb
 * Server-authoritative: allocates ID, creates parent, initializes reservations
 */
export const createCollaborativeKhatma = functions.https.onCall(
  async (request): Promise<CreateKhatmaResponse> => {
    const db = admin.firestore();
    const userId = getCanonicalUserId(request.auth);
    const data = request.data as CreateKhatmaRequest;

    // Validate input
    if (!data.title || data.title.trim().length === 0) {
      throw new functions.https.HttpsError(
        ErrorCode.INVALID_ARGUMENT,
        "Title is required"
      );
    }

    const hizbDefinitionId = data.hizbDefinitionId || DEFINITION_ID;
    if (hizbDefinitionId !== DEFINITION_ID) {
      throw new functions.https.HttpsError(
        ErrorCode.INVALID_ARGUMENT,
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
      const parentData = {
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
        Object.assign(parentData, {objectives: data.objectives.trim()});
      }

      batch.set(khatmaRef, parentData);

      // Create all 60 canonical Hizb reservations
      for (let i = 1; i <= TOTAL_HIZB; i++) {
        const reservation = createCanonicalReservation(i, hizbDefinitionId);
        const hizbRef = khatmaRef.collection("hizb_reservations").doc(String(i));
        batch.set(hizbRef, reservation);
      }

      // Mark parent as ready
      batch.update(khatmaRef, {creationState: "ready"});

      // Commit all writes atomically
      await batch.commit();

      return {khatmaId};
    } catch (error) {
      functions.logger.error("createCollaborativeKhatma failed", {
        khatmaId,
        error,
      });
      throw new functions.https.HttpsError(
        ErrorCode.INTERNAL,
        "Failed to create Khatma"
      );
    }
  }
);
