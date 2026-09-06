import canonicalData from "../data/canonical_hizb.json";
import {CanonicalHizbData, HizbCanonical, HizbReservation} from "./types";

const CANONICAL: CanonicalHizbData = canonicalData as CanonicalHizbData;

export const DEFINITION_ID = CANONICAL.definitionId;
export const TOTAL_HIZB = 60;

/**
 * Get canonical Hizb definition by number (1-60)
 */
export function getCanonicalHizb(hizbNumber: number): HizbCanonical {
  if (hizbNumber < 1 || hizbNumber > TOTAL_HIZB) {
    throw new Error(`hizbNumber must be 1-60, got ${hizbNumber}`);
  }
  return CANONICAL.hizbs[hizbNumber - 1];
}

/**
 * Create canonical reservation snapshot for a given Hizb
 */
export function createCanonicalReservation(
  hizbNumber: number,
  definitionId?: string
): HizbReservation {
  const hizb = getCanonicalHizb(hizbNumber);
  return {
    hizbNumber,
    status: "available",
    hizbDefinitionId: definitionId || DEFINITION_ID,
    startVerseKey: `${hizb.startSurah}:${hizb.startAyah}`,
    endVerseKey: `${hizb.endSurah}:${hizb.endAyah}`,
    startPageHafs: hizb.startPageHafs,
    endPageHafs: hizb.endPageHafs,
  };
}

/**
 * Get all 60 canonical Hizb definitions
 */
export function getAllCanonicalHizbs(): HizbCanonical[] {
  return CANONICAL.hizbs;
}
