# ANIS Development Tools

This directory contains development-only tools for local preview and testing.

**IMPORTANT**: These tools NEVER touch production data. They only work with Firebase emulators.

---

## 🎯 Formations V1 Local Preview

### Prerequisites

1. **Firebase CLI** installed:
   ```bash
   npm install -g firebase-tools
   ```

2. **Firebase Admin SDK** available (for seed script):
   ```bash
   cd functions
   npm install
   ```

### Reproducible Commands

#### 1. Start Firebase Emulators

```bash
cd /Users/jaouad/Desktop/KHATAMAT/anis_merge_main
firebase emulators:start --only auth,firestore --project demo-test
```

**Ports**:
- Firestore: `localhost:8080`
- Auth: `localhost:9099`
- Emulator UI: `localhost:4000` (optional)

#### 2. Seed Formation Preview Data

In a **new terminal**:

```bash
cd /Users/jaouad/Desktop/KHATAMAT/anis_merge_main/functions

export FIRESTORE_EMULATOR_HOST="localhost:8080"
export FIREBASE_AUTH_EMULATOR_HOST="localhost:9099"

node seed_formations_preview.js
```

**Script location**: `functions/seed_formations_preview.js` (uses installed `firebase-admin`)

**Expected output**:
```
✅ Course: demo-formation-basics
   Pillar: foundations_practice (Bases & pratique)
✅ Module: module-1-intro (2 lessons)
✅ Module: module-2-practice (1 lesson)
✅ Lesson: lesson-1 (Welcome)
✅ Lesson: lesson-2 (Progress Tracking)
✅ Lesson: lesson-3 (Practice)
```

#### 3. Start Local ANIS API

In a **new terminal**:

```bash
cd /Users/jaouad/Desktop/KHATAMAT/anis_merge_main/api

export FIRESTORE_EMULATOR_HOST="localhost:8080"
export FIREBASE_AUTH_EMULATOR_HOST="localhost:9099"
export NODE_ENV=development
export PORT=3000

npm run dev
```

**Expected output**:
```
ANIS API server listening on port 3000 (development mode)
```

#### 4. Launch Flutter on iPhone SE

In a **new terminal**:

```bash
cd /Users/jaouad/Desktop/KHATAMAT/anis_merge_main

# Development mode (default) - connects to emulators
flutter run -d "iPhone SE (3rd generation)"

# OR if you know the device ID:
flutter run -d "649035B3-84CF-4F0F-9E78-8C5C721C1E1B"
```

**IMPORTANT**: Do NOT pass `--dart-define=ENV_MODE=production`

---

## ✅ Expected Result

### On iPhone SE Simulator

1. **Tap "Formations" tab** (bottom navigation)

2. **See pedagogical pillar chips**:
   - Tout (All)
   - **Bases & pratique** ← Demo course is here
   - Qur'an & lecture
   - Prophète ﷺ : modèle et enseignement
   - Vie quotidienne en France
   - Comportement & éthique
   - Spiritualité & cœur

3. **Tap "Bases & pratique" chip**

4. **See course card**: "Formation Basics Demo"

5. **Tap course card** → Path detail screen opens

6. **See modules & lessons**:
   - Introduction Module (2 lessons)
   - Practice Module (1 lesson)

7. **Tap a lesson** → Lesson screen opens with content, summary, action

8. **Mark complete** → Progress updates, checkmark appears

9. **Return to landing** → Resume card appears

---

## 🔄 Re-running the Seed

The seed script is **idempotent**. You can run it multiple times without errors.

To reset the emulator data:
1. Stop the emulators (Ctrl+C)
2. Restart: `firebase emulators:start --only auth,firestore --project demo-test`
3. Re-run the seed: `node tools/dev/seed_formations_preview.js`

---

## 🔒 Safety

### How We Prevent Production Writes

1. **Seed Script**: Refuses to run unless `FIRESTORE_EMULATOR_HOST` is set
2. **Flutter App**: Auto-connects to emulators in debug mode when `ENV_MODE != production`
3. **API Server**: Uses emulator when environment variables are set

### Production Mode

To use production Firebase (e.g., for staging/release builds):

```bash
flutter run --dart-define=ENV_MODE=production
```

When `ENV_MODE=production`:
- Flutter connects to real Firebase (not emulators)
- Seed scripts refuse to run
- API uses production Firestore

---

## 🐛 Troubleshooting

### "No courses visible"

**Check**:
1. Emulators are running: `lsof -i :8080,9099` should show Java processes
2. Seed script ran successfully: Look for "✅ Seed Complete"
3. Flutter console shows: `[FirebaseBootstrap] ✅ Connected to Firestore emulator`

**Fix**:
```bash
# Kill all processes
pkill -f firebase
pkill -f flutter

# Restart in order: emulators → seed → API → Flutter
```

### "Emulators not available" warning in Flutter

This is **normal** if you haven't started the emulators yet. Flutter will fall back to production Firebase.

**Fix**: Start emulators before launching Flutter.

### "Course visible but lessons don't load"

**Check**: API server is running and connected to emulators.

**Fix**:
```bash
cd api
export FIRESTORE_EMULATOR_HOST="localhost:8080"
npm run dev
```

---

## 📝 What Gets Seeded

### Course
- **ID**: `demo-formation-basics`
- **Pillar**: `foundations_practice` (Bases & pratique)
- **Published**: `true`
- **Lessons**: 3
- **Duration**: 30 minutes

### Content
- ✅ Neutral technical/demo text
- ✅ Summaries (3 bullets per lesson)
- ✅ Action-to-apply sections
- ❌ No religious rulings
- ❌ No Quran references
- ❌ No quiz questions

---

## 🚀 Quick Start (All Commands)

```bash
# Terminal 1: Emulators
firebase emulators:start --only auth,firestore --project demo-test

# Terminal 2: Seed
export FIRESTORE_EMULATOR_HOST="localhost:8080"
export FIREBASE_AUTH_EMULATOR_HOST="localhost:9099"
node tools/dev/seed_formations_preview.js

# Terminal 3: API
cd api
export FIRESTORE_EMULATOR_HOST="localhost:8080"
export FIREBASE_AUTH_EMULATOR_HOST="localhost:9099"
npm run dev

# Terminal 4: Flutter
flutter run -d "iPhone SE (3rd generation)"
```

**Then**: Tap Formations → Bases & pratique → See demo course ✅
