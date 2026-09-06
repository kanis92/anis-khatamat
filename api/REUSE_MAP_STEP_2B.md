# STEP 2B REUSE MAP — Functions Business Logic Migration

**Source**: `functions/src/`  
**Target**: `api/src/business/`  
**Estimated Reuse**: **~80%** (939 lines from Functions, minimal adapter changes)

---

## FILE CLASSIFICATION

### Category A: Copy Unchanged ✅ (100% Reuse)

| Source File | Target File | Lines | Changes Required |
|-------------|-------------|-------|------------------|
| `functions/src/types.ts` | `api/src/types.ts` | 135 | None — copy as-is |
| `functions/src/data/canonical_hizb.json` | `api/src/data/canonical_hizb.json` | 68 | None — copy as-is |
| `functions/src/utils/canonical.ts` | `api/src/utils/canonical.ts` | 44 | None — copy as-is |
| `functions/src/utils/khatma.ts` | `api/src/utils/khatma.ts` | 73 | None — copy as-is (pure functions) |

**Total**: 320 lines, 100% reuse

---

### Category B: Minimal Adapter (95% Reuse)

| Source File | Target File | Lines | Adaptation |
|-------------|-------------|-------|------------|
| `functions/src/utils/auth.ts` | `api/src/utils/auth.ts` | 50 | Change `functions.https.CallableRequest["auth"]` to `AuthContext` |

**Example Adaptation**:

```typescript
// BEFORE (Firebase Functions):
export function getCanonicalUserId(auth: functions.https.CallableRequest["auth"]): string {
  if (!auth || !auth.uid) {
    throw new functions.https.HttpsError(
      ErrorCode.UNAUTHENTICATED,
      "Authentication required"
    );
  }
  const email = auth.token?.email;
  return email?.trim() || auth.uid;
}

// AFTER (REST API):
export function getCanonicalUserId(auth: AuthContext): string {
  // Already validated by middleware
  const email = auth.email;
  return email?.trim() || auth.uid;
}
```

**Total**: 50 lines, 95% reuse (5 lines changed)

---

### Category C: Extract Business Logic from Wrapper (75% Reuse)

These files wrap business logic in Firebase `onCall` handlers. The core logic is 100% reusable; only the wrapper changes.

| Source File | Target File | Lines | Business Logic Lines | Wrapper Lines |
|-------------|-------------|-------|---------------------|---------------|
| `functions/src/khatma/createCollaborativeKhatma.ts` | `api/src/business/createKhatma.ts` | 100 | ~75 | ~25 |
| `functions/src/khatma/reserveHizb.ts` | `api/src/business/reserveHizb.ts` | 170 | ~130 | ~40 |
| `functions/src/khatma/assignHizbToParticipant.ts` | `api/src/business/assignHizb.ts` | 40 | ~30 | ~10 |
| `functions/src/khatma/releaseHizb.ts` | `api/src/business/releaseHizb.ts` | 110 | ~85 | ~25 |
| `functions/src/khatma/completeHizb.ts` | `api/src/business/completeHizb.ts` | 130 | ~100 | ~30 |

**Total**: 550 lines, ~420 lines reusable business logic (76% reuse)

**Wrapper Conversion Pattern**:

```typescript
// BEFORE (Firebase Functions):
export const reserveHizb = functions.https.onCall(
  async (request): Promise<ReserveHizbResponse> => {
    const db = admin.firestore();
    const userId = getCanonicalUserId(request.auth);
    const data = request.data as ReserveHizbRequest;
    
    // ... validation ...
    // ... business logic ...
    
    return { success: true };
  }
);

// AFTER (REST API):
export async function reserveHizb(
  auth: AuthContext,
  data: ReserveHizbRequest
): Promise<ReserveHizbResponse> {
  const db = getFirestore();
  const userId = getCanonicalUserId(auth);
  
  // ... SAME validation ...
  // ... SAME business logic ...
  
  return { success: true };
}

// Route handler (new):
router.post('/v1/khatmat/:khatmaId/hizb/:hizbNumber/reserve', 
  authMiddleware,
  async (req: Request, res: Response, next: NextFunction) => {
    try {
      const data: ReserveHizbRequest = {
        khatmaId: req.params.khatmaId,
        hizbNumber: parseInt(req.params.hizbNumber),
        ...req.body,
      };
      const result = await reserveHizb((req as AuthenticatedRequest).auth, data);
      res.json(result);
    } catch (error) {
      next(error);
    }
  }
);
```

---

### Category D: Obsolete ❌

**None** — All business logic is reusable.

---

## REUSE SUMMARY

| Category | Files | Lines | Reusable Lines | Reuse % |
|----------|-------|-------|----------------|---------|
| A: Unchanged | 4 | 320 | 320 | 100% |
| B: Minimal Adapter | 1 | 50 | 47 | 94% |
| C: Extract Business Logic | 5 | 550 | 420 | 76% |
| **Total** | **10** | **920** | **787** | **~86%** |

---

## STEP 2B IMPLEMENTATION PLAN

### 1. Copy Unchanged Files

```bash
cp functions/src/types.ts api/src/types.ts
cp functions/src/data/canonical_hizb.json api/src/data/canonical_hizb.json
cp functions/src/utils/canonical.ts api/src/utils/canonical.ts
cp functions/src/utils/khatma.ts api/src/utils/khatma.ts
```

### 2. Adapt auth.ts

- Copy `functions/src/utils/auth.ts` to `api/src/utils/auth.ts`
- Replace `functions.https.CallableRequest["auth"]` with `AuthContext` (from `api/src/middleware/auth.ts`)
- Replace `functions.https.HttpsError` with `ApiError` (from `api/src/errors/api-error.ts`)

### 3. Extract Business Logic

For each mutation file:

1. Copy file to `api/src/business/`
2. Remove `export const functionName = functions.https.onCall(...)` wrapper
3. Convert to `export async function functionName(auth: AuthContext, data: RequestType): Promise<ResponseType>`
4. Replace `admin.firestore()` with `getFirestore()` (from `api/src/firebase/admin.ts`)
5. Replace `functions.https.HttpsError` with `ApiError`
6. Keep ALL validation, authorization, transaction logic unchanged

### 4. Create Route Handlers

Create `api/src/routes/khatmat.ts`:

```typescript
import { Router } from 'express';
import { authMiddleware, AuthenticatedRequest } from '../middleware/auth';
import * as khatmaBusinessLogic from '../business';

const router = Router();

router.post('/v1/khatmat', authMiddleware, async (req, res, next) => {
  try {
    const result = await khatmaBusinessLogic.createKhatma(req.auth, req.body);
    res.status(201).json(result);
  } catch (error) {
    next(error);
  }
});

router.post('/v1/khatmat/:khatmaId/hizb/:hizbNumber/reserve', authMiddleware, async (req, res, next) => {
  try {
    const data = {
      khatmaId: req.params.khatmaId,
      hizbNumber: parseInt(req.params.hizbNumber),
      ...req.body,
    };
    const result = await khatmaBusinessLogic.reserveHizb(req.auth, data);
    res.json(result);
  } catch (error) {
    next(error);
  }
});

// ... (assign, release, complete)

export default router;
```

### 5. Update app.ts

```typescript
import khatmatRouter from './routes/khatmat';

// After health router:
app.use(khatmatRouter);
```

### 6. Add Tests

Adapt `functions/__tests__/khatma.test.ts` to REST API format:

- Replace Firebase Functions test framework with supertest
- Replace `httpsCallable` with `request(app).post('/v1/...')`
- Keep ALL business logic tests (14 tests)

---

## VALIDATION CHECKLIST

After STEP 2B:

- ✅ All 14 business logic tests pass (from Functions)
- ✅ All 28 foundation tests pass (from STEP 2A)
- ✅ TypeScript build succeeds
- ✅ No linter errors
- ✅ Business logic unchanged (validate with diff)
- ✅ Authorization rules preserved
- ✅ Transaction semantics preserved
- ✅ Error codes stable

---

## ESTIMATED EFFORT

- **Copy unchanged**: 15 minutes
- **Adapt auth.ts**: 15 minutes
- **Extract business logic (5 files)**: 2 hours
- **Create route handlers**: 1 hour
- **Adapt tests**: 1.5 hours
- **Validation**: 30 minutes

**Total**: ~5-6 hours

---

## CONFIDENCE LEVEL

✅ **HIGH** — Business logic is pure, well-tested, and platform-agnostic. Wrapper conversion is mechanical and low-risk.
