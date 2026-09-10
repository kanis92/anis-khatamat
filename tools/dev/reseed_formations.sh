#!/bin/bash

# ═══════════════════════════════════════════════════════════════════════════
# ANIS Formations - Quick re-seed against running emulators
# ═══════════════════════════════════════════════════════════════════════════
#
# Same guarantees as start_formations_preview.sh, without restarting anything:
# both emulators must be healthy, the preview user is (re)ensured, the seed is
# idempotent, and the canonical dataset is verified before we report success.
#
# ═══════════════════════════════════════════════════════════════════════════

set -e

WORKSPACE_ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
FIRESTORE_PORT=8080
AUTH_PORT=9099

echo ""
echo "═══════════════════════════════════════════════════════════════"
echo "  ANIS Formations - Re-seeding Data"
echo "═══════════════════════════════════════════════════════════════"
echo ""

require_service() {
    local port=$1
    local name=$2

    if ! curl -s "http://127.0.0.1:$port/" >/dev/null 2>&1; then
        echo "❌ $name emulator not responding on 127.0.0.1:$port"
        echo ""
        echo "Start the canonical preview environment first:"
        echo "  ./tools/dev/start_formations_preview.sh"
        echo ""
        exit 1
    fi
    echo "✅ $name emulator healthy (127.0.0.1:$port)"
}

require_service $FIRESTORE_PORT "Firestore"
require_service $AUTH_PORT "Auth"

export FIRESTORE_EMULATOR_HOST="127.0.0.1:$FIRESTORE_PORT"
export FIREBASE_AUTH_EMULATOR_HOST="127.0.0.1:$AUTH_PORT"
export FIREBASE_PROJECT_ID=anis-437c3

echo ""
node "$WORKSPACE_ROOT/tools/dev/ensure_preview_user.js"

echo ""
echo "🌱 Re-seeding Formation data (cleans legacy preview IDs first)..."
echo ""

cd "$WORKSPACE_ROOT/functions"
node seed_formations_preview.js

echo ""
node "$WORKSPACE_ROOT/tools/dev/verify_preview_dataset.js"

echo ""
echo "═══════════════════════════════════════════════════════════════"
echo "✅ Re-seed complete"
echo "═══════════════════════════════════════════════════════════════"
echo ""
echo "📱 In your running Flutter app:"
echo "   1. Navigate back to the Formations tab"
echo "   2. Formation providers rebuild on auth change — no restart needed"
echo ""
