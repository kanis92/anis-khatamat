/**
 * E2E Test Setup
 * Creates real Firebase Auth users and manages emulator state
 */

import * as admin from 'firebase-admin';
import fetch from 'node-fetch';
import { getFirebaseAuth } from '../../src/firebase/admin';

// Test user credentials
// NOTE: Firebase Auth emulator normalizes emails to lowercase
export const TEST_USERS = {
  creator: {
    email: 'creator@test.com',
    password: 'password123',
    uid: '',
    token: '',
  },
  participantA: {
    email: 'participanta@test.com', // lowercase to match Firebase normalization
    password: 'password123',
    uid: '',
    token: '',
  },
  participantB: {
    email: 'participantb@test.com', // lowercase to match Firebase normalization
    password: 'password123',
    uid: '',
    token: '',
  },
  outsider: {
    email: 'outsider@test.com',
    password: 'password123',
    uid: '',
    token: '',
  },
};

/**
 * Create test users in Firebase Auth emulator
 */
export async function createTestUsers(): Promise<void> {
  const auth = getFirebaseAuth();

  for (const [_key, user] of Object.entries(TEST_USERS)) {
    try {
      const userRecord = await auth.createUser({
        email: user.email,
        password: user.password,
        emailVerified: true,
      });
      user.uid = userRecord.uid;
      
      // Generate custom token for authentication
      const customToken = await auth.createCustomToken(user.uid);
      user.token = customToken;
    } catch (error: any) {
      if (error.code !== 'auth/email-already-exists') {
        throw error;
      }
      // User already exists, get UID
      const userRecord = await auth.getUserByEmail(user.email);
      user.uid = userRecord.uid;
      const customToken = await auth.createCustomToken(user.uid);
      user.token = customToken;
    }
  }
}

/**
 * Clear Firestore data for clean test isolation
 */
export async function clearFirestore(): Promise<void> {
  const db = admin.firestore();
  
  // Delete all khatmat documents
  const khatmat = await db.collection('khatmat').listDocuments();
  for (const doc of khatmat) {
    // Delete subcollections first
    const reservations = await doc.collection('hizb_reservations').listDocuments();
    for (const res of reservations) {
      await res.delete();
    }
    await doc.delete();
  }
}

/**
 * Exchange custom token for ID token (simulates client auth)
 */
export async function getIdToken(customToken: string): Promise<string> {
  // In a real scenario, we'd call Firebase Auth REST API
  // For emulator, custom token can be used directly with verifyIdToken
  // But we need an actual ID token for HTTP Authorization header
  
  // For emulator testing, we'll use a workaround:
  // Create a token that looks like an ID token
  // The emulator is more lenient
  
  // Actually, let's call the Firebase Auth REST API
  const response = await fetch(
    `http://localhost:9099/identitytoolkit.googleapis.com/v1/accounts:signInWithCustomToken?key=fake-api-key`,
    {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({
        token: customToken,
        returnSecureToken: true,
      }),
    }
  );

  if (!response.ok) {
    throw new Error(`Failed to exchange token: ${response.statusText}`);
  }

  const data = await response.json();
  return data.idToken;
}

/**
 * Get auth headers for HTTP requests
 */
export async function getAuthHeaders(userKey: keyof typeof TEST_USERS): Promise<Record<string, string>> {
  const user = TEST_USERS[userKey];
  const idToken = await getIdToken(user.token);
  
  return {
    'Authorization': `Bearer ${idToken}`,
    'Content-Type': 'application/json',
  };
}
