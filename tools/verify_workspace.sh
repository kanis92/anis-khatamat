#!/bin/bash
# verify_workspace.sh - ANIS Khatamat Workspace Safety Guard
# 
# Ensures all critical operations happen in the canonical development worktree.
# Run this before: commits, releases, migrations, Firebase changes, large refactors.

set -e

CANONICAL_PATH="/Users/jaouad/Desktop/KHATAMAT/anis_merge_main"
CANONICAL_BRANCH="main"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo "========================================="
echo "ANIS Khatamat Workspace Verification"
echo "========================================="
echo ""

# Check current directory
CURRENT_PATH="$(pwd)"
echo "WORKTREE: $CURRENT_PATH"

if [ "$CURRENT_PATH" != "$CANONICAL_PATH" ]; then
    echo -e "${RED}✗ STOP: Wrong ANIS worktree${NC}"
    echo ""
    echo "Expected: $CANONICAL_PATH"
    echo "Found:    $CURRENT_PATH"
    echo ""
    echo "Switch to canonical worktree:"
    echo "  cd $CANONICAL_PATH"
    exit 1
fi

# Check current branch
CURRENT_BRANCH="$(git branch --show-current)"
echo "BRANCH:   $CURRENT_BRANCH"

if [ "$CURRENT_BRANCH" != "$CANONICAL_BRANCH" ]; then
    echo -e "${YELLOW}⚠ WARNING: Not on canonical branch${NC}"
    echo ""
    echo "Expected: $CANONICAL_BRANCH"
    echo "Found:    $CURRENT_BRANCH"
    echo ""
    echo "This may be intentional for feature branches."
    echo "Verify this is expected before proceeding."
    echo ""
fi

# Show HEAD
HEAD_SHA="$(git rev-parse HEAD)"
HEAD_SHORT="$(git rev-parse --short HEAD)"
echo "HEAD:     $HEAD_SHORT ($HEAD_SHA)"
echo ""

# Status summary
echo "STATUS SUMMARY:"
MODIFIED=$(git status --short | grep "^ M" | wc -l | tr -d ' ')
STAGED=$(git status --short | grep "^M " | wc -l | tr -d ' ')
UNTRACKED=$(git status --short | grep "^??" | wc -l | tr -d ' ')

echo "  Modified:  $MODIFIED files"
echo "  Staged:    $STAGED files"
echo "  Untracked: $UNTRACKED files"

if [ "$MODIFIED" -gt 0 ] || [ "$STAGED" -gt 0 ]; then
    echo ""
    echo -e "${YELLOW}⚠ Workspace has uncommitted changes${NC}"
    echo ""
    echo "Recent changes:"
    git status --short | head -10
    if [ "$(git status --short | wc -l)" -gt 10 ]; then
        echo "  ... ($(git status --short | wc -l) total)"
    fi
fi

echo ""
echo "========================================="

if [ "$CURRENT_PATH" = "$CANONICAL_PATH" ]; then
    if [ "$CURRENT_BRANCH" = "$CANONICAL_BRANCH" ]; then
        echo -e "${GREEN}✓ Canonical ANIS workspace confirmed${NC}"
        exit 0
    else
        echo -e "${YELLOW}⚠ On feature branch - verify this is expected${NC}"
        exit 0
    fi
else
    echo -e "${RED}✗ STOP: Wrong ANIS worktree${NC}"
    exit 1
fi
