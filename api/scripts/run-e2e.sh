#!/bin/bash
#
# Run E2E Tests Against Firebase Emulators
#

set -e

cd "$(dirname "$0")/.."

echo "========================================"
echo "E2E Test Execution Script"
echo "========================================"

# Check Firebase CLI
if ! command -v firebase &> /dev/null; then
    echo "❌ Firebase CLI not found"
    echo "Install: npm install -g firebase-tools"
    exit 1
fi

# Set emulator environment variables
export FIREBASE_AUTH_EMULATOR_HOST="localhost:9099"
export FIRESTORE_EMULATOR_HOST="localhost:8080"
export NODE_ENV="test"

echo ""
echo "✅ Environment configured for emulators"
echo "   AUTH:      $FIREBASE_AUTH_EMULATOR_HOST"
echo "   FIRESTORE: $FIRESTORE_EMULATOR_HOST"
echo ""

# Run tests using firebase emulators:exec
cd ..
echo "🚀 Starting Firebase emulators..."
echo ""

firebase emulators:exec --only auth,firestore \
  "cd api && npm test -- test/e2e"

echo ""
echo "========================================"
echo "✅ E2E Tests Complete"
echo "========================================"
