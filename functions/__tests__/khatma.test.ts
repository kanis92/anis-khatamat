import * as admin from "firebase-admin";
import {db} from "./setup";
import {
  CreateKhatmaRequest,
  ReserveHizbRequest,
  ReleaseHizbRequest,
  CompleteHizbRequest,
} from "../src/types";

// Mock callable context
function createMockRequest(
  data: any,
  userId: string | null,
  email?: string,
  admin = false
) {
  if (!userId) {
    return {
      data,
      auth: undefined,
    };
  }
  return {
    data,
    auth: {
      uid: userId,
      token: {
        email: email || `${userId}@test.com`,
        admin,
      },
    },
  };
}

// Import functions - these need to be imported after Firebase is initialized
import {createCollaborativeKhatma} from "../src/khatma/createCollaborativeKhatma";
import {reserveHizb} from "../src/khatma/reserveHizb";
import {releaseHizb} from "../src/khatma/releaseHizb";
import {completeHizb} from "../src/khatma/completeHizb";

describe("Khatma Callable Functions", () => {
  beforeEach(async () => {
    // Clear Firestore before each test
    const collections = await db.listCollections();
    for (const collection of collections) {
      const docs = await collection.listDocuments();
      for (const doc of docs) {
        await doc.delete();
      }
    }
  });

  describe("createCollaborativeKhatma", () => {
    it("should create Khatma with 60 Hizb", async () => {
      const request = createMockRequest(
        {
          title: "Test Khatma",
          isGroup: true,
          isPublic: false,
          members: ["member1@test.com"],
        } as CreateKhatmaRequest,
        "creator-uid",
        "creator@test.com"
      );

      const result = await createCollaborativeKhatma.run(request as any);
      expect(result.khatmaId).toBeDefined();

      // Verify parent document
      const khatmaDoc = await db.collection("khatmat").doc(result.khatmaId).get();
      expect(khatmaDoc.exists).toBe(true);
      const khatma = khatmaDoc.data();
      expect(khatma?.title).toBe("Test Khatma");
      expect(khatma?.createdBy).toBe("creator@test.com");
      expect(khatma?.creationState).toBe("ready");
      expect(khatma?.hizbDefinitionId).toBe("quran_foundation_hafs_v1");

      // Verify 60 Hizb reservations
      const reservations = await db
        .collection("khatmat")
        .doc(result.khatmaId)
        .collection("hizb_reservations")
        .get();
      expect(reservations.size).toBe(60);

      // Verify all are available
      reservations.forEach((doc) => {
        const data = doc.data();
        expect(data.status).toBe("available");
        expect(data.hizbNumber).toBeGreaterThanOrEqual(1);
        expect(data.hizbNumber).toBeLessThanOrEqual(60);
        expect(data.hizbDefinitionId).toBe("quran_foundation_hafs_v1");
      });
    });

    it("should deny unauthenticated creation", async () => {
      const request = createMockRequest(
        {
          title: "Test",
          isGroup: false,
          isPublic: false,
        } as CreateKhatmaRequest,
        null
      );

      await expect(createCollaborativeKhatma.run(request as any)).rejects.toThrow();
    });

    it("should deny empty title", async () => {
      const request = createMockRequest(
        {
          title: "",
          isGroup: false,
          isPublic: false,
        } as CreateKhatmaRequest,
        "user-uid"
      );

      await expect(createCollaborativeKhatma.run(request as any)).rejects.toThrow(
        /Title is required/
      );
    });
  });

  describe("reserveHizb", () => {
    let khatmaId: string;

    beforeEach(async () => {
      const request = createMockRequest(
        {
          title: "Test Khatma",
          isGroup: true,
          isPublic: false,
        } as CreateKhatmaRequest,
        "creator-uid",
        "creator@test.com"
      );
      const result = await createCollaborativeKhatma.run(request as any);
      khatmaId = result.khatmaId;
    });

    it("should allow self reservation", async () => {
      const request = createMockRequest(
        {
          khatmaId,
          hizbNumber: 1,
          assigneeKind: "self",
        } as ReserveHizbRequest,
        "creator-uid",
        "creator@test.com"
      );

      const result = await reserveHizb.run(request as any);
      expect(result.success).toBe(true);

      // Verify reservation
      const hizbDoc = await db
        .collection("khatmat")
        .doc(khatmaId)
        .collection("hizb_reservations")
        .doc("1")
        .get();
      const hizb = hizbDoc.data();
      expect(hizb?.status).toBe("reserved");
      expect(hizb?.assigneeKind).toBe("self");
      expect(hizb?.reservedBy).toBe("creator@test.com");
      expect(hizb?.assigneeUserId).toBe("creator@test.com");
    });

    it("should allow offline reservation with display name", async () => {
      const request = createMockRequest(
        {
          khatmaId,
          hizbNumber: 2,
          assigneeKind: "offline",
          assigneeDisplayName: "Fatima",
        } as ReserveHizbRequest,
        "creator-uid",
        "creator@test.com"
      );

      const result = await reserveHizb.run(request as any);
      expect(result.success).toBe(true);

      // Verify reservation
      const hizbDoc = await db
        .collection("khatmat")
        .doc(khatmaId)
        .collection("hizb_reservations")
        .doc("2")
        .get();
      const hizb = hizbDoc.data();
      expect(hizb?.status).toBe("reserved");
      expect(hizb?.assigneeKind).toBe("offline");
      expect(hizb?.assigneeDisplayName).toBe("Fatima");
      expect(hizb?.assigneeUserId).toBeUndefined();
    });

    it("should deny offline reservation without display name", async () => {
      const request = createMockRequest(
        {
          khatmaId,
          hizbNumber: 2,
          assigneeKind: "offline",
        } as ReserveHizbRequest,
        "creator-uid",
        "creator@test.com"
      );

      await expect(reserveHizb.run(request as any)).rejects.toThrow(
        /Display name required/
      );
    });

    it("should deny offline reservation with UID injection", async () => {
      const request = createMockRequest(
        {
          khatmaId,
          hizbNumber: 2,
          assigneeKind: "offline",
          assigneeDisplayName: "Fatima",
          assigneeUserId: "forged-uid",
        } as ReserveHizbRequest,
        "creator-uid",
        "creator@test.com"
      );

      await expect(reserveHizb.run(request as any)).rejects.toThrow(
        /Offline reservation cannot have assigneeUserId/
      );
    });

    it("should deny concurrent reservation (conflict)", async () => {
      // First, add user1 to the Khatma as member
      await db.collection("khatmat").doc(khatmaId).update({
        members: ["user1@test.com"],
        participantIds: ["creator@test.com", "user1@test.com"]
      });

      // First reservation
      const request1 = createMockRequest(
        {
          khatmaId,
          hizbNumber: 3,
          assigneeKind: "self",
        } as ReserveHizbRequest,
        "user1-uid",
        "user1@test.com"
      );
      await reserveHizb.run(request1 as any);

      // Second reservation on same Hizb (by another participant)
      const request2 = createMockRequest(
        {
          khatmaId,
          hizbNumber: 3,
          assigneeKind: "self",
        } as ReserveHizbRequest,
        "creator-uid",
        "creator@test.com"
      );

      await expect(reserveHizb.run(request2 as any)).rejects.toThrow(/already reserved/);
    });

    it("should deny non-participant reservation", async () => {
      const request = createMockRequest(
        {
          khatmaId,
          hizbNumber: 4,
          assigneeKind: "self",
        } as ReserveHizbRequest,
        "outsider-uid",
        "outsider@test.com"
      );

      await expect(reserveHizb.run(request as any)).rejects.toThrow(
        /not a participant/
      );
    });
  });

  describe("releaseHizb", () => {
    let khatmaId: string;

    beforeEach(async () => {
      const createReq = createMockRequest(
        {
          title: "Test Khatma",
          isGroup: true,
          isPublic: false,
        } as CreateKhatmaRequest,
        "creator-uid",
        "creator@test.com"
      );
      const createRes = await createCollaborativeKhatma.run(createReq as any);
      khatmaId = createRes.khatmaId;

      // Reserve Hizb 1
      const reserveReq = createMockRequest(
        {
          khatmaId,
          hizbNumber: 1,
          assigneeKind: "self",
        } as ReserveHizbRequest,
        "creator-uid",
        "creator@test.com"
      );
      await reserveHizb.run(reserveReq as any);
    });

    it("should allow owner to release", async () => {
      const request = createMockRequest(
        {
          khatmaId,
          hizbNumber: 1,
        } as ReleaseHizbRequest,
        "creator-uid",
        "creator@test.com"
      );

      const result = await releaseHizb.run(request as any);
      expect(result.success).toBe(true);

      // Verify released
      const hizbDoc = await db
        .collection("khatmat")
        .doc(khatmaId)
        .collection("hizb_reservations")
        .doc("1")
        .get();
      const hizb = hizbDoc.data();
      expect(hizb?.status).toBe("available");
      expect(hizb?.reservedBy).toBeUndefined();
      expect(hizb?.assigneeKind).toBeUndefined();
    });

    it("should deny non-owner release", async () => {
      // Add another user as participant (but not organizer)
      await db.collection("khatmat").doc(khatmaId).update({
        participantIds: admin.firestore.FieldValue.arrayUnion("other@test.com")
      });

      const request = createMockRequest(
        {
          khatmaId,
          hizbNumber: 1,
        } as ReleaseHizbRequest,
        "other-uid",
        "other@test.com"
      );

      await expect(releaseHizb.run(request as any)).rejects.toThrow(
        /Only the reservation owner or organizers/
      );
    });
  });

  describe("completeHizb", () => {
    let khatmaId: string;

    beforeEach(async () => {
      const createReq = createMockRequest(
        {
          title: "Test Khatma",
          isGroup: true,
          isPublic: false,
        } as CreateKhatmaRequest,
        "creator-uid",
        "creator@test.com"
      );
      const createRes = await createCollaborativeKhatma.run(createReq as any);
      khatmaId = createRes.khatmaId;

      // Reserve Hizb 1
      const reserveReq = createMockRequest(
        {
          khatmaId,
          hizbNumber: 1,
          assigneeKind: "self",
        } as ReserveHizbRequest,
        "creator-uid",
        "creator@test.com"
      );
      await reserveHizb.run(reserveReq as any);
    });

    it("should allow owner to complete and increment counter", async () => {
      const request = createMockRequest(
        {
          khatmaId,
          hizbNumber: 1,
        } as CompleteHizbRequest,
        "creator-uid",
        "creator@test.com"
      );

      const result = await completeHizb.run(request as any);
      expect(result.success).toBe(true);

      // Verify completed
      const hizbDoc = await db
        .collection("khatmat")
        .doc(khatmaId)
        .collection("hizb_reservations")
        .doc("1")
        .get();
      const hizb = hizbDoc.data();
      expect(hizb?.status).toBe("completed");
      expect(hizb?.completedBy).toBe("creator@test.com");

      // Verify parent counter
      const khatmaDoc = await db.collection("khatmat").doc(khatmaId).get();
      const khatma = khatmaDoc.data();
      expect(khatma?.completedHizbCount).toBe(1);
    });

    it("should deny non-owner completion", async () => {
      // Add another user as participant (but not organizer)
      await db.collection("khatmat").doc(khatmaId).update({
        participantIds: admin.firestore.FieldValue.arrayUnion("other@test.com")
      });

      const request = createMockRequest(
        {
          khatmaId,
          hizbNumber: 1,
        } as CompleteHizbRequest,
        "other-uid",
        "other@test.com"
      );

      await expect(completeHizb.run(request as any)).rejects.toThrow(
        /Only the reservation owner/
      );
    });

    it("should deny completion of available Hizb", async () => {
      const request = createMockRequest(
        {
          khatmaId,
          hizbNumber: 2,
        } as CompleteHizbRequest,
        "creator-uid",
        "creator@test.com"
      );

      await expect(completeHizb.run(request as any)).rejects.toThrow(
        /not reserved/
      );
    });
  });
});
