import * as functions from "firebase-functions/v2";
import {
  AssignHizbToParticipantRequest,
  AssignHizbToParticipantResponse,
  ReserveHizbRequest,
} from "../types";
import {reserveHizb} from "./reserveHizb";

/**
 * Assign a Hizb to a participant (organizer-only operation)
 * This is a convenience wrapper around reserveHizb with assigneeKind="participant"
 */
export const assignHizbToParticipant = functions.https.onCall(
  async (request): Promise<AssignHizbToParticipantResponse> => {
    const data = request.data as AssignHizbToParticipantRequest;

    // Delegate to reserveHizb with participant assignee kind
    const reserveRequest: ReserveHizbRequest = {
      khatmaId: data.khatmaId,
      hizbNumber: data.hizbNumber,
      assigneeKind: "participant",
      assigneeUserId: data.participantUserId,
    };

    // Call reserveHizb with modified request
    const modifiedRequest = {
      ...request,
      data: reserveRequest,
    };

    const result = await reserveHizb.run(modifiedRequest as any);
    return {success: result.success};
  }
);
