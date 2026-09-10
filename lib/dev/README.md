# Auth Provider Validation Harness

## Purpose

Isolated debug-only executable for testing **REAL** Google and Apple Sign-In against Firebase Auth (`anis-437c3`) without launching the full ANIS production application.

## Safety Guarantees

This harness is **FAIL-CLOSED** and requires BOTH:

1. **Debug build** (`kDebugMode = true`)
2. **Compile-time flag**: `--dart-define=AUTH_PROVIDER_VALIDATION=true`

If either condition is false, the harness throws `StateError` and refuses to run.

## What It Does

- ✅ Initializes Firebase Core and Firebase Auth
- ✅ Uses real `AuthService` (Google/Apple provider implementations)
- ✅ Displays Firebase UID, email, provider IDs after authentication
- ✅ Tests sign-out

## What It Does NOT Do

- ❌ Initialize Firestore
- ❌ Create Firestore profiles
- ❌ Initialize business repositories (Khatma/Formations/Wird)
- ❌ Call ANIS business APIs
- ❌ Navigate to ANIS home
- ❌ Access any product data

## Dependencies

**Allowed:**
- `firebase_core` (Firebase.initializeApp)
- `firebase_auth` (FirebaseAuth stream)
- `core/services/auth_service` (Google/Apple logic)

**Forbidden:**
- `cloud_firestore`
- `features/formations`
- `features/khatma`
- `features/wird`
- Business API clients

## How to Run

### iPhone Simulator

```bash
# 1. Find device ID
flutter devices

# 2. Launch harness
flutter run \
  -d <iPhone-device-id> \
  --dart-define=AUTH_PROVIDER_VALIDATION=true \
  -t lib/dev/auth_provider_validation_main.dart
```

### Physical iPhone

```bash
flutter run \
  -d <physical-device-id> \
  --dart-define=AUTH_PROVIDER_VALIDATION=true \
  -t lib/dev/auth_provider_validation_main.dart
```

## Expected Flow

1. App launches with **"ANIS — Auth Provider Validation"** screen
2. Tap **"Sign in with Google"**
   - Native Google account chooser appears
   - Select account
   - Success → Firebase UID displayed
3. Tap **"Sign Out"**
4. Tap **"Sign in with Apple"**
   - Native Apple Sign-In sheet appears
   - Authenticate with Face ID / Touch ID
   - Success → Firebase UID displayed
5. Verify no Firestore profile created

## Validation Checklist

After successful authentication:

- [x] Firebase UID displayed (non-empty)
- [x] Email displayed (if provided by provider)
- [x] Provider IDs displayed (e.g., `google.com`, `apple.com`)
- [x] No navigation to ANIS home
- [x] No Firestore errors in console
- [x] Sign out clears authenticated state

## Troubleshooting

### "StateError: Auth provider validation harness requires..."

**Cause:** Missing `--dart-define=AUTH_PROVIDER_VALIDATION=true` or release build.

**Fix:** Add the flag and ensure debug mode.

### "Firebase Auth not initialized"

**Cause:** `GoogleService-Info.plist` missing or invalid.

**Fix:** Verify `ios/Runner/GoogleService-Info.plist` exists and matches `com.aniskhatamat.app`.

### Google Sign-In cancelled immediately

**Cause:** URL scheme mismatch.

**Fix:** Verify `Info.plist` contains correct `REVERSED_CLIENT_ID` in `CFBundleURLSchemes`.

### Apple Sign-In fails with "operation not allowed"

**Cause:** Apple provider not enabled in Firebase Console.

**Fix:** Firebase Console → Authentication → Sign-in method → Apple → Enable.

## Tests

```bash
flutter test test/dev/auth_provider_validation_test.dart
```

Proves:
- Harness requires debug mode
- Harness requires `AUTH_PROVIDER_VALIDATION` flag
- No business repository dependencies
- No business API dependencies
- Isolation from production ANIS app

## Safety Notes

- **This harness CANNOT be shipped to production** (hard guard prevents it)
- **Uses real Firebase Auth project** (`anis-437c3`)
- **Does NOT mutate Firestore business data**
- **Authentication state is real** but isolated from ANIS business logic
- **Sign-in creates Firebase User** but no ANIS profile
