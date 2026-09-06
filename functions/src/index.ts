import * as admin from "firebase-admin";

// Initialize Firebase Admin
admin.initializeApp();

// Export callable functions
export {createCollaborativeKhatma} from "./khatma/createCollaborativeKhatma";
export {reserveHizb} from "./khatma/reserveHizb";
export {assignHizbToParticipant} from "./khatma/assignHizbToParticipant";
export {releaseHizb} from "./khatma/releaseHizb";
export {completeHizb} from "./khatma/completeHizb";
