/**
 * Server-authoritative Khatma mutation types
 */

export interface HizbCanonical {
  hizbNumber: number;
  juzNumber: number;
  startSurah: number;
  startAyah: number;
  endSurah: number;
  endAyah: number;
  startPageHafs: number;
  endPageHafs: number;
}

export interface CanonicalHizbData {
  sourceUrl: string;
  certifiedAt: string;
  definitionId: string;
  hizbs: HizbCanonical[];
}

export type AssigneeKind = "self" | "offline" | "participant";

export type ReservationStatus = "available" | "reserved" | "completed";

export interface HizbReservation {
  hizbNumber: number;
  status: ReservationStatus;
  hizbDefinitionId: string | null;
  startVerseKey: string;
  endVerseKey: string;
  startPageHafs: number;
  endPageHafs: number;
  reservedBy?: string;
  assigneeKind?: AssigneeKind;
  assigneeUserId?: string;
  assigneeDisplayName?: string;
  assignedByUserId?: string;
  reservedAt?: string;
  completedAt?: string;
  completedBy?: string;
}

export interface Khatma {
  id: string;
  title: string;
  createdBy: string;
  createdAt: string;
  isGroup: boolean;
  isPublic: boolean;
  reservationMode: boolean;
  reservationSchemaVersion: number;
  completedHizbCount: number;
  participantIds: string[];
  members: string[];
  guestParticipants: Record<string, unknown>;
  creationState: "initializing" | "ready";
  hizbDefinitionId: string;
  objectives?: string;
}

/**
 * Callable function error codes
 */
export enum ErrorCode {
  UNAUTHENTICATED = "unauthenticated",
  PERMISSION_DENIED = "permission-denied",
  NOT_FOUND = "not-found",
  ALREADY_EXISTS = "already-exists",
  CONFLICT = "conflict",
  INVALID_ARGUMENT = "invalid-argument",
  FAILED_PRECONDITION = "failed-precondition",
  RESOURCE_EXHAUSTED = "resource-exhausted",
  INTERNAL = "internal",
  UNAVAILABLE = "unavailable",
}

/**
 * Request/Response types for callable functions
 */

export interface CreateKhatmaRequest {
  title: string;
  isGroup: boolean;
  isPublic: boolean;
  hizbDefinitionId?: string;
  objectives?: string;
  members?: string[];
}

export interface CreateKhatmaResponse {
  khatmaId: string;
}

export interface ReserveHizbRequest {
  khatmaId: string;
  hizbNumber: number;
  assigneeKind: AssigneeKind;
  assigneeDisplayName?: string;
  assigneeUserId?: string;
}

export interface ReserveHizbResponse {
  success: boolean;
}

export interface AssignHizbToParticipantRequest {
  khatmaId: string;
  hizbNumber: number;
  participantUserId: string;
}

export interface AssignHizbToParticipantResponse {
  success: boolean;
}

export interface ReleaseHizbRequest {
  khatmaId: string;
  hizbNumber: number;
}

export interface ReleaseHizbResponse {
  success: boolean;
}

export interface CompleteHizbRequest {
  khatmaId: string;
  hizbNumber: number;
}

export interface CompleteHizbResponse {
  success: boolean;
}
