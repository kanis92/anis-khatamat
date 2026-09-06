/**
 * Firebase Admin SDK initialization
 * 
 * Security:
 * - Production credentials supplied ONLY via server environment
 * - NEVER bundle service-account JSON in Git
 * - Test/emulator mode does not require production credentials
 */

import * as admin from 'firebase-admin';
import { getEnvironment } from '../config/environment';

let initialized = false;

export function initializeFirebaseAdmin(): void {
  if (initialized) {
    return;
  }

  const env = getEnvironment();
  const { nodeEnv, firebaseProjectId } = env;

  if (nodeEnv === 'test') {
    // Test mode: use minimal initialization
    // Firebase Admin SDK will use emulator if FIREBASE_AUTH_EMULATOR_HOST is set
    admin.initializeApp({
      projectId: firebaseProjectId,
    });
  } else if (nodeEnv === 'development') {
    // Development: may use emulator or ADC (Application Default Credentials)
    // If FIREBASE_AUTH_EMULATOR_HOST is set, SDK will use emulator
    admin.initializeApp({
      projectId: firebaseProjectId,
    });
  } else {
    // Production: requires explicit credentials
    // Use Application Default Credentials (ADC) or GOOGLE_APPLICATION_CREDENTIALS
    // Never hardcode or bundle credentials in repository
    admin.initializeApp({
      credential: admin.credential.applicationDefault(),
      projectId: firebaseProjectId,
    });
  }

  initialized = true;
}

export function getFirebaseAuth(): admin.auth.Auth {
  if (!initialized) {
    throw new Error('Firebase Admin not initialized. Call initializeFirebaseAdmin() first.');
  }
  return admin.auth();
}

export function getFirestore(): admin.firestore.Firestore {
  if (!initialized) {
    throw new Error('Firebase Admin not initialized. Call initializeFirebaseAdmin() first.');
  }
  return admin.firestore();
}

// For testing: allow reset
export function resetFirebaseAdmin(): void {
  if (initialized) {
    admin.app().delete();
    initialized = false;
  }
}
