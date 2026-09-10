#!/bin/bash

# ═══════════════════════════════════════════════════════════════════════════
# ANIS Formations V1 - Stop Preview Services
# ═══════════════════════════════════════════════════════════════════════════
#
# Safely stops:
# - Firebase emulators (Firestore + Auth)
# - Local ANIS API
#
# Does NOT kill:
# - Flutter processes (in case you're running other Flutter apps)
# - Unrelated Node processes
# - Simulator.app
#
# Usage:
#   ./tools/dev/stop_formations_preview.sh
#
# ═══════════════════════════════════════════════════════════════════════════

set -e

# ─── Constants ─────────────────────────────────────────────────────────────

EMULATOR_FIRESTORE_PORT=8080
EMULATOR_AUTH_PORT=9099
API_PORT=3000

# ─── Colors ────────────────────────────────────────────────────────────────

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# ─── Helper Functions ──────────────────────────────────────────────────────

log_success() {
    echo -e "${GREEN}✅${NC} $1"
}

log_info() {
    echo -e "${YELLOW}ℹ${NC}  $1"
}

# ═══════════════════════════════════════════════════════════════════════════
# STOP SERVICES
# ═══════════════════════════════════════════════════════════════════════════

echo ""
echo "═══════════════════════════════════════════════════════════════"
echo "  Stopping Formations Preview Services"
echo "═══════════════════════════════════════════════════════════════"
echo ""

# Stop Firestore emulator
if lsof -i ":$EMULATOR_FIRESTORE_PORT" >/dev/null 2>&1; then
    log_info "Stopping Firestore emulator (port $EMULATOR_FIRESTORE_PORT)..."
    lsof -ti ":$EMULATOR_FIRESTORE_PORT" | xargs kill 2>/dev/null || true
    log_success "Firestore emulator stopped"
else
    log_info "Firestore emulator not running"
fi

# Stop Auth emulator
if lsof -i ":$EMULATOR_AUTH_PORT" >/dev/null 2>&1; then
    log_info "Stopping Auth emulator (port $EMULATOR_AUTH_PORT)..."
    lsof -ti ":$EMULATOR_AUTH_PORT" | xargs kill 2>/dev/null || true
    log_success "Auth emulator stopped"
else
    log_info "Auth emulator not running"
fi

# Stop API server
if lsof -i ":$API_PORT" >/dev/null 2>&1; then
    log_info "Stopping API server (port $API_PORT)..."
    lsof -ti ":$API_PORT" | xargs kill 2>/dev/null || true
    log_success "API server stopped"
else
    log_info "API server not running"
fi

# Clean up log files
if [ -f /tmp/anis_emulators.log ]; then
    rm /tmp/anis_emulators.log
fi
if [ -f /tmp/anis_seed.log ]; then
    rm /tmp/anis_seed.log
fi
if [ -f /tmp/anis_api.log ]; then
    rm /tmp/anis_api.log
fi

echo ""
log_success "All preview services stopped"
echo ""
echo "Note: Simulator.app and Flutter processes were left running"
echo "      (in case you're using them for other work)"
echo ""
