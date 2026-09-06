import * as functions from "firebase-functions/v2";
import {ErrorCode} from "../types";

/**
 * Derive canonical user identity from authenticated request
 * Prefer email, fall back to UID
 */
export function getCanonicalUserId(auth: functions.https.CallableRequest["auth"]): string {
  if (!auth || !auth.uid) {
    throw new functions.https.HttpsError(
      ErrorCode.UNAUTHENTICATED,
      "Authentication required"
    );
  }

  // Prefer email for canonical identity
  const email = auth.token?.email;
  if (email && email.trim().length > 0) {
    return email.trim();
  }

  // Fallback to UID
  return auth.uid;
}

/**
 * Validate display name for offline reservations
 */
export function validateDisplayName(name: string | undefined): void {
  if (!name || name.trim().length === 0) {
    throw new functions.https.HttpsError(
      ErrorCode.INVALID_ARGUMENT,
      "Display name required for offline reservation"
    );
  }
  if (name.trim().length > 50) {
    throw new functions.https.HttpsError(
      ErrorCode.INVALID_ARGUMENT,
      "Display name must be 50 characters or less"
    );
  }
}

/**
 * Check if user is admin
 */
export function isAdmin(auth: functions.https.CallableRequest["auth"]): boolean {
  return auth?.token?.admin === true;
}
