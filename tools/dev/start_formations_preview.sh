#!/bin/bash

# ═══════════════════════════════════════════════════════════════════════════
# ANIS Formations V1 - One-Command Preview Launcher
# ═══════════════════════════════════════════════════════════════════════════
#
# Launches complete local preview on iPhone SE Simulator:
# - Firebase emulators (Firestore + Auth)
# - Demo course seed
# - Local ANIS API
# - Flutter on iPhone SE Simulator
#
# SAFETY: Fail-closed - stops immediately on any error
# SAFETY: NEVER touches production Firebase
#
# Usage:
#   ./tools/dev/start_formations_preview.sh
#
# ═══════════════════════════════════════════════════════════════════════════

set -e  # Exit on any error

# ─── Constants ─────────────────────────────────────────────────────────────

WORKSPACE_ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
EMULATOR_FIRESTORE_PORT=8080
EMULATOR_AUTH_PORT=9099
API_PORT=3000
MAX_WAIT_SECONDS=30
FIREBASE_PROJECT_ID=anis-437c3

# Local emulator state (gitignored). Persisted across runs so that restarting
# the emulators does not silently destroy the preview auth user.
EMULATOR_STATE_DIR="$WORKSPACE_ROOT/.firebase-emulator-state"

# ─── Colors ────────────────────────────────────────────────────────────────

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# ─── Helper Functions ──────────────────────────────────────────────────────

log_info() {
    echo -e "${BLUE}ℹ${NC}  $1"
}

log_success() {
    echo -e "${GREEN}✅${NC} $1"
}

log_error() {
    echo -e "${RED}❌${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}⚠️${NC}  $1"
}

wait_for_port() {
    local port=$1
    local service=$2
    local waited=0

    log_info "Waiting for $service on port $port..."

    while ! lsof -i ":$port" -sTCP:LISTEN >/dev/null 2>&1; do
        if [ $waited -ge $MAX_WAIT_SECONDS ]; then
            log_error "$service did not start within ${MAX_WAIT_SECONDS}s"
            return 1
        fi
        sleep 1
        waited=$((waited + 1))
    done

    log_success "$service ready (port $port)"
    return 0
}

wait_for_http() {
    local url=$1
    local service=$2
    local waited=0

    log_info "Waiting for $service at $url..."

    while ! curl -s "$url" >/dev/null 2>&1; do
        if [ $waited -ge $MAX_WAIT_SECONDS ]; then
            log_error "$service did not respond within ${MAX_WAIT_SECONDS}s"
            return 1
        fi
        sleep 1
        waited=$((waited + 1))
    done

    log_success "$service responding"
    return 0
}

# Graceful stop so that --export-on-exit can flush the emulator state.
stop_port_gracefully() {
    local port=$1
    local pids
    pids=$(lsof -ti ":$port" 2>/dev/null || true)
    [ -z "$pids" ] && return 0

    echo "$pids" | xargs kill 2>/dev/null || true
    local waited=0
    while lsof -i ":$port" -sTCP:LISTEN >/dev/null 2>&1; do
        if [ $waited -ge 15 ]; then
            echo "$pids" | xargs kill -9 2>/dev/null || true
            break
        fi
        sleep 1
        waited=$((waited + 1))
    done
}

# ═══════════════════════════════════════════════════════════════════════════
# STEP 1: VERIFY WORKSPACE
# ═══════════════════════════════════════════════════════════════════════════

echo ""
echo "═══════════════════════════════════════════════════════════════"
echo "  ANIS Formations V1 Preview Launcher"
echo "═══════════════════════════════════════════════════════════════"
echo ""

if [ ! -f "$WORKSPACE_ROOT/pubspec.yaml" ]; then
    log_error "Not in ANIS workspace root"
    exit 1
fi

log_success "Workspace: $WORKSPACE_ROOT"

# ═══════════════════════════════════════════════════════════════════════════
# STEP 2: VERIFY TOOLS
# ═══════════════════════════════════════════════════════════════════════════

log_info "Verifying required tools..."

if ! command -v firebase >/dev/null 2>&1; then
    log_error "Firebase CLI not found. Install: npm install -g firebase-tools"
    exit 1
fi

if ! command -v node >/dev/null 2>&1; then
    log_error "Node.js not found. Install from https://nodejs.org"
    exit 1
fi

if ! command -v flutter >/dev/null 2>&1; then
    log_error "Flutter not found. Install from https://flutter.dev"
    exit 1
fi

log_success "All tools available (Firebase CLI, Node, Flutter)"

# ═══════════════════════════════════════════════════════════════════════════
# STEP 3: STOP STALE PROCESSES
# ═══════════════════════════════════════════════════════════════════════════

log_info "Checking for stale preview processes..."

# Kill existing emulators (SIGTERM first so --export-on-exit can flush state)
if lsof -i ":$EMULATOR_FIRESTORE_PORT" >/dev/null 2>&1; then
    log_warning "Stopping existing Firestore emulator..."
    stop_port_gracefully $EMULATOR_FIRESTORE_PORT
fi

if lsof -i ":$EMULATOR_AUTH_PORT" >/dev/null 2>&1; then
    log_warning "Stopping existing Auth emulator..."
    stop_port_gracefully $EMULATOR_AUTH_PORT
fi

# Kill existing API server
if lsof -i ":$API_PORT" >/dev/null 2>&1; then
    log_warning "Stopping existing API server..."
    lsof -ti ":$API_PORT" | xargs kill -9 2>/dev/null || true
fi

sleep 2
log_success "Old processes cleaned"

# ═══════════════════════════════════════════════════════════════════════════
# STEP 4: START FIREBASE EMULATORS
# ═══════════════════════════════════════════════════════════════════════════

log_info "Starting Firebase emulators (Firestore + Auth)..."

# Export Java 21 for Firebase emulators (required by firebase-tools)
export JAVA_HOME=/opt/homebrew/opt/openjdk@21
export PATH="$JAVA_HOME/bin:$PATH"

cd "$WORKSPACE_ROOT"

mkdir -p "$EMULATOR_STATE_DIR"

# --import only accepts a directory that already holds an export manifest.
EMULATOR_IMPORT_ARGS=()
if [ -f "$EMULATOR_STATE_DIR/firebase-export-metadata.json" ]; then
    log_info "Restoring local emulator state from .firebase-emulator-state/"
    EMULATOR_IMPORT_ARGS=(--import "$EMULATOR_STATE_DIR")
else
    log_info "No local emulator state yet — starting from empty state"
fi

firebase emulators:start \
    --only auth,firestore \
    --project "$FIREBASE_PROJECT_ID" \
    "${EMULATOR_IMPORT_ARGS[@]}" \
    --export-on-exit "$EMULATOR_STATE_DIR" \
    > /tmp/anis_emulators.log 2>&1 &
EMULATOR_PID=$!

log_info "Emulator PID: $EMULATOR_PID"

# ═══════════════════════════════════════════════════════════════════════════
# STEP 5: WAIT FOR EMULATOR PORTS
# ═══════════════════════════════════════════════════════════════════════════

if ! wait_for_port $EMULATOR_FIRESTORE_PORT "Firestore emulator"; then
    log_error "Firestore emulator failed to start"
    log_error "Check logs: tail /tmp/anis_emulators.log"
    kill $EMULATOR_PID 2>/dev/null || true
    exit 1
fi

if ! wait_for_port $EMULATOR_AUTH_PORT "Auth emulator"; then
    log_error "Auth emulator failed to start"
    log_error "Check logs: tail /tmp/anis_emulators.log"
    kill $EMULATOR_PID 2>/dev/null || true
    exit 1
fi

# Ports being open is not enough: both services must actually answer.
if ! wait_for_http "http://127.0.0.1:$EMULATOR_FIRESTORE_PORT/" "Firestore emulator API"; then
    log_error "Firestore emulator is listening but not responding"
    kill $EMULATOR_PID 2>/dev/null || true
    exit 1
fi

if ! wait_for_http "http://127.0.0.1:$EMULATOR_AUTH_PORT/" "Auth emulator API"; then
    log_error "Auth emulator is listening but not responding"
    kill $EMULATOR_PID 2>/dev/null || true
    exit 1
fi

log_success "Firebase emulators ready (Auth + Firestore healthy)"

# ═══════════════════════════════════════════════════════════════════════════
# STEP 6: EMULATOR-ONLY ENVIRONMENT FOR EVERY LOCAL TOOL
# ═══════════════════════════════════════════════════════════════════════════

export FIRESTORE_EMULATOR_HOST="127.0.0.1:$EMULATOR_FIRESTORE_PORT"
export FIREBASE_AUTH_EMULATOR_HOST="127.0.0.1:$EMULATOR_AUTH_PORT"

# ═══════════════════════════════════════════════════════════════════════════
# STEP 6b: ENSURE PREVIEW USER (idempotent, emulator-only)
# ═══════════════════════════════════════════════════════════════════════════

log_info "Ensuring preview user exists in the Auth emulator..."

cd "$WORKSPACE_ROOT"

if ! node tools/dev/ensure_preview_user.js; then
    log_error "Preview user bootstrap failed — refusing to continue"
    kill $EMULATOR_PID 2>/dev/null || true
    exit 1
fi

# ═══════════════════════════════════════════════════════════════════════════
# STEP 6c: SEED CANONICAL FORMATION DATA (idempotent)
# ═══════════════════════════════════════════════════════════════════════════

log_info "Seeding canonical Formation data..."

cd "$WORKSPACE_ROOT/functions"

if ! node seed_formations_preview.js > /tmp/anis_seed.log 2>&1; then
    log_error "Seed failed"
    log_error "Check logs: cat /tmp/anis_seed.log"
    kill $EMULATOR_PID 2>/dev/null || true
    exit 1
fi

log_success "Demo courses seeded (6 pillars with modules)"

# ═══════════════════════════════════════════════════════════════════════════
# STEP 6d: VERIFY CANONICAL DATASET (6 courses / 33 modules)
# ═══════════════════════════════════════════════════════════════════════════

cd "$WORKSPACE_ROOT"

if ! node tools/dev/verify_preview_dataset.js; then
    log_error "Canonical dataset verification failed — refusing to continue"
    log_error "Seed logs: cat /tmp/anis_seed.log"
    kill $EMULATOR_PID 2>/dev/null || true
    exit 1
fi

# ═══════════════════════════════════════════════════════════════════════════
# STEP 7: START LOCAL ANIS API
# ═══════════════════════════════════════════════════════════════════════════

log_info "Starting local ANIS API (port $API_PORT)..."

cd "$WORKSPACE_ROOT/api"

export FIREBASE_PROJECT_ID=anis-437c3
export NODE_ENV=development
export PORT=$API_PORT

npm run dev > /tmp/anis_api.log 2>&1 &
API_PID=$!

log_info "API PID: $API_PID"

# ═══════════════════════════════════════════════════════════════════════════
# STEP 8: WAIT FOR API HEALTH
# ═══════════════════════════════════════════════════════════════════════════

# Note: The API doesn't have a /health endpoint, so we check for the server startup log
sleep 5

if ! lsof -i ":$API_PORT" >/dev/null 2>&1; then
    log_error "API failed to start"
    log_error "Check logs: tail /tmp/anis_api.log"
    kill $EMULATOR_PID 2>/dev/null || true
    kill $API_PID 2>/dev/null || true
    exit 1
fi

log_success "API server ready (http://127.0.0.1:$API_PORT)"

# ═══════════════════════════════════════════════════════════════════════════
# STEP 9: BOOT IPHONE SE SIMULATOR
# ═══════════════════════════════════════════════════════════════════════════

log_info "Finding iPhone SE (3rd generation)..."

# Find iPhone SE device
DEVICE_ID=$(xcrun simctl list devices | grep "iPhone SE (3rd generation)" | grep -v "unavailable" | head -1 | grep -o "[0-9A-F\-]\{36\}")

if [ -z "$DEVICE_ID" ]; then
    log_error "iPhone SE (3rd generation) not found"
    log_error "Available devices:"
    xcrun simctl list devices | grep "iPhone"
    kill $EMULATOR_PID 2>/dev/null || true
    kill $API_PID 2>/dev/null || true
    exit 1
fi

log_success "Found iPhone SE: $DEVICE_ID"

# Check if already booted
DEVICE_STATE=$(xcrun simctl list devices | grep "$DEVICE_ID" | grep -o "Booted\|Shutdown")

if [ "$DEVICE_STATE" != "Booted" ]; then
    log_info "Booting iPhone SE..."
    xcrun simctl boot "$DEVICE_ID"
    sleep 3
fi

# Open Simulator.app if not already open
if ! pgrep -x "Simulator" > /dev/null; then
    log_info "Opening Simulator.app..."
    open -a Simulator
    sleep 2
fi

log_success "iPhone SE ready"

# ═══════════════════════════════════════════════════════════════════════════
# STEP 10: LAUNCH FLUTTER
# ═══════════════════════════════════════════════════════════════════════════

log_info "Launching Flutter on iPhone SE (DEVELOPMENT MODE)..."

cd "$WORKSPACE_ROOT"

echo ""
echo "═══════════════════════════════════════════════════════════════"
echo "  ✅ FORMATIONS PREVIEW READY"
echo "═══════════════════════════════════════════════════════════════"
echo ""
echo "✅ iPhone SE booted: $DEVICE_ID"
echo "✅ Auth emulator healthy      127.0.0.1:$EMULATOR_AUTH_PORT"
echo "✅ Firestore emulator healthy 127.0.0.1:$EMULATOR_FIRESTORE_PORT"
echo "✅ Preview user ready         preview@anis.local"
echo "✅ Canonical dataset verified 6 courses / 33 modules"
echo "✅ API active                 http://127.0.0.1:$API_PORT"
echo "✅ Emulator state persisted   .firebase-emulator-state/ (gitignored)"
echo "✅ Production untouched       ENV_MODE=development"
echo ""
echo "📱 Launching Flutter app..."
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "Expected flow:"
echo "  1. Signed out → Formations shows 'Connexion requise'"
echo "  2. Sign in with preview@anis.local"
echo "  3. Formations → Bases & pratique → 5 modules (no restart needed)"
echo "  4. Expand a module → real lessons"
echo ""
echo "Press Ctrl+C when done (will stop all services and export state)"
echo ""

# Launch Flutter (stays in foreground)
flutter run -d "$DEVICE_ID" --dart-define=ENV_MODE=development

# Clean up on exit — SIGTERM so --export-on-exit flushes the emulator state.
log_info "Stopping services..."
kill $API_PID 2>/dev/null || true
kill $EMULATOR_PID 2>/dev/null || true
wait $EMULATOR_PID 2>/dev/null || true
log_success "Preview stopped (emulator state exported)"
