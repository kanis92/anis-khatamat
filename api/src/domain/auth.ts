/**
 * Domain authentication utilities
 * Adapted from Firebase Functions to REST API
 */

import { AuthContext } from '../middleware/auth';
import { ApiError } from '../errors/api-error';

/**
 * Derive canonical user identity from authenticated context
 * 
 * NEW IDENTITIES (2026-09+):
 * - Email is normalized: trim().toLowerCase()
 * - Ensures consistent comparison regardless of input case
 * 
 * LEGACY COMPATIBILITY:
 * - isParticipant() checks both normalized and raw values
 * - Historical mixed-case emails in Firestore remain readable
 * - No production data migration required
 */
export function getCanonicalUserId(auth: AuthContext): string {
  // Auth middleware already validated that uid exists
  const email = auth.email;
  if (email && email.trim().length > 0) {
    // NEW: Normalize to lowercase for consistent identity
    return email.trim().toLowerCase();
  }

  // Fallback to UID
  return auth.uid;
}

/**
 * Validate display name for offline reservations
 */
export function validateDisplayName(name: string | undefined): void {
  if (!name || name.trim().length === 0) {
    throw ApiError.invalidArgument(
      "Display name required for offline reservation"
    );
  }
  if (name.trim().length > 50) {
    throw ApiError.invalidArgument(
      "Display name must be 50 characters or less"
    );
  }
}

/**
 * Check if user is admin
 */
export function isAdmin(auth: AuthContext): boolean {
  return auth.isAdmin === true;
}
