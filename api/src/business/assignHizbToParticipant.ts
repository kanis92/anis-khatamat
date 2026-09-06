/**
 * Assign Hizb to Participant Business Logic
 * Convenience wrapper around reserveHizb for organizer assignments
 */

import { AuthContext } from '../middleware/auth';
import {
  AssignHizbToParticipantRequest,
  AssignHizbToParticipantResponse,
  ReserveHizbRequest,
} from '../domain/types';
import { reserveHizb } from './reserveHizb';

/**
 * Assign a Hizb to a participant (organizer-only operation)
 * This is a convenience wrapper around reserveHizb with assigneeKind="participant"
 */
export async function assignHizbToParticipant(
  auth: AuthContext,
  data: AssignHizbToParticipantRequest
): Promise<AssignHizbToParticipantResponse> {
  // Delegate to reserveHizb with participant assignee kind
  const reserveRequest: ReserveHizbRequest = {
    khatmaId: data.khatmaId,
    hizbNumber: data.hizbNumber,
    assigneeKind: "participant",
    assigneeUserId: data.participantUserId,
  };

  const result = await reserveHizb(auth, reserveRequest);
  return { success: result.success };
}
