import * as admin from "firebase-admin";

// Initialize Firebase Admin for tests
if (!admin.apps.length) {
  admin.initializeApp({
    projectId: "anis-test",
  });
}

// Use Firestore emulator
process.env.FIRESTORE_EMULATOR_HOST = "127.0.0.1:8080";
process.env.FIREBASE_AUTH_EMULATOR_HOST = "127.0.0.1:9099";

export const db = admin.firestore();
export const auth = admin.auth();
